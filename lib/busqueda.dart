/// Búsqueda de lugares reales usando Photon (datos de OpenStreetMap).
///
/// No necesita API key. Photon está pensado para búsquedas mientras se escribe,
/// a diferencia de Nominatim, que lo desaconseja.
library;

import 'dart:async';
import 'dart:convert';
import 'dart:io';

/// Un lugar encontrado en la búsqueda.
class Lugar {
  const Lugar({
    required this.nombre,
    required this.detalle,
    required this.lon,
    required this.lat,
  });

  final String nombre;
  final String detalle;
  final double lon;
  final double lat;
}

/// Error con un mensaje listo para mostrar al usuario.
class BusquedaException implements Exception {
  const BusquedaException(this.mensaje);

  final String mensaje;

  @override
  String toString() => mensaje;
}

/// Convierte un resultado de Photon en un [Lugar].
///
/// Se mantiene público para poder probarlo sin acceder a internet.
Lugar lugarDesdeJson(Map<String, dynamic> feature) {
  final props = (feature['properties'] as Map<String, dynamic>?) ?? const {};
  final geometry = feature['geometry'] as Map<String, dynamic>?;
  final coords = geometry?['coordinates'] as List<dynamic>?;

  if (coords == null || coords.length < 2) {
    throw const FormatException('Resultado sin coordenadas');
  }

  final nombre = (props['name'] ??
          props['street'] ??
          props['city'] ??
          props['state'] ??
          'Lugar sin nombre')
      .toString();

  final partes = <String>[];
  for (final clave in ['city', 'state', 'country']) {
    final valor = props[clave]?.toString().trim();
    if (valor != null &&
        valor.isNotEmpty &&
        valor != nombre &&
        !partes.contains(valor)) {
      partes.add(valor);
    }
  }

  return Lugar(
    nombre: nombre,
    detalle: partes.join(', '),
    lon: (coords[0] as num).toDouble(),
    lat: (coords[1] as num).toDouble(),
  );
}

/// Construye la URL de consulta.
///
/// Photon solo admite `default`, `de`, `en` y `fr` en `lang`; enviar `es`
/// devuelve HTTP 400. Por eso se omite el parámetro y se usa el idioma local.
/// Si se pasan [lat] y [lon], Photon prioriza lugares cercanos a ese punto.
Uri uriBusqueda(
  String texto, {
  int limite = 5,
  double? lat,
  double? lon,
}) {
  final parametros = <String, String>{
    'q': texto.trim(),
    'limit': '$limite',
  };
  if (lat != null && lon != null) {
    parametros['lat'] = lat.toStringAsFixed(6);
    parametros['lon'] = lon.toStringAsFixed(6);
  }
  return Uri.https('photon.komoot.io', '/api/', parametros);
}

/// Cliente de geocodificación.
class ServicioBusqueda {
  static const Duration _tiempoEspera = Duration(seconds: 8);

  /// Devuelve hasta [limite] lugares que coinciden con [texto].
  ///
  /// [lat] y [lon] sesgan los resultados hacia tu ubicación.
  Future<List<Lugar>> buscar(
    String texto, {
    int limite = 5,
    double? lat,
    double? lon,
  }) async {
    final consulta = texto.trim();
    if (consulta.length < 3) return const [];

    final uri = uriBusqueda(
      consulta,
      limite: limite,
      lat: lat,
      lon: lon,
    );
    final cliente = HttpClient()
      ..userAgent = 'GAMEGPS/0.1 (Android; OpenStreetMap)';

    try {
      final peticion = await cliente.getUrl(uri).timeout(_tiempoEspera);
      final respuesta = await peticion.close().timeout(_tiempoEspera);
      if (respuesta.statusCode != 200) {
        throw BusquedaException(
          'El servicio de lugares devolvió un error. Inténtalo de nuevo.',
        );
      }
      final cuerpo = await respuesta.transform(utf8.decoder).join();
      final datos = jsonDecode(cuerpo) as Map<String, dynamic>;
      final features = datos['features'] as List<dynamic>? ?? [];

      return features
          .whereType<Map<String, dynamic>>()
          .map(lugarDesdeJson)
          .toList(growable: false);
    } on SocketException {
      throw const BusquedaException(
        'Sin conexión a internet. Revisa tu WiFi o datos móviles.',
      );
    } on TimeoutException {
      throw const BusquedaException(
        'La búsqueda tardó demasiado. Inténtalo de nuevo.',
      );
    } on FormatException {
      throw const BusquedaException(
        'El servicio devolvió una respuesta inesperada.',
      );
    } finally {
      cliente.close();
    }
  }
}
