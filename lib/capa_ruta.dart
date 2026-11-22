import 'dart:ui';

import 'package:maplibre/maplibre.dart';

import 'rutas.dart';

/// Convierte la geometría de una [Ruta] en capas dibujables por MapLibre.
///
/// La primera capa es un halo oscuro que hace que la línea se distinga sobre
/// cualquier estilo de mapa; la segunda es la línea con el color elegido.
List<Layer> capasRuta(
  Ruta ruta, {
  required Color color,
  required int grosor,
}) {
  final linea = Feature<LineString>(
    id: 'ruta-activa',
    geometry: LineString.from([
      for (final punto in ruta.puntos) [punto[0], punto[1]].xy,
    ]),
  );

  return [
    PolylineLayer(
      polylines: [linea],
      color: const Color(0xCC05070F),
      width: grosor + 4,
    ),
    PolylineLayer(
      polylines: [linea],
      color: color,
      width: grosor,
    ),
  ];
}
