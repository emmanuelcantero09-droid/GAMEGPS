/// Búsqueda de lugares reales usando Photon (datos de OpenStreetMap).
///
/// No necesita API key. Photon está pensado para búsquedas mientras se escribe,
/// a diferencia de Nominatim, que lo desaconseja.
library;

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

/// Cliente de geocodificación.
class ServicioBusqueda {
  static const Duration _tiempoEspera = Duration(seconds: 8);

  /// Devuelve hasta [limite] lugares que coinciden con [texto].
  Future<List<Lugar>> buscar(String texto, {int limite = 5}) async {
    final consulta = texto.trim();
    if (consulta.length < 3) return const [];

    final uri = Uri.https('photon.komoot.io', '/api/', {
      'q': consulta,
      'limit': '$limite',
      'lang': 'es',
    });

    final cliente = HttpClient()
      ..userAgent = 'GAMEGPS/0.1 (Android; OpenStreetMap)';
    try {
      final peticion = await cliente.getUrl(uri).timeout(_tiempoEspera);
      final respuesta = await peticion.close().timeout(_tiempoEspera);
      if (respuesta.statusCode != 200) {
        throw HttpException('HTTP ${respuesta.statusCode}', uri: uri);
      }
      final cuerpo = await respuesta.transform(utf8.decoder).join();
      final datos = jsonDecode(cuerpo) as Map<String, dynamic>;
      final features = (datos['features'] as List<dynamic>? ?? []);

      return features
          .whereType<Map<String, dynamic>>()
          .map(lugarDesdeJson)
          .toList(growable: false);
    } finally {
      cliente.close();
    }
  }
}
