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
    this.tipo = '',
    this.modifier = '',
    this.salida,
    this.nombreCalle = '',
    this.lon,
    this.lat,
    this.desdeInicioMetros = 0,
  });

  final String instruccion;
  final double distanciaMetros;

  /// Datos de la maniobra de OSRM, usados por el HUD direccional.
  final String tipo;
  final String modifier;
  final Object? salida;
  final String nombreCalle;
  final double? lon;
  final double? lat;

  /// Metros acumulados desde el inicio de la ruta hasta esta maniobra.
  final double desdeInicioMetros;

  bool get esLlegada => tipo == 'arrive';
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
  final coord =
      '${lonOrigen.toStringAsFixed(6)},'
      '${latOrigen.toStringAsFixed(6)};'
      '${lonDestino.toStringAsFixed(6)},'
      '${latDestino.toStringAsFixed(6)}';
  return Uri.https(modo.host, '${modo.perfil}$coord', {
    'overview': 'full',
    'geometries': 'geojson',
    'steps': 'true',
  });
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
    'turn' =>
      es
          ? 'Gira ${direccionManiobra(modifier, idioma)}'
          : 'Turn ${direccionManiobra(modifier, idioma)}',
    'continue' =>
      es
          ? 'Continúa ${direccionManiobra(modifier, idioma)}'
          : 'Continue ${direccionManiobra(modifier, idioma)}',
    'merge' =>
      es
          ? 'Incorpórate ${direccionManiobra(modifier, idioma)}'
          : 'Merge ${direccionManiobra(modifier, idioma)}',
    'on ramp' =>
      es
          ? 'Toma la rampa ${direccionManiobra(modifier, idioma)}'
          : 'Take the ramp ${direccionManiobra(modifier, idioma)}',
    'off ramp' =>
      es
          ? 'Sal de la rampa ${direccionManiobra(modifier, idioma)}'
          : 'Take the exit ${direccionManiobra(modifier, idioma)}',
    'fork' =>
      es
          ? 'Toma el desvío ${direccionManiobra(modifier, idioma)}'
          : 'Keep ${direccionManiobra(modifier, idioma)} at the fork',
    'end of road' =>
      es
          ? 'Al final de la calle gira ${direccionManiobra(modifier, idioma)}'
          : 'At the end of the road turn ${direccionManiobra(modifier, idioma)}',
    'roundabout' || 'rotary' || 'roundabout turn' =>
      salida == null
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
      .map((p) => <double>[(p[0] as num).toDouble(), (p[1] as num).toDouble()])
      .toList(growable: false);

  final pasos = <PasoRuta>[];
  var acumulado = 0.0;
  final piernas = ruta['legs'] as List<dynamic>? ?? [];
  for (final pierna in piernas) {
    final lista =
        (pierna as Map<String, dynamic>)['steps'] as List<dynamic>? ?? [];
    for (final crudo in lista) {
      final paso = crudo as Map<String, dynamic>;
      final maniobra = (paso['maneuver'] as Map<String, dynamic>?) ?? const {};
      final distancia = (paso['distance'] as num?)?.toDouble() ?? 0;
      final nombre = paso['name']?.toString() ?? '';
      // OSRM con geometries=geojson devuelve la ubicación de la maniobra como
      // [longitud, latitud]. Algunas respuestas antiguas usan un objeto con
      // longitude/latitude; se aceptan ambos formatos para no perder la ruta.
      final crudoUbicacion = maniobra['location'];
      final listaUbicacion = crudoUbicacion is List ? crudoUbicacion : null;
      final mapaUbicacion = crudoUbicacion is Map
          ? Map<String, dynamic>.from(crudoUbicacion)
          : null;
      final double? lonManiobra;
      final double? latManiobra;
      if (listaUbicacion != null && listaUbicacion.length >= 2) {
        lonManiobra = (listaUbicacion[0] as num?)?.toDouble();
        latManiobra = (listaUbicacion[1] as num?)?.toDouble();
      } else {
        lonManiobra = (mapaUbicacion?['longitude'] as num?)?.toDouble();
        latManiobra = (mapaUbicacion?['latitude'] as num?)?.toDouble();
      }
      acumulado += distancia;
      pasos.add(
        PasoRuta(
          instruccion: instruccionPaso(maniobra, nombre, idioma: idioma),
          distanciaMetros: distancia,
          tipo: maniobra['type']?.toString() ?? '',
          modifier: maniobra['modifier']?.toString() ?? '',
          salida: maniobra['exit'],
          nombreCalle: nombre,
          lon: lonManiobra,
          lat: latManiobra,
          desdeInicioMetros: acumulado,
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
      throw const RutaException(
        'El servicio devolvió una respuesta inesperada.',
      );
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
  return (minLon: minLon, maxLon: maxLon, minLat: minLat, maxLat: maxLat);
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

/// Distancia en metros entre dos coordenadas (fórmula de Haversine).
double distanciaGeo(double lat1, double lon1, double lat2, double lon2) {
  const radio = 6371000.0;
  final dLat = (lat2 - lat1) * math.pi / 180;
  final dLon = (lon2 - lon1) * math.pi / 180;
  final a =
      math.pow(math.sin(dLat / 2), 2) +
      math.cos(lat1 * math.pi / 180) *
          math.cos(lat2 * math.pi / 180) *
          math.pow(math.sin(dLon / 2), 2);
  return 2 * radio * math.asin(math.sqrt(a));
}

/// Rumbo (grados 0..360, 0 = norte) entre dos coordenadas.
double rumboGeo(double lat1, double lon1, double lat2, double lon2) {
  final phi1 = lat1 * math.pi / 180;
  final phi2 = lat2 * math.pi / 180;
  final delta = (lon2 - lon1) * math.pi / 180;
  final y = math.sin(delta) * math.cos(phi2);
  final x =
      math.cos(phi1) * math.sin(phi2) -
      math.sin(phi1) * math.cos(phi2) * math.cos(delta);
  return (math.atan2(y, x) * 180 / math.pi + 360) % 360;
}

/// Progreso del usuario sobre la geometría de la ruta.
///
/// Devuelve los metros ya recorridos y los que quedan. Se calcula proyectando
/// la posición sobre el polilínea, así que funciona aunque el GPS se salga un
/// poco de la calle o salte de un punto a otro.
({double recorrido, double restante}) progresoRuta(
  Ruta ruta,
  double lat,
  double lon,
) {
  final puntos = ruta.puntos;
  if (puntos.length < 2) {
    return (recorrido: 0, restante: ruta.distanciaMetros);
  }
  var mejorDistancia = double.infinity;
  var mejorIndice = 0;
  var mejorFraccion = 0.0;
  var acumulado = 0.0;
  var total = 0.0;
  final longitudes = <double>[acumulado];

  for (var i = 0; i < puntos.length - 1; i++) {
    final a = puntos[i];
    final b = puntos[i + 1];
    final segmento = distanciaGeo(a[1], a[0], b[1], b[0]);
    total += segmento;
    acumulado += segmento;
    longitudes.add(acumulado);

    final dx = b[0] - a[0];
    final dy = b[1] - a[1];
    final denominador = dx * dx + dy * dy;
    final fraccion = denominador == 0
        ? 0.0
        : (((lon - a[0]) * dx + (lat - a[1]) * dy) / denominador)
              .clamp(0.0, 1.0)
              .toDouble();
    final proyectadoLon = a[0] + dx * fraccion;
    final proyectadoLat = a[1] + dy * fraccion;
    final separacion = distanciaGeo(lat, lon, proyectadoLat, proyectadoLon);
    if (separacion < mejorDistancia) {
      mejorDistancia = separacion;
      mejorIndice = i;
      mejorFraccion = fraccion;
    }
  }

  if (total <= 0) return (recorrido: 0, restante: ruta.distanciaMetros);
  final escala = ruta.distanciaMetros / total;
  final recorrido =
      ((longitudes[mejorIndice] +
                  (longitudes[mejorIndice + 1] - longitudes[mejorIndice]) *
                      mejorFraccion) *
              escala)
          .clamp(0.0, ruta.distanciaMetros)
          .toDouble();
  return (recorrido: recorrido, restante: ruta.distanciaMetros - recorrido);
}

/// Próximas maniobras que faltan, con la distancia real hasta cada una.
List<({PasoRuta paso, double metros})> maniobrasPendientes(
  Ruta ruta,
  double recorridoMetros, {
  int cantidad = 2,
}) {
  final pendientes = <({PasoRuta paso, double metros})>[];
  for (final paso in ruta.pasos) {
    if (paso.desdeInicioMetros <= recorridoMetros + 5) continue;
    pendientes.add((
      paso: paso,
      metros: paso.desdeInicioMetros - recorridoMetros,
    ));
    if (pendientes.length >= cantidad) break;
  }
  if (pendientes.isEmpty && ruta.pasos.isNotEmpty) {
    pendientes.add((paso: ruta.pasos.last, metros: 0));
  }
  return pendientes;
}

/// Segundos que faltan según la velocidad media de la ruta calculada.
double segundosRestantes(Ruta ruta, double restanteMetros) {
  if (ruta.duracionSegundos <= 0 || ruta.distanciaMetros <= 0) return 0;
  final velocidad = ruta.distanciaMetros / ruta.duracionSegundos;
  return velocidad <= 0 ? 0 : restanteMetros / velocidad;
}

/// Zoom aproximado para que la ruta completa quepa en pantalla.
double zoomParaRuta(Ruta ruta) {
  if (ruta.puntos.length < 2) return 16;
  final limites = _limites(ruta);
  final centro = centroRuta(ruta);
  final ancho =
      (limites.maxLon - limites.minLon) * math.cos(centro.lat * math.pi / 180);
  final alto = limites.maxLat - limites.minLat;
  final span = math.max(ancho, alto);
  if (span <= 0) return 16;
  // 0,01° equivale aproximadamente al nivel de zoom 16.
  final zoom = 16 - math.log(span / 0.01) / math.ln2;
  return zoom.clamp(9.0, 17.0);
}
