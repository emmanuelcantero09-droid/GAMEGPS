import 'dart:ui';

import 'package:maplibre/maplibre.dart';

/// Mapa generado por la propia app: sin internet, sin API key y sin permisos.
///
/// Las calles, manzanas, parques y el marcador son geometrías GeoJSON creadas
/// en Dart y dibujadas por MapLibre. Es el reemplazo offline de las teselas.
class MapaLocal {
  /// Separación entre calles (~200 m).
  static const double paso = 0.0018;

  /// Medellín, Colombia: zona cubierta por el paquete de teselas embebidas.
  static const double centroPorDefectoLon = -75.5812;
  static const double centroPorDefectoLat = 6.2442;

  /// Estilo mínimo: solo fondo. No declara ninguna fuente remota.
  static const String style = '''
{
  "version": 8,
  "name": "GAME GPS Local",
  "sources": {},
  "layers": [
    {
      "id": "fondo",
      "type": "background",
      "paint": {"background-color": "#05070F"}
    }
  ]
}
''';

  /// Capas declarativas que dibujan el mapa alrededor de [lon], [lat].
  static List<Layer> layers({required double lon, required double lat}) {
    const int radio = 9;

    final parques = <Feature<Polygon>>[];
    final bloques = <Feature<Polygon>>[];
    final calles = <Feature<LineString>>[];
    final avenidas = <Feature<LineString>>[];

    // Cuadrícula de calles.
    for (var i = -radio; i < radio; i++) {
      final oeste = lon + i * paso;
      calles.add(
        Feature<LineString>(
          id: 'calle-v-$i',
          geometry: LineString.from([
            [oeste, lat - radio * paso].xy,
            [oeste, lat + radio * paso].xy,
          ]),
        ),
      );

      final sur = lat + i * paso;
      calles.add(
        Feature<LineString>(
          id: 'calle-h-$i',
          geometry: LineString.from([
            [lon - radio * paso, sur].xy,
            [lon + radio * paso, sur].xy,
          ]),
        ),
      );
    }

    // Manzanas entre calles; algunas se pintan como parque.
    for (var x = -radio; x < radio; x++) {
      for (var y = -radio; y < radio; y++) {
        final o = lon + x * paso;
        final n = lat + y * paso;
        final margen = paso * 0.12;
        final anillo = <double>[
          o + margen, n + margen, //
          o + paso - margen, n + margen,
          o + paso - margen, n + paso - margen,
          o + margen, n + paso - margen,
          o + margen, n + margen,
        ];
        final esParque = (x + y) % 7 == 0;
        (esParque ? parques : bloques).add(
          Feature<Polygon>(
            id: 'manzana-$x-$y',
            geometry: Polygon.build([anillo]),
          ),
        );
      }
    }

    // Dos avenidas diagonales para que no parezca una cuadrícula perfecta.
    avenidas.add(
      Feature<LineString>(
        id: 'avenida-1',
        geometry: LineString.from([
          [lon - radio * paso, lat - radio * paso].xy,
          [lon + radio * paso, lat + radio * paso].xy,
        ]),
      ),
    );
    avenidas.add(
      Feature<LineString>(
        id: 'avenida-2',
        geometry: LineString.from([
          [lon - radio * paso, lat + radio * paso].xy,
          [lon + radio * paso, lat - radio * paso].xy,
        ]),
      ),
    );

    return [
      PolygonLayer(
        polygons: parques,
        color: const Color(0xFF0C2A22),
        outlineColor: const Color(0xFF123B2F),
      ),
      PolygonLayer(
        polygons: bloques,
        color: const Color(0xFF0B1426),
        outlineColor: const Color(0xFF132340),
      ),
      PolylineLayer(
        polylines: calles,
        color: const Color(0xFF0A1020),
        width: 8,
      ),
      PolylineLayer(
        polylines: calles,
        color: const Color(0xFF1E3A5F),
        width: 3,
      ),
      PolylineLayer(
        polylines: avenidas,
        color: const Color(0x4426A8FF),
        width: 2,
      ),
    ];
  }
}
