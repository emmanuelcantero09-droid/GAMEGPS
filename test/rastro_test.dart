import 'package:flutter_test/flutter_test.dart';
import 'package:game_gps/capa_ruta.dart';

void main() {
  test('el rastro no se dibuja con menos de dos puntos', () {
    expect(capasRastro(const []), isEmpty);
    expect(
      capasRastro([
        [-3.7038, 40.4168],
      ]),
      isEmpty,
    );
  });

  test('el rastro dibuja un halo y una línea cian', () {
    final capas = capasRastro([
      [-3.7038, 40.4168],
      [-3.7040, 40.4170],
      [-3.7042, 40.4172],
    ]);

    expect(capas.length, 2);
  });
}
