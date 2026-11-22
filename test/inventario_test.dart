import 'package:flutter_test/flutter_test.dart';
import 'package:game_gps/inventario.dart';
import 'package:game_gps/skins.dart';

void main() {
  test('un diseño propio conserva sus datos al guardarlo y leerlo', () {
    final original = DisenoPropio(
      id: 'propio_123',
      nombre: 'Diseño 1',
      rutaImagen: '/tmp/diseno.jpg',
    );

    final restaurado = DisenoPropio.fromJson(original.toJson());

    expect(restaurado.id, original.id);
    expect(restaurado.nombre, original.nombre);
    expect(restaurado.rutaImagen, original.rutaImagen);
  });

  test('los skins incluidos siguen siendo los seis originales', () {
    expect(skins.map((s) => s.id), [
      'clasico',
      'caballero',
      'robot',
      'compas',
      'nave',
      'explorador',
    ]);
    expect(skins.any((s) => s.esPropio), isFalse);
  });
}
