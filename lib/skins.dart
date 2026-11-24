import 'dart:io';

import 'package:material_ui/material_ui.dart';

/// Identificadores de los skins incluidos en la app.
enum SkinId { clasico, caballero, robot, compas, nave, explorador }

/// Un skin del marcador: nombre, descripción y constructor del widget.
///
/// Si [rutaImagen] no es nulo, el marcador usa esa imagen del inventario
/// en vez de uno de los dibujos incluidos.
class Skin {
  const Skin({
    required this.id,
    required this.nombre,
    required this.descripcion,
    this.rutaImagen,
    this.asset,
    this.color,
  });

  final String id;
  final String nombre;
  final String descripcion;
  final String? rutaImagen;
  final String? asset;
  final Color? color;

  bool get esPropio => rutaImagen != null;

  Widget build({required bool seleccionado}) {
    final imagenAsset = asset;
    if (imagenAsset != null) {
      return ClipOval(
        child: ColorFiltered(
          colorFilter: ColorFilter.mode(
            color ?? const Color(0xFF00E5FF),
            BlendMode.srcIn,
          ),
          child: Image.asset(
            imagenAsset,
            width: 56,
            height: 56,
            fit: BoxFit.cover,
          ),
        ),
      );
    }
    final ruta = rutaImagen;
    if (ruta != null) {
      return ClipOval(
        child: Image.file(
          File(ruta),
          width: 56,
          height: 56,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => const Icon(
            Icons.image_not_supported,
            color: Color(0xFF00E5FF),
            size: 40,
          ),
        ),
      );
    }
    final tipo =
        SkinId.values.where((e) => e.name == id).firstOrNull ?? SkinId.clasico;
    return CustomPaint(
      size: const Size(56, 56),
      painter: _SkinPainter(id: tipo, seleccionado: seleccionado),
    );
  }
}

/// Catálogo completo. Todos son diseños originales.
const List<Skin> skins = [
  Skin(id: 'clasico', nombre: 'Clásico', descripcion: 'Punto GPS con pulso'),
  Skin(
    id: 'caballero',
    nombre: 'Caballero Neo',
    descripcion: 'Guerrero enmascarado',
  ),
  Skin(id: 'robot', nombre: 'Sonda Rover', descripcion: 'Robot explorador'),
  Skin(id: 'compas', nombre: 'Brújula', descripcion: 'Aguja de navegación'),
  Skin(id: 'nave', nombre: 'Nave', descripcion: 'Nave espacial'),
  Skin(id: 'explorador', nombre: 'Explorador', descripcion: 'Tigre nocturno'),
];

const Color _cyan = Color(0xFF00E5FF);
const Color _violeta = Color(0xFF7B2BFF);
const Color _oscuro = Color(0xFF05070F);
const Color _panel = Color(0xFF10182B);

class _SkinPainter extends CustomPainter {
  const _SkinPainter({required this.id, required this.seleccionado});

  final SkinId id;
  final bool seleccionado;

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final s = size.width / 56;

    canvas.save();
    canvas.scale(s);

    // Halo común: más intenso cuando el skin está seleccionado.
    final halo = Paint()
      ..color = _cyan.withValues(alpha: seleccionado ? 0.30 : 0.14)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(c, 25, halo);

    final borde = Paint()
      ..color = _cyan
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final relleno = Paint()
      ..color = _panel
      ..style = PaintingStyle.fill;

    switch (id) {
      case SkinId.clasico:
        canvas.drawCircle(
          c,
          19,
          Paint()..color = _cyan.withValues(alpha: 0.22),
        );
        canvas.drawCircle(c, 13, Paint()..color = _cyan);
        canvas.drawCircle(c, 6, Paint()..color = _oscuro);
        canvas.drawCircle(c, 2.5, Paint()..color = _cyan);
        canvas.drawCircle(c, 21, borde..style = PaintingStyle.stroke);
        break;

      case SkinId.caballero:
        // Capa
        final capa = Path()
          ..moveTo(18, 42)
          ..lineTo(38, 42)
          ..lineTo(34, 25)
          ..lineTo(22, 25)
          ..close();
        canvas.drawPath(capa, Paint()..color = const Color(0xFF14224A));
        // Antenas del casco (originales, no copian a ningún personaje conocido)
        final antena = Paint()
          ..color = _cyan
          ..strokeWidth = 2.5
          ..strokeCap = StrokeCap.round;
        canvas.drawLine(const Offset(23, 17), const Offset(21, 8), antena);
        canvas.drawLine(const Offset(33, 17), const Offset(35, 8), antena);
        // Casco
        final casco = Path()
          ..moveTo(19, 20)
          ..quadraticBezierTo(28, 11, 37, 20)
          ..lineTo(35, 29)
          ..quadraticBezierTo(28, 34, 21, 29)
          ..close();
        canvas.drawPath(casco, relleno);
        canvas.drawPath(casco, borde);
        // Visor
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            const Rect.fromLTWH(22, 21, 12, 4),
            const Radius.circular(2),
          ),
          Paint()..color = _cyan,
        );
        // Botas
        canvas.drawRect(
          const Rect.fromLTWH(22, 42, 5, 5),
          Paint()..color = _oscuro,
        );
        canvas.drawRect(
          const Rect.fromLTWH(30, 42, 5, 5),
          Paint()..color = _oscuro,
        );
        break;

      case SkinId.robot:
        // Orugas
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            const Rect.fromLTWH(12, 39, 11, 8),
            const Radius.circular(4),
          ),
          Paint()..color = _violeta,
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            const Rect.fromLTWH(33, 39, 11, 8),
            const Radius.circular(4),
          ),
          Paint()..color = _violeta,
        );
        // Cuerpo
        final cuerpo = RRect.fromRectAndRadius(
          const Rect.fromLTWH(16, 16, 24, 24),
          const Radius.circular(8),
        );
        canvas.drawRRect(cuerpo, relleno);
        canvas.drawRRect(cuerpo, borde);
        // Antena
        final antena = Paint()
          ..color = _cyan
          ..strokeWidth = 2;
        canvas.drawLine(const Offset(28, 16), const Offset(28, 7), antena);
        canvas.drawCircle(const Offset(28, 6), 3, Paint()..color = _cyan);
        // Ojo
        canvas.drawCircle(
          const Offset(28, 27),
          7,
          Paint()..color = _cyan.withValues(alpha: 0.25),
        );
        canvas.drawCircle(const Offset(28, 27), 4, Paint()..color = _cyan);
        canvas.drawCircle(const Offset(28, 27), 1.5, Paint()..color = _oscuro);
        break;

      case SkinId.compas:
        canvas.drawCircle(c, 21, Paint()..color = _panel);
        canvas.drawCircle(c, 21, borde);
        final aguja = Path()
          ..moveTo(28, 12)
          ..lineTo(33, 30)
          ..lineTo(28, 26)
          ..lineTo(23, 30)
          ..close();
        canvas.drawPath(aguja, Paint()..color = _cyan);
        final sur = Path()
          ..moveTo(28, 44)
          ..lineTo(33, 30)
          ..lineTo(28, 26)
          ..lineTo(23, 30)
          ..close();
        canvas.drawPath(sur, Paint()..color = _violeta.withValues(alpha: 0.8));
        canvas.drawCircle(const Offset(28, 28), 3, Paint()..color = _oscuro);
        canvas.drawCircle(
          c,
          25,
          Paint()..color = _cyan.withValues(alpha: 0.18),
        );
        break;

      case SkinId.nave:
        final alas = Path()
          ..moveTo(28, 8)
          ..lineTo(42, 40)
          ..lineTo(28, 33)
          ..lineTo(14, 40)
          ..close();
        canvas.drawPath(alas, Paint()..color = _violeta);
        final cuerpo = Path()
          ..moveTo(28, 10)
          ..lineTo(36, 35)
          ..lineTo(28, 30)
          ..lineTo(20, 35)
          ..close();
        canvas.drawPath(cuerpo, Paint()..color = _panel);
        canvas.drawPath(cuerpo, borde);
        canvas.drawCircle(const Offset(28, 23), 4, Paint()..color = _cyan);
        canvas.drawCircle(const Offset(22, 40), 2.5, Paint()..color = _cyan);
        canvas.drawCircle(const Offset(34, 40), 2.5, Paint()..color = _cyan);
        break;

      case SkinId.explorador:
        final capucha = Path()
          ..moveTo(28, 9)
          ..lineTo(41, 43)
          ..lineTo(28, 35)
          ..lineTo(15, 43)
          ..close();
        canvas.drawPath(capucha, Paint()..color = _panel);
        canvas.drawPath(capucha, borde);
        canvas.drawCircle(const Offset(23, 27), 3, Paint()..color = _cyan);
        canvas.drawCircle(const Offset(33, 27), 3, Paint()..color = _cyan);
        canvas.drawCircle(const Offset(23, 27), 1.2, Paint()..color = _oscuro);
        canvas.drawCircle(const Offset(33, 27), 1.2, Paint()..color = _oscuro);
        break;
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _SkinPainter oldDelegate) =>
      oldDelegate.id != id || oldDelegate.seleccionado != seleccionado;
}
