/// Iconos propios de GAME GPS con aire a Hollow Knight.
///
/// Se dibujan con [CustomPainter] (sin copiar arte del juego) y se registran
/// en el estilo de MapLibre para sustituir a los símbolos genéricos del mapa:
/// el hospital deja de ser una cruz plana y pasa a ser una insignia luminosa.
library;

import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:maplibre/maplibre.dart';
import 'package:material_ui/material_ui.dart';

/// Símbolos disponibles en los puntos de interés.
enum IconoHollowId { hospital, comida, descanso, tesoro, pocion, runa }

class IconoHollow {
  const IconoHollow(this.id, this.etiqueta, this.color, this.brillo);

  final IconoHollowId id;
  final String etiqueta;
  final Color color;
  final Color brillo;

  /// Identificador que usa el documento MapLibre en `icon-image`.
  String get nombre => 'hollow_${id.name}';
}

const List<IconoHollow> iconosHollow = [
  IconoHollow(
    IconoHollowId.hospital,
    'Sanctuario',
    Color(0xFFC8404A),
    Color(0xFFFF9A9E),
  ),
  IconoHollow(
    IconoHollowId.comida,
    'Manjar',
    Color(0xFFE0A44C),
    Color(0xFFFFE0A0),
  ),
  IconoHollow(
    IconoHollowId.descanso,
    'Refugio',
    Color(0xFF7FCFA8),
    Color(0xFFC8F5DC),
  ),
  IconoHollow(
    IconoHollowId.tesoro,
    'Tesoro',
    Color(0xFFD4A24C),
    Color(0xFFFFE9A8),
  ),
  IconoHollow(
    IconoHollowId.pocion,
    'Poción',
    Color(0xFF58C8E0),
    Color(0xFFB8F0FA),
  ),
  IconoHollow(IconoHollowId.runa, 'Runa', Color(0xFFB08CD8), Color(0xFFE8D4FF)),
];

/// Dibuja una placa hexagonal con el glifo del tipo de punto.
class HollowIconoPainter extends CustomPainter {
  const HollowIconoPainter({required this.icono});

  final IconoHollow icono;

  @override
  void paint(ui.Canvas canvas, ui.Size size) {
    final escala = size.width / 100;
    canvas.save();
    canvas.scale(escala, escala);

    final sombra = ui.Paint()
      ..color = const ui.Color(0x99000000)
      ..maskFilter = const ui.MaskFilter.blur(ui.BlurStyle.normal, 5);
    canvas.drawCircle(const ui.Offset(50, 55), 38, sombra);

    _hexagono(canvas, 41, icono.color);
    _hexagono(canvas, 33, icono.brillo.withValues(alpha: 0.35), grosor: 2);

    final relleno = ui.Paint()..color = const ui.Color(0xFFE8E3D4);
    final brillo = ui.Paint()..color = icono.brillo;
    final trazo = ui.Paint()
      ..color = const ui.Color(0xFFE8E3D4)
      ..style = ui.PaintingStyle.stroke
      ..strokeWidth = 5
      ..strokeCap = ui.StrokeCap.round
      ..strokeJoin = ui.StrokeJoin.round;

    switch (icono.id) {
      case IconoHollowId.hospital:
        // Cruz de bordes afilados con un núcleo encendido: más llamativa
        // que el símbolo sanitario habitual.
        canvas.drawPath(
          ui.Path()
            ..moveTo(45, 25)
            ..lineTo(55, 25)
            ..lineTo(55, 42)
            ..lineTo(72, 42)
            ..lineTo(72, 52)
            ..lineTo(55, 52)
            ..lineTo(55, 74)
            ..lineTo(45, 74)
            ..lineTo(45, 52)
            ..lineTo(28, 52)
            ..lineTo(28, 42)
            ..lineTo(45, 42)
            ..close(),
          relleno,
        );
        canvas.drawCircle(const ui.Offset(50, 47), 4.5, brillo);
        break;

      case IconoHollowId.comida:
        canvas.drawRRect(
          ui.RRect.fromRectAndRadius(
            const ui.Rect.fromLTWH(43, 50, 14, 22),
            const ui.Radius.circular(4),
          ),
          relleno,
        );
        canvas.drawPath(
          ui.Path()
            ..moveTo(26, 53)
            ..quadraticBezierTo(50, 14, 74, 53)
            ..close(),
          brillo,
        );
        for (final punto in [
          const ui.Offset(40, 43),
          const ui.Offset(55, 36),
          const ui.Offset(64, 49),
        ]) {
          canvas.drawCircle(punto, 3.2, relleno);
        }
        break;

      case IconoHollowId.descanso:
        canvas.drawRRect(
          ui.RRect.fromRectAndRadius(
            const ui.Rect.fromLTWH(33, 46, 34, 30),
            const ui.Radius.circular(3),
          ),
          relleno,
        );
        canvas.drawPath(
          ui.Path()
            ..moveTo(27, 48)
            ..lineTo(50, 27)
            ..lineTo(73, 48)
            ..close(),
          brillo,
        );
        canvas.drawRRect(
          ui.RRect.fromRectAndRadius(
            const ui.Rect.fromLTWH(45, 57, 10, 19),
            const ui.Radius.circular(2),
          ),
          brillo,
        );
        break;

      case IconoHollowId.tesoro:
        canvas.drawPath(
          ui.Path()
            ..moveTo(50, 24)
            ..lineTo(74, 50)
            ..lineTo(50, 76)
            ..lineTo(26, 50)
            ..close(),
          relleno,
        );
        canvas.drawPath(
          ui.Path()
            ..moveTo(50, 35)
            ..lineTo(64, 50)
            ..lineTo(50, 65)
            ..lineTo(36, 50)
            ..close(),
          brillo,
        );
        break;

      case IconoHollowId.pocion:
        canvas.drawRRect(
          ui.RRect.fromRectAndRadius(
            const ui.Rect.fromLTWH(45, 24, 10, 18),
            const ui.Radius.circular(2),
          ),
          relleno,
        );
        canvas.drawPath(
          ui.Path()
            ..moveTo(43, 41)
            ..lineTo(57, 41)
            ..lineTo(70, 70)
            ..quadraticBezierTo(50, 80, 30, 70)
            ..close(),
          brillo,
        );
        canvas.drawLine(
          const ui.Offset(38, 63),
          const ui.Offset(62, 63),
          trazo..strokeWidth = 4,
        );
        break;

      case IconoHollowId.runa:
        canvas.drawCircle(
          const ui.Offset(50, 50),
          23,
          ui.Paint()
            ..color = relleno.color
            ..style = ui.PaintingStyle.stroke
            ..strokeWidth = 5,
        );
        final espiral = ui.Path()..moveTo(50, 50);
        for (var i = 0; i < 26; i++) {
          final angulo = i * 0.55;
          final radio = 2 + i * 0.72;
          espiral.lineTo(
            50 + radio * math.cos(angulo),
            50 + radio * math.sin(angulo),
          );
        }
        canvas.drawPath(
          espiral,
          ui.Paint()
            ..color = brillo.color
            ..style = ui.PaintingStyle.stroke
            ..strokeWidth = 4
            ..strokeCap = ui.StrokeCap.round,
        );
        break;
    }

    canvas.restore();
  }

  void _hexagono(
    ui.Canvas canvas,
    double radio,
    ui.Color color, {
    double grosor = 4,
  }) {
    final borde = ui.Paint()
      ..color = color
      ..style = ui.PaintingStyle.stroke
      ..strokeWidth = grosor
      ..strokeJoin = ui.StrokeJoin.round;
    final relleno = ui.Paint()..color = const ui.Color(0xFF0B0C13);
    final path = ui.Path();
    for (var i = 0; i < 6; i++) {
      final angulo = -math.pi / 2 + i * math.pi / 3;
      final x = 50 + radio * math.cos(angulo);
      final y = 50 + radio * math.sin(angulo);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    canvas.drawPath(path, relleno);
    canvas.drawPath(path, borde);
  }

  @override
  bool shouldRepaint(HollowIconoPainter oldDelegate) =>
      oldDelegate.icono != icono;
}

/// Versión widget, útil para leyendas y menús dentro de la app.
Widget iconoHollowWidget(IconoHollow icono, {double size = 40}) => CustomPaint(
  size: Size.square(size),
  painter: HollowIconoPainter(icono: icono),
);

/// Registra los seis símbolos en el estilo para que `icon-image` los encuentre.
Future<void> registrarIconosHollow(StyleController controller) async {
  for (final icono in iconosHollow) {
    await controller.addImageFromCanvas(
      id: icono.nombre,
      width: 128,
      height: 128,
      painter: (canvas) =>
          HollowIconoPainter(icono: icono)
              .paint(canvas, const ui.Size(128, 128)),
    );
  }
}
