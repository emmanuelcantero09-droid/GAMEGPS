import 'dart:ui';

import 'package:maplibre/maplibre.dart';

import 'rutas.dart';

/// Convierte el recorrido real del usuario en una línea degradada bajo el marcador.
/// Cada lista es `[longitud, latitud]`. Se necesitan al menos dos puntos.
List<Layer> capasRastro(List<List<double>> puntos) {
  if (puntos.length < 2) return const [];

  final linea = Feature<LineString>(
    id: 'rastro-actual',
    geometry: LineString.from([
      for (final punto in puntos) [punto[0], punto[1]].xy,
    ]),
  );

  return [
    PolylineLayer(polylines: [linea], color: const Color(0x9905070F), width: 9),
    PolylineLayer(polylines: [linea], color: const Color(0xFF00E5FF), width: 4),
  ];
}

/// Convierte la geometría de una [Ruta] en capas dibujables por MapLibre.
///
/// La primera capa es un halo oscuro que hace que la línea se distinga sobre
/// cualquier estilo de mapa; la segunda es la línea con el color elegido.
List<Layer> capasRuta(Ruta ruta, {required Color color, required int grosor}) {
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
    PolylineLayer(polylines: [linea], color: color, width: grosor),
  ];
}
