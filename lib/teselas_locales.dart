/// Servidor de teselas embebido en la app.
///
/// Las teselas reales de OpenStreetMap viajan dentro del APK en
/// `assets/tiles`. Este servidor las entrega a MapLibre por localhost,
/// así que el mapa funciona sin internet en la zona descargada. Si el viajero
/// se aleja de esa zona, pide la tesela al servidor público, la guarda en caché
/// y la entrega igual, sin que la interfaz mencione claves ni servicios externos.
library;

import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

HttpServer? _servidor;
String? _estiloDia;
String? _estiloNoche;
Directory? _cacheDisk;

/// Teselas bajadas fuera del paquete, en memoria y en disco, para que al
/// repetir un recorrido no haga falta volver a pedirlas.
final LinkedHashMap<String, List<int>> _cacheMemoria = LinkedHashMap();
const int _maxCacheMemoria = 160;
const int _maxCacheDisco = 400;

/// Un PNG transparente de 1x1. Se entrega solo cuando no hay tesela local ni
/// red; así MapLibre no muestra huecos negros ni repite errores.
final List<int> _teselaVacia = base64.decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAAC0lEQVR4nGNgAAIAAAUAAXpeqz8AAAAASUVORK5CYII=',
);

/// User-Agent que OpenStreetMap sí sirve con teselas reales. Otros valores
/// devuelven una imagen placeholder de 6.725 bytes que parece un mapa vacío.
const String _userAgent = 'GAMEGPS/1.0 (educational project)';

/// Dirección base del servidor local, disponible después de [iniciarTeselas].
String? get direccionTeselasLocales =>
    _servidor == null ? null : 'http://127.0.0.1:${_servidor!.port}/tiles';

/// Estilo de día: teselas reales sin desvanecido, para que no parpadeen.
String? get estiloTeselasLocales => _estiloDia;

/// Estilo nocturno: mismo mapa real, atenuado y teñido de azul GAME GPS.
String? get estiloTeselasLocalesNoche => _estiloNoche;

/// Arranca el servidor en un puerto local libre. Debe llamarse antes de
/// `runApp` para que los estilos ya estén listos cuando se construya el mapa.
Future<void> iniciarTeselas() async {
  if (_servidor != null) return;
  _cacheDisk = await _directorioCache();
  try {
    final servidor = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    _servidor = servidor;
    servidor.listen((solicitud) => _atender(solicitud));
    final base = direccionTeselasLocales!;
    _estiloDia = _documentoEstilo(
      base,
      nombre: 'GAME GPS · Calles offline',
      brillo: 1.0,
      saturacion: 0.0,
      contraste: 0.0,
      tinteOpacidad: 0.0,
    );
    _estiloNoche = _documentoEstilo(
      base,
      nombre: 'GAME GPS · Calles offline · Noche',
      brillo: 0.72,
      saturacion: -0.28,
      contraste: 0.10,
      tinteOpacidad: 0.22,
    );
  } catch (_) {
    // Sin servidor local se usa el estilo online habitual.
    _estiloDia = null;
    _estiloNoche = null;
  }
}

String _documentoEstilo(
  String base, {
  required String nombre,
  required double brillo,
  required double saturacion,
  required double contraste,
  required double tinteOpacidad,
}) {
  final capas = <String>[
    '{"id":"fondo","type":"background",'
        '"paint":{"background-color":"#0B1220"}}',
    '{"id":"calles","type":"raster","source":"calles","paint":{'
        '"raster-fade-duration":0,'
        '"raster-brightness-max":$brillo,'
        '"raster-saturation":$saturacion,'
        '"raster-contrast":$contraste}}',
  ];
  if (tinteOpacidad > 0) {
    capas.add(
      '{"id":"tinete","type":"background",'
      '"paint":{"background-color":"#07111F",'
      '"background-opacity":$tinteOpacidad}}',
    );
  }
  return '{"version":8,"name":"$nombre",'
      '"sources":{"calles":{"type":"raster","tileSize":256,'
      '"tiles":["$base/{z}/{x}/{y}.png"],'
      '"attribution":"© OpenStreetMap contributors"}},'
      '"layers":[${capas.join(',')}]}';
}

Future<Directory?> _directorioCache() async {
  try {
    final base = await getApplicationDocumentsDirectory();
    final directorio = Directory('${base.path}/tiles_cache');
    if (!await directorio.exists()) {
      await directorio.create(recursive: true);
    }
    return directorio;
  } catch (_) {
    return null;
  }
}

Future<void> _atender(HttpRequest solicitud) async {
  final partes = solicitud.uri.pathSegments;
  final respuesta = solicitud.response;
  if (partes.length != 4 ||
      partes[0] != 'tiles' ||
      !partes[3].endsWith('.png')) {
    respuesta
      ..statusCode = HttpStatus.notFound
      ..close();
    return;
  }
  final z = int.tryParse(partes[1]);
  final x = int.tryParse(partes[2]);
  final y = int.tryParse(partes[3].substring(0, partes[3].length - 4));
  if (z == null ||
      x == null ||
      y == null ||
      z < 0 ||
      z > 20 ||
      x < 0 ||
      y < 0) {
    respuesta
      ..statusCode = HttpStatus.badRequest
      ..close();
    return;
  }

  final clave = '$z-$x-$y';
  List<int>? bytes;
  try {
    bytes = (await rootBundle.load('assets/tiles/$clave.png')).buffer
        .asUint8List();
  } catch (_) {
    bytes = await _teselaRemota(clave, z, x, y);
  }

  respuesta.headers.contentType = ContentType('image', 'png');
  if (bytes == null) {
    // Vacía pero válida: MapLibre sigue dibujando el resto del mapa y vuelve
    // a intentarlo en cuanto haya red, gracias a no-store.
    respuesta.headers.set('Cache-Control', 'no-store');
    respuesta
      ..statusCode = HttpStatus.ok
      ..add(_teselaVacia)
      ..close();
    return;
  }
  respuesta.headers.set('Cache-Control', 'public, max-age=604800');
  respuesta
    ..statusCode = HttpStatus.ok
    ..add(bytes)
    ..close();
}

int _enVuelo = 0;
final Queue<Completer<void>> _esperando = Queue();

Future<void> _adquirirTurno() async {
  if (_enVuelo < 4) {
    _enVuelo++;
    return;
  }
  final turno = Completer<void>();
  _esperando.add(turno);
  await turno.future;
}

void _liberarTurno() {
  if (_esperando.isNotEmpty) {
    _esperando.removeFirst().complete();
  } else if (_enVuelo > 0) {
    _enVuelo--;
  }
}

void _guardarEnMemoria(String clave, List<int> bytes) {
  _cacheMemoria.remove(clave);
  _cacheMemoria[clave] = bytes;
  while (_cacheMemoria.length > _maxCacheMemoria) {
    _cacheMemoria.remove(_cacheMemoria.keys.first);
  }
}

Future<List<int>?> _teselaRemota(String clave, int z, int x, int y) async {
  final memorizada = _cacheMemoria[clave];
  if (memorizada != null) return memorizada;

  final archivo = _cacheDisk == null
      ? null
      : File('${_cacheDisk!.path}/$clave.png');
  if (archivo != null && await archivo.exists()) {
    try {
      final guardada = await archivo.readAsBytes();
      if (guardada.length > 1000) {
        _guardarEnMemoria(clave, guardada);
        return guardada;
      }
    } catch (_) {
      // Archivo dañado: se vuelve a bajar.
    }
  }

  await _adquirirTurno();
  try {
    final remota = await http
        .get(
          Uri.parse('https://tile.openstreetmap.org/$z/$x/$y.png'),
          headers: const {'User-Agent': _userAgent},
        )
        .timeout(const Duration(seconds: 8));
    if (remota.statusCode != 200 || remota.bodyBytes.length < 1000) {
      return null;
    }
    final bytes = remota.bodyBytes;
    _guardarEnMemoria(clave, bytes);
    if (archivo != null) {
      unawaited(_guardarEnDisco(archivo, bytes));
    }
    return bytes;
  } catch (_) {
    return null;
  } finally {
    _liberarTurno();
  }
}

Future<void> _guardarEnDisco(File archivo, List<int> bytes) async {
  try {
    if (!await archivo.exists()) {
      await archivo.writeAsBytes(bytes);
      final directorio = _cacheDisk;
      if (directorio != null) {
        final archivos = directorio.listSync().whereType<File>().toList()
          ..sort(
            (a, b) => a.statSync().modified.compareTo(b.statSync().modified),
          );
        if (archivos.length > _maxCacheDisco) {
          for (final viejo in archivos.take(archivos.length - _maxCacheDisco)) {
            await viejo.delete();
          }
        }
      }
    }
  } catch (_) {
    // La caché en disco es opcional; la memoria ya sirvió esta sesión.
  }
}
