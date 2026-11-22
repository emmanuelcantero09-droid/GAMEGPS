import 'package:flutter_test/flutter_test.dart';
import 'package:game_gps/tienda.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('el catálogo tiene skins con precio y asset propio', () {
    expect(tiendaSkins.length, 8);

    for (final articulo in tiendaSkins) {
      expect(articulo.id, isNotEmpty);
      expect(articulo.precio, greaterThan(0));
      expect(articulo.asset, startsWith('assets/tienda/'));
      expect(articulo.asset, endsWith('.png'));
    }
  });

  test('un articulo de la tienda se convierte en skin del inventario', () {
    final articulo = tiendaSkins.first;
    final skin = articulo.skin;

    expect(skin.id, articulo.id);
    expect(skin.nombre, articulo.nombre);
    expect(skin.asset, articulo.asset);
    expect(skin.color, articulo.color);
    expect(skin.esPropio, isFalse);
  });

  test('las compras se conservan al guardar y cargar', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    await InventarioTienda.guardar(prefs, const ['dragon', 'ninja']);

    expect(InventarioTienda.cargar(prefs), ['dragon', 'ninja']);
  });

  test('sin compras previas el inventario está vacío', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    expect(InventarioTienda.cargar(prefs), isEmpty);
  });
}
