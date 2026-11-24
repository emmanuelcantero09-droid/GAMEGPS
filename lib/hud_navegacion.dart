/// HUD direccional de navegación: maniobra próxima, distancia, ETA,
/// velocidad, rumbo y progreso. Se dibuja encima del mapa con estética
/// Hollow Knight para que el viaje se sienta como un GPS real.
library;

import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import 'rutas.dart';

/// Icono de la maniobra Following OSRM's type/modifier.
IconData iconoManiobra(PasoRuta paso) {
  if (paso.esLlegada) return Icons.flag;
  final tipo = paso.tipo;
  final modifier = paso.modifier;
  final izquierda = modifier.contains('left');

  if (tipo == 'roundabout' || tipo == 'rotary' || tipo == 'roundabout turn') {
    return izquierda ? Icons.roundabout_left : Icons.roundabout_right;
  }
  if (tipo == 'on ramp' || tipo == 'off ramp' || tipo == 'merge') {
    return Icons.merge_type;
  }
  if (tipo == 'fork') return Icons.alt_route;
  if (tipo == 'end of road') {
    return izquierda ? Icons.turn_left : Icons.turn_right;
  }
  if (modifier.contains('slight')) {
    return izquierda ? Icons.turn_slight_left : Icons.turn_slight_right;
  }
  if (modifier.contains('sharp')) {
    return izquierda ? Icons.turn_sharp_left : Icons.turn_sharp_right;
  }
  if (modifier.contains('uturn')) {
    return izquierda ? Icons.turn_left : Icons.turn_right;
  }
  if (modifier.contains('right')) return Icons.turn_right;
  if (modifier.contains('left')) return Icons.turn_left;
  return Icons.straight;
}

/// Letra cardinal correspondiente a un rumbo en grados.
String cardinal(double grados) {
  const nombres = ['N', 'NE', 'E', 'SE', 'S', 'SO', 'O', 'NO'];
  final indice = (((grados + 22.5) % 360) / 45).floor() % 8;
  return nombres[indice];
}

/// El ángulo de giro de una maniobra, para resaltarla en la tarjeta.
double anguloManiobra(PasoRuta paso) {
  if (paso.modifier.contains('right')) return 0;
  if (paso.modifier.contains('left')) return math.pi;
  return 0;
}

/// Tarjeta superior con la próxima maniobra y la siguiente.
class HudManiobra extends StatelessWidget {
  const HudManiobra({
    super.key,
    required this.maniobras,
    required this.unidades,
    required this.restante,
    required this.duracionRestante,
  });

  final List<({PasoRuta paso, double metros})> maniobras;
  final UnidadesRuta unidades;
  final double restante;
  final double duracionRestante;

  @override
  Widget build(BuildContext context) {
    if (maniobras.isEmpty) return const SizedBox.shrink();
    final actual = maniobras.first;
    final siguiente = maniobras.length > 1 ? maniobras[1] : null;
    final llegada = actual.paso.esLlegada;
    final color = llegada ? const Color(0xFFFF3D71) : const Color(0xFF00E5FF);

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        color: const Color(0xF210182B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.75), width: 1.5),
        boxShadow: const [
          BoxShadow(
            color: Color(0xAA05070F),
            blurRadius: 14,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              // El anillo se llena al acercarse a la maniobra: se ve de un
              // vistazo cuánto falta sin leer la distancia.
              SizedBox(
                width: 56,
                height: 56,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Positioned.fill(
                      child: CircularProgressIndicator(
                        value: (1 - actual.metros / 1000).clamp(0.0, 1.0),
                        color: color,
                        backgroundColor: color.withValues(alpha: 0.12),
                        strokeWidth: 3,
                      ),
                    ),
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 220),
                        child: Transform.rotate(
                          key: ValueKey(iconoManiobra(actual.paso)),
                          angle: anguloManiobra(actual.paso),
                          child: Icon(
                            iconoManiobra(actual.paso),
                            color: color,
                            size: 34,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 220),
                  child: Column(
                    key: ValueKey(actual.paso.instruccion),
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        formatoDistancia(actual.metros, unidades),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          height: 1.05,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        actual.paso.nombreCalle.isEmpty
                            ? actual.paso.instruccion
                            : actual.paso.nombreCalle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFFE8E3D4),
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        actual.paso.instruccion,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFF8FA3BF),
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.flag, size: 12, color: Color(0xFFFF3D71)),
              const SizedBox(width: 5),
              Text(
                '${formatoDistancia(restante, unidades)} · '
                '${formatoDuracion(duracionRestante, IdiomaInstrucciones.es)}',
                style: const TextStyle(color: Color(0xFFCFCCBE), fontSize: 11),
              ),
            ],
          ),
          if (siguiente != null) ...[
            const SizedBox(height: 6),
            Container(height: 1, color: const Color(0x3300E5FF)),
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(iconoManiobra(siguiente.paso), size: 17, color: color),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Después: ${siguiente.paso.instruccion}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF8FA3BF),
                      fontSize: 10,
                    ),
                  ),
                ),
                Text(
                  formatoDistancia(siguiente.metros, unidades),
                  style: TextStyle(
                    color: color,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// Barra inferior con velocidad, rumbo, llegada estimada y progreso.
class HudResumen extends StatelessWidget {
  const HudResumen({
    super.key,
    required this.velocidadKmh,
    required this.rumbo,
    required this.progreso,
    required this.llegada,
    required this.onDetener,
    required this.onReencuadrar,
    this.restanteMetros,
    this.segundosRestantes,
    this.unidades = UnidadesRuta.kilometros,
  });

  final double velocidadKmh;
  final double rumbo;
  final double progreso;
  final DateTime llegada;
  final VoidCallback onDetener;
  final VoidCallback onReencuadrar;
  final double? restanteMetros;
  final double? segundosRestantes;
  final UnidadesRuta unidades;

  String get _hora =>
      '${llegada.hour.toString().padLeft(2, '0')}:'
      '${llegada.minute.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
      decoration: BoxDecoration(
        color: const Color(0xF210182B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0x9900E5FF)),
        boxShadow: const [
          BoxShadow(
            color: Color(0xAA05070F),
            blurRadius: 14,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              _Dato(
                icono: Icons.speed,
                valor: velocidadKmh.round().toString(),
                unidad: 'km/h',
              ),
              _Separador(),
              _Dato(
                icono: Icons.navigation,
                valor: cardinal(rumbo),
                unidad: '${rumbo.round()}°',
                giro: rumbo,
              ),
              _Separador(),
              _Dato(icono: Icons.schedule, valor: _hora, unidad: 'llegada'),
              const Spacer(),
              IconButton(
                icon: const Icon(
                  Icons.center_focus_strong,
                  color: Color(0xFF00E5FF),
                ),
                tooltip: 'Ver ruta completa',
                onPressed: onReencuadrar,
              ),
              IconButton(
                icon: const Icon(Icons.stop_circle, color: Color(0xFFFF3D71)),
                tooltip: 'Terminar navegación',
                onPressed: onDetener,
              ),
            ],
          ),
          const SizedBox(height: 7),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progreso.clamp(0.0, 1.0),
              minHeight: 5,
              color: const Color(0xFF00E5FF),
              backgroundColor: const Color(0x3300E5FF),
            ),
          ),
          if (restanteMetros != null) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(Icons.route, size: 12, color: Color(0xFF00E5FF)),
                const SizedBox(width: 5),
                Text(
                  'Faltan ${formatoDistancia(restanteMetros!, unidades)}'
                  '${segundosRestantes == null ? '' : ' · ${formatoDuracion(segundosRestantes!, IdiomaInstrucciones.es)}'}'
                  ' · ${(progreso.clamp(0.0, 1.0) * 100).round()}%',
                  style: const TextStyle(
                    color: Color(0xFFCFCCBE),
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _Dato extends StatelessWidget {
  const _Dato({
    required this.icono,
    required this.valor,
    required this.unidad,
    this.giro,
  });

  final IconData icono;
  final String valor;
  final String unidad;
  final double? giro;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Transform.rotate(
          angle: (giro ?? 0) * math.pi / 180,
          child: Icon(icono, size: 17, color: const Color(0xFF00E5FF)),
        ),
        const SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              valor,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.bold,
                height: 1,
              ),
            ),
            Text(
              unidad,
              style: const TextStyle(color: Color(0xFF8FA3BF), fontSize: 9),
            ),
          ],
        ),
      ],
    );
  }
}

class _Separador extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 26,
      width: 1,
      margin: const EdgeInsets.symmetric(horizontal: 10),
      color: const Color(0x3300E5FF),
    );
  }
}
