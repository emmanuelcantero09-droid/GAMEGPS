import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';
import 'package:game_gps/iconos_hollow.dart';

void main() {
  test('los seis símbolos propios tienen id estable para MapLibre', () {
    expect(iconosHollow.map((i) => i.nombre), [
      'hollow_hospital',
      'hollow_comida',
      'hollow_descanso',
      'hollow_tesoro',
      'hollow_pocion',
      'hollow_runa',
    ]);
    expect(iconosHollow.map((i) => i.etiqueta), contains('Sanctuario'));
  });

  test('cada símbolo se dibuja sin errores', () {
    for (final icono in iconosHollow) {
      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder);
      HollowIconoPainter(icono: icono).paint(canvas, const ui.Size(128, 128));
      expect(recorder.endRecording(), isNotNull, reason: icono.etiqueta);
    }
  });
}
