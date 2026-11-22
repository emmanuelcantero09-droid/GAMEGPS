/// Fuentes de mapa gratuitas y sin API key. Ninguna pertenece a Google.
library;

import 'estilo_custom.dart';

/// Identificador de la fuente elegida.
enum ProveedorMapaId { local, cartoDark, osm, hot, topo, custom }

/// Descripción de una fuente de teselas o del mapa propio.
class ProveedorMapa {
  const ProveedorMapa({
    required this.id,
    required this.nombre,
    required this.detalle,
    this.style,
  });

  final ProveedorMapaId id;
  final String nombre;
  final String detalle;

  /// `null` significa que se usa el mapa generado en `mapa_local.dart`.
  final String? style;
}

String _estiloRaster({
  required String nombre,
  required List<String> tiles,
  required String attribution,
}) {
  final lista = tiles.map((t) => '"$t"').join(', ');
  return '''
{
  "version": 8,
  "name": "$nombre",
  "sources": {
    "teselas": {
      "type": "raster",
      "tiles": [$lista],
      "tileSize": 256,
      "attribution": "$attribution"
    }
  },
  "layers": [
    {
      "id": "fondo",
      "type": "background",
      "paint": {"background-color": "#05070F"}
    },
    {
      "id": "teselas",
      "type": "raster",
      "source": "teselas"
    }
  ]
}
''';
}

final String _cartoDark = _estiloRaster(
  nombre: 'GAME GPS CARTO Dark',
  tiles: const [
    'https://a.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}.png',
    'https://b.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}.png',
    'https://c.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}.png',
  ],
  attribution: '© OpenStreetMap contributors © CARTO',
);

final String _osm = _estiloRaster(
  nombre: 'OpenStreetMap Standard',
  tiles: const ['https://tile.openstreetmap.org/{z}/{x}/{y}.png'],
  attribution: '© OpenStreetMap contributors',
);

final String _hot = _estiloRaster(
  nombre: 'OpenStreetMap HOT',
  tiles: const ['https://a.tile.openstreetmap.fr/hot/{z}/{x}/{y}.png'],
  attribution: '© OpenStreetMap contributors, HOT',
);

final String _topo = _estiloRaster(
  nombre: 'OpenTopoMap',
  tiles: const ['https://a.tile.opentopomap.org/{z}/{x}/{y}.png'],
  attribution: '© OpenTopoMap, © OpenStreetMap contributors',
);

/// Catálogo de fuentes disponibles.
final List<ProveedorMapa> proveedoresMapa = [
  const ProveedorMapa(
    id: ProveedorMapaId.local,
    nombre: 'Propio · offline',
    detalle: 'Calles generadas por la app. Sin internet ni key.',
  ),
  const ProveedorMapa(
    id: ProveedorMapaId.custom,
    nombre: 'GAME GPS Custom',
    detalle: 'Vectorial · colores propios · OpenFreeMap',
    style: estiloGameGps,
  ),
  ProveedorMapa(
    id: ProveedorMapaId.cartoDark,
    nombre: 'CARTO Dark',
    detalle: 'OSM · estilo oscuro · gratis, sin key.',
    style: _cartoDark,
  ),
  ProveedorMapa(
    id: ProveedorMapaId.osm,
    nombre: 'OpenStreetMap',
    detalle: 'Mapa estándar · gratis, sin key.',
    style: _osm,
  ),
  ProveedorMapa(
    id: ProveedorMapaId.hot,
    nombre: 'OSM HOT',
    detalle: 'Estilo Humanitarian · gratis, sin key.',
    style: _hot,
  ),
  ProveedorMapa(
    id: ProveedorMapaId.topo,
    nombre: 'OpenTopoMap',
    detalle: 'Mapa topográfico · gratis, sin key.',
    style: _topo,
  ),
];
