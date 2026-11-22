/// Retos y desafíos que entregan puntos extra en GAME GPS.
library;

import 'package:material_ui/material_ui.dart';

import 'puntos.dart';

/// Los retos diarios se reinician cada día; los otros se ganan una sola vez.
enum TipoReto { diario, distancia, destinos }

/// Un objetivo del jugador. El progreso se calcula desde [Puntos].
class Reto {
  const Reto({
    required this.id,
    required this.titulo,
    required this.descripcion,
    required this.tipo,
    required this.meta,
    required this.puntos,
    required this.icono,
  });

  final String id;
  final String titulo;
  final String descripcion;
  final TipoReto tipo;
  final double meta;
  final int puntos;
  final IconData icono;

  /// Cuánto lleva el jugador de este reto.
  double progreso(Puntos puntos) {
    switch (id) {
      case 'caminar500':
        return puntos.metrosHoy;
      case 'destinoDiario':
        return puntos.destinosHoy.toDouble();
      case 'buscar3':
        return puntos.busquedasHoy.toDouble();
      case 'dist1km':
      case 'dist5km':
      case 'dist10km':
        return puntos.metrosTotales;
      case 'dest3':
      case 'dest10':
      case 'dest25':
        return puntos.destinosDistintos.toDouble();
      default:
        return 0;
    }
  }

  /// Los retos diarios pueden volverse a ganar al día siguiente.
  String claveEntrega(Puntos puntos) =>
      tipo == TipoReto.diario ? 'reto:$id:${puntos.ultimoDia}' : 'reto:$id';

  bool estaCompleto(Puntos puntos) => progreso(puntos) >= meta;

  /// Texto corto para la barra de progreso de la interfaz.
  String progresoTexto(Puntos puntos) {
    final valor = progreso(puntos).clamp(0.0, meta).round();
    if (tipo == TipoReto.distancia) {
      return '${(valor / 1000).toStringAsFixed(1)} / ${(meta / 1000).round()} km';
    }
    if (id == 'caminar500') return '$valor / ${meta.round()} m';
    return '$valor / ${meta.round()}';
  }
}

/// Retos diarios (se repiten) y metas fijas de distancia y destinos.
const List<Reto> retos = [
  Reto(
    id: 'caminar500',
    titulo: 'Caminá 500 m hoy',
    descripcion: 'Reto diario · muévete con la app abierta',
    tipo: TipoReto.diario,
    meta: 500,
    puntos: 20,
    icono: Icons.directions_walk,
  ),
  Reto(
    id: 'destinoDiario',
    titulo: 'Llegá a 1 destino hoy',
    descripcion: 'Reto diario · elige un lugar y alcanzalo',
    tipo: TipoReto.diario,
    meta: 1,
    puntos: 10,
    icono: Icons.flag,
  ),
  Reto(
    id: 'buscar3',
    titulo: 'Buscá 3 lugares hoy',
    descripcion: 'Reto diario · usa el buscador del mapa',
    tipo: TipoReto.diario,
    meta: 3,
    puntos: 10,
    icono: Icons.search,
  ),
  Reto(
    id: 'dist1km',
    titulo: 'Primer kilómetro',
    descripcion: 'Meta total · 1 km recorrido',
    tipo: TipoReto.distancia,
    meta: 1000,
    puntos: 15,
    icono: Icons.route,
  ),
  Reto(
    id: 'dist5km',
    titulo: 'Explorador',
    descripcion: 'Meta total · 5 km recorridos',
    tipo: TipoReto.distancia,
    meta: 5000,
    puntos: 30,
    icono: Icons.explore,
  ),
  Reto(
    id: 'dist10km',
    titulo: 'Maratón',
    descripcion: 'Meta total · 10 km recorridos',
    tipo: TipoReto.distancia,
    meta: 10000,
    puntos: 50,
    icono: Icons.emoji_events,
  ),
  Reto(
    id: 'dest3',
    titulo: 'Tres paradas',
    descripcion: 'Meta total · 3 destinos distintos',
    tipo: TipoReto.destinos,
    meta: 3,
    puntos: 20,
    icono: Icons.place,
  ),
  Reto(
    id: 'dest10',
    titulo: 'Diez paradas',
    descripcion: 'Meta total · 10 destinos distintos',
    tipo: TipoReto.destinos,
    meta: 10,
    puntos: 50,
    icono: Icons.map,
  ),
  Reto(
    id: 'dest25',
    titulo: 'Veinte y cinco paradas',
    descripcion: 'Meta total · 25 destinos distintos',
    tipo: TipoReto.destinos,
    meta: 25,
    puntos: 100,
    icono: Icons.public,
  ),
];

/// Resultado de revisar los retos tras un cambio en los puntos.
class ResultadoRetos {
  const ResultadoRetos({
    required this.puntos,
    required this.nuevos,
    required this.ganados,
  });

  final Puntos puntos;
  final List<Reto> nuevos;
  final int ganados;
}

/// Entrega automáticamente todos los retos que ya alcanzaron su meta.
/// Cada reto se paga una sola vez (los diarios, una vez por día).
ResultadoRetos evaluarRetos(Puntos puntos) {
  var actual = puntos;
  final nuevos = <Reto>[];
  var ganados = 0;

  for (final reto in retos) {
    if (!reto.estaCompleto(actual)) continue;
    final clave = reto.claveEntrega(actual);
    if (actual.entregados.contains(clave)) continue;
    actual = actual.marcarEntrega(clave, reto.puntos);
    ganados += reto.puntos;
    nuevos.add(reto);
  }

  return ResultadoRetos(puntos: actual, nuevos: nuevos, ganados: ganados);
}
