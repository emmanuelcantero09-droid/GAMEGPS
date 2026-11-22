/// Cálculo de rutas con OSRM, sin API key.
///
/// - Coche: servidor público de OSRM.
/// - A pie y en bici: servidores de OpenStreetMap (routed-foot / routed-bike).
library;

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

/// Modo de viaje de la ruta.
enum ModoRuta { coche, aPie, bici }

extension ModoRutaInfo on ModoRuta {
  String get etiqueta => switch (this) {
        ModoRuta.coche => 'Coche',
        ModoRuta.aPie => 'A pie',
        ModoRuta.bici => 'Bici',
      };

  String get host => switch (this) {
        ModoRuta.coche => 'router.project-osrm.org',
        ModoRuta.aPie || ModoRuta.bici => 'routing.openstreetmap.de',
      };

  String get perfil => switch (this) {
        ModoRuta.coche => '/route/v1/driving/',
        ModoRuta.aPie => '/routed-foot/route/v1/driving/',
        ModoRuta.bici => '/routed-bike/route/v1/driving/',
      };
}

/// Idioma de las instrucciones paso a paso.
enum IdiomaInstrucciones { es, en }

/// Formato de las distancias mostradas.
enum UnidadesRuta { metros, kilometros }

/// Preferencias que el usuario puede cambiar de una ruta.
class OpcionesRuta {
  const OpcionesRuta({
    this.modo = ModoRuta.coche,
    this.idioma = IdiomaInstrucciones.es,
    this.unidades = UnidadesRuta.kilometros,
    this.color = 0xFF00E5FF,
    this.grosor = 5,
  });

  final ModoRuta modo;
  final IdiomaInstrucciones idioma;
  final UnidadesRuta unidades;
  final int color;
  final int grosor;

  OpcionesRuta copyWith({
    ModoRuta? modo,
    IdiomaInstrucciones? idioma,
    UnidadesRuta? unidades,
    int? color,
    int? grosor,
  }) {
    return OpcionesRuta(
      modo: modo ?? this.modo,
      idioma: idioma ?? this.idioma,
      unidades: unidades ?? this.unidades,
      color: color ?? this.color,
      grosor: grosor ?? this.grosor,
    );
  }
}

/// Un paso de la ruta (una maniobra).
class PasoRuta {
  const PasoRuta({
    required this.instruccion,
    required this.distanciaMetros,
  });

  final String instruccion;
  final double distanciaMetros;
}

/// Una ruta completa: geometría, distancia, duración e instrucciones.
class Ruta {
  const Ruta({
    required this.puntos,
    required this.distanciaMetros,
    required this.duracionSegundos,
    required this.pasos,
  });

  /// Puntos [longitud, latitud] en orden de viaje.
  final List<List<double>> puntos;
  final double distanciaMetros;
  final double duracionSegundos;
  final List<PasoRuta> pasos;
}

/// Error con mensaje listo para mostrar al usuario.
class RutaException implements Exception {
  const RutaException(this.mensaje);

  final String mensaje;

  @override
  String toString() => mensaje;
}

/// Construye la URL de consulta.
Uri uriRuta({
  required double lonOrigen,
  required double latOrigen,
  required double lonDestino,
  required double latDestino,
  required ModoRuta modo,
}) {
  final coord = '${lonOrigen.toStringAsFixed(6)},'
      '${latOrigen.toStringAsFixed(6)};'
      '${lonDestino.toStringAsFixed(6)},'
      '${latDestino.toStringAsFixed(6)}';
  return Uri.https(
    modo.host,
    '${modo.perfil}$coord',
    {
      'overview': 'full',
      'geometries': 'geojson',
      'steps': 'true',
    },
  );
}

/// Convierte el modificador de OSRM en una dirección legible.
String direccionManiobra(String modifier, IdiomaInstrucciones idioma) {
  final es = idioma == IdiomaInstrucciones.es;
  return switch (modifier) {
    'left' => es ? 'a la izquierda' : 'left',
    'right' => es ? 'a la derecha' : 'right',
    'slight left' => es ? 'ligeramente a la izquierda' : 'slightly left',
    'slight right' => es ? 'ligeramente a la derecha' : 'slightly right',
    'sharp left' => es ? 'fuertemente a la izquierda' : 'sharp left',
    'sharp right' => es ? 'fuertemente a la derecha' : 'sharp right',
    'uturn' => es ? 'en dirección contraria' : 'around',
    _ => es ? 'recto' : 'straight',
  };
}

/// Genera el texto de una maniobra de OSRM.
String instruccionPaso(
  Map<String, dynamic> maneuver,
  String nombre, {
  IdiomaInstrucciones idioma = IdiomaInstrucciones.es,
}) {
  final es = idioma == IdiomaInstrucciones.es;
  final tipo = maneuver['type']?.toString() ?? '';
  final modifier = maneuver['modifier']?.toString() ?? '';
  final salida = maneuver['exit'];
  final calle = nombre.trim();
  final hacia = calle.isEmpty
      ? ''
      : es
          ? ' hacia $calle'
          : ' onto $calle';

  final accion = switch (tipo) {
    'depart' => es ? 'Sal' : 'Head out',
    'arrive' => es ? 'Llegaste a tu destino' : 'You have arrived',
    'turn' => es ? 'Gira ${direccionManiobra(modifier, idioma)}' : 'Turn ${direccionManiobra(modifier, idioma)}',
    'continue' => es ? 'Continúa ${direccionManiobra(modifier, idioma)}' : 'Continue ${direccionManiobra(modifier, idioma)}',
    'merge' => es ? 'Incorpórate ${direccionManiobra(modifier, idioma)}' : 'Merge ${direccionManiobra(modifier, idioma)}',
    'on ramp' => es ? 'Toma la rampa ${direccionManiobra(modifier, idioma)}' : 'Take the ramp ${direccionManiobra(modifier, idioma)}',
    'off ramp' => es ? 'Sal de la rampa ${direccionManiobra(modifier, idioma)}' : 'Take the exit ${direccionManiobra(modifier, idioma)}',
    'fork' => es ? 'Toma el desvío ${direccionManiobra(modifier, idioma)}' : 'Keep ${direccionManiobra(modifier, idioma)} at the fork',
    'end of road' => es ? 'Al final de la calle gira ${direccionManiobra(modifier, idioma)}' : 'At the end of the road turn ${direccionManiobra(modifier, idioma)}',
    'roundabout' || 'rotary' || 'roundabout turn' => salida == null
        ? (es ? 'Toma la rotonda' : 'Take the roundabout')
        : es
            ? 'En la rotonda, toma la salida $salida'
            : 'At the roundabout, take exit $salida',
    'new name' => es ? 'Sigue por $calle' : 'Continue on $calle',
    _ => es ? 'Sigue recto' : 'Continue straight',
  };

  if (tipo == 'arrive' || (tipo == 'new name' && calle.isNotEmpty)) {
    return accion;
  }
  return '$accion$hacia';
}

/// Da formato a una distancia según las unidades elegidas.
String formatoDistancia(double metros, UnidadesRuta unidades) {
  if (unidades == UnidadesRuta.metros) return '${metros.round()} m';
  return metros >= 1000
      ? '${(metros / 1000).toStringAsFixed(1)} km'
      : '${metros.round()} m';
}

/// Da formato a una duración en segundos.
String formatoDuracion(double segundos, IdiomaInstrucciones idioma) {
  final es = idioma == IdiomaInstrucciones.es;
  final minutos = (segundos / 60).round();
  if (minutos < 60) return '$minutos min';
  final horas = minutos ~/ 60;
  final mins = minutos % 60;
  if (mins == 0) return '$horas h';
  return es ? '$horas h $mins min' : '$horas h $mins min';
}

/// Convierte la respuesta de OSRM en una [Ruta].
Ruta rutaDesdeJson(
  Map<String, dynamic> datos, {
  IdiomaInstrucciones idioma = IdiomaInstrucciones.es,
}) {
  if (datos['code'] != 'Ok') {
    throw const RutaException('El servicio de rutas no pudo calcularla.');
  }
  final rutas = datos['routes'] as List<dynamic>? ?? [];
  if (rutas.isEmpty) {
    throw const RutaException('No hay ruta entre tu posición y el destino.');
  }
  final ruta = rutas.first as Map<String, dynamic>;
  final geometria = ruta['geometry'] as Map<String, dynamic>?;
  final crudos = geometria?['coordinates'] as List<dynamic>? ?? [];
  if (crudos.length < 2) {
    throw const RutaException('La ruta recibida no tiene geometría válida.');
  }

  final puntos = crudos
      .whereType<List<dynamic>>()
      .where((p) => p.length >= 2)
      .map(
        (p) => <double>[
          (p[0] as num).toDouble(),
          (p[1] as num).toDouble(),
        ],
      )
      .toList(growable: false);

  final pasos = <PasoRuta>[];
  final piernas = ruta['legs'] as List<dynamic>? ?? [];
  for (final pierna in piernas) {
    final lista = (pierna as Map<String, dynamic>)['steps'] as List<dynamic>? ?? [];
    for (final crudo in lista) {
      final paso = crudo as Map<String, dynamic>;
      final maniobra = (paso['maneuver'] as Map<String, dynamic>?) ?? const {};
      final distancia = (paso['distance'] as num?)?.toDouble() ?? 0;
      final nombre = paso['name']?.toString() ?? '';
      pasos.add(
        PasoRuta(
          instruccion: instruccionPaso(maniobra, nombre, idioma: idioma),
          distanciaMetros: distancia,
        ),
      );
    }
  }

  return Ruta(
    puntos: puntos,
    distanciaMetros: (ruta['distance'] as num?)?.toDouble() ?? 0,
    duracionSegundos: (ruta['duration'] as num?)?.toDouble() ?? 0,
    pasos: pasos,
  );
}

/// Cliente de rutas.
class ServicioRutas {
  static const Duration _tiempoEspera = Duration(seconds: 12);

  /// Calcula una ruta entre dos puntos geográficos.
  Future<Ruta> obtener({
    required double lonOrigen,
    required double latOrigen,
    required double lonDestino,
    required double latDestino,
    required ModoRuta modo,
    IdiomaInstrucciones idioma = IdiomaInstrucciones.es,
  }) async {
    final uri = uriRuta(
      lonOrigen: lonOrigen,
      latOrigen: latOrigen,
      lonDestino: lonDestino,
      latDestino: latDestino,
      modo: modo,
    );
    final cliente = HttpClient()
      ..userAgent = 'GAMEGPS/0.1 (Android; OpenStreetMap)';
    try {
      final peticion = await cliente.getUrl(uri).timeout(_tiempoEspera);
      final respuesta = await peticion.close().timeout(_tiempoEspera);
      if (respuesta.statusCode != 200) {
        throw const RutaException(
          'El servicio de rutas devolvió un error. Inténtalo de nuevo.',
        );
      }
      final cuerpo = await respuesta.transform(utf8.decoder).join();
      return rutaDesdeJson(
        jsonDecode(cuerpo) as Map<String, dynamic>,
        idioma: idioma,
      );
    } on SocketException {
      throw const RutaException(
        'Sin conexión a internet. Revisa tu WiFi o datos móviles.',
      );
    } on TimeoutException {
      throw const RutaException('La ruta tardó demasiado. Inténtalo de nuevo.');
    } on FormatException {
      throw const RutaException('El servicio devolvió una respuesta inesperada.');
    } finally {
      cliente.close();
    }
  }
}

/// Límites geográficos de una ruta.
({double minLon, double maxLon, double minLat, double maxLat}) _limites(
  Ruta ruta,
) {
  var minLon = ruta.puntos.first[0];
  var maxLon = minLon;
  var minLat = ruta.puntos.first[1];
  var maxLat = minLat;
  for (final punto in ruta.puntos.skip(1)) {
    minLon = math.min(minLon, punto[0]);
    maxLon = math.max(maxLon, punto[0]);
    minLat = math.min(minLat, punto[1]);
    maxLat = math.max(maxLat, punto[1]);
  }
  return (
    minLon: minLon,
    maxLon: maxLon,
    minLat: minLat,
    maxLat: maxLat,
  );
}

/// Centro de la ruta para colocar la cámara.
({double lon, double lat}) centroRuta(Ruta ruta) {
  if (ruta.puntos.isEmpty) return (lon: 0, lat: 0);
  final limites = _limites(ruta);
  return (
    lon: (limites.minLon + limites.maxLon) / 2,
    lat: (limites.minLat + limites.maxLat) / 2,
  );
}

/// Zoom aproximado para que la ruta completa quepa en pantalla.
double zoomParaRuta(Ruta ruta) {
  if (ruta.puntos.length < 2) return 16;
  final limites = _limites(ruta);
  final centro = centroRuta(ruta);
  final ancho =
      (limites.maxLon - limites.minLon) *
      math.cos(centro.lat * math.pi / 180);
  final alto = limites.maxLat - limites.minLat;
  final span = math.max(ancho, alto);
  if (span <= 0) return 16;
  // 0,01° equivale aproximadamente al nivel de zoom 16.
  final zoom = 16 - math.log(span / 0.01) / math.ln2;
  return zoom.clamp(9.0, 17.0);
}
