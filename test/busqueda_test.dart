import 'package:flutter_test/flutter_test.dart';
import 'package:game_gps/busqueda.dart';

void main() {
  test('convierte un resultado de Photon en un lugar', () {
    final lugar = lugarDesdeJson({
      'properties': {
        'name': 'Madrid',
        'city': 'Madrid',
        'state': 'Comunidad de Madrid',
        'country': 'España',
      },
      'geometry': {
        'type': 'Point',
        'coordinates': [-3.7035, 40.4168],
      },
    });

    expect(lugar.nombre, 'Madrid');
    expect(lugar.detalle, 'Comunidad de Madrid, España');
    expect(lugar.lat, closeTo(40.4168, 0.0001));
    expect(lugar.lon, closeTo(-3.7035, 0.0001));
  });

  test('usa la calle cuando el resultado no tiene nombre', () {
    final lugar = lugarDesdeJson({
      'properties': {'street': 'Calle Gran Vía', 'city': 'Madrid'},
      'geometry': {'coordinates': [-3.7015, 40.4200]},
    });

    expect(lugar.nombre, 'Calle Gran Vía');
    expect(lugar.detalle, 'Madrid');
  });
}
