/// Fuentes de mapa de GAME GPS: mapa propio offline, estilo vectorial propio
/// y cuatro reinos inspirados en Hollow Knight. Ninguna usa Google Maps ni
/// requiere registro.
library;

import 'estilo_custom.dart';
import 'estilos_hollow.dart';

/// Mapa de calle real con nombres y números de vía. Es una tesela raster, así
/// que no depende de fuentes vectoriales, glifos ni sprites externos. Usa
/// teselas de OpenStreetMap y un espejo de respaldo; ninguna requiere clave.
const String estiloGps =
    r'''{"version":8,"name":"GPS · Calles reales","sources":{"calles":{"type":"raster","tileSize":256,"tiles":["https://tile.openstreetmap.org/{z}/{x}/{y}.png","https://a.tile.openstreetmap.fr/osmfr/{z}/{x}/{y}.png"],"attribution":"© OpenStreetMap contributors"}},"layers":[{"id":"fondo","type":"background","paint":{"background-color":"#0B1220"}},{"id":"calles","type":"raster","source":"calles","paint":{"raster-fade-duration":0,"raster-brightness-max":0.98,"raster-saturation":-0.12,"raster-contrast":0.10}},{"id":"tinete_gps","type":"background","paint":{"background-color":"#07111F","background-opacity":0.16}}]}''';

/// Identificador de la fuente elegida.
enum ProveedorMapaId {
  local,
  custom,
  gps,
  hollowNoche,
  hollowNiebla,
  hollowCristal,
  hollowCarmesi,
}

/// Descripción de una fuente vectorial o del mapa propio.
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

  /// `null` significa que se sirven las teselas reales embebidas desde
  /// `lib/teselas_locales.dart`.
  final String? style;
}

/// Catálogo de fuentes disponibles.
final List<ProveedorMapa> proveedoresMapa = [
  const ProveedorMapa(
    id: ProveedorMapaId.local,
    nombre: 'Propio · calles reales offline',
    detalle:
        'Teselas reales embebidas · nombres de vía · sin internet ni clave',
  ),
  const ProveedorMapa(
    id: ProveedorMapaId.gps,
    nombre: 'GPS · Calles reales',
    detalle: 'Nombres de calles y números · OpenStreetMap, sin clave',
    style: estiloGps,
  ),
  const ProveedorMapa(
    id: ProveedorMapaId.custom,
    nombre: 'GAME GPS Custom',
    detalle: 'Vectorial · cian esmeralda · OpenFreeMap',
    style: estiloGameGps,
  ),
  for (final paleta in paletasHollow)
    ProveedorMapa(
      id: _idDePaleta[paleta.id]!,
      nombre: paleta.nombre,
      detalle: paleta.detalle,
      style: estiloHollow(paleta),
    ),
];

const Map<String, ProveedorMapaId> _idDePaleta = {
  'hollow_noche': ProveedorMapaId.hollowNoche,
  'hollow_niebla': ProveedorMapaId.hollowNiebla,
  'hollow_cristal': ProveedorMapaId.hollowCristal,
  'hollow_carmesi': ProveedorMapaId.hollowCarmesi,
};
