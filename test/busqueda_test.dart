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

  test('la consulta no envía un idioma que Photon no acepta', () {
    final uri = uriBusqueda('  Madrid  ');

    expect(uri.host, 'photon.komoot.io');
    expect(uri.queryParameters['q'], 'Madrid');
    expect(uri.queryParameters['limit'], '5');
    expect(uri.queryParameters.containsKey('lang'), isFalse);
  });

  test('la consulta sesga los resultados hacia mi ubicación', () {
    final uri = uriBusqueda('parque', lat: 40.4168, lon: -3.7038);

    expect(uri.queryParameters['lat'], '40.416800');
    expect(uri.queryParameters['lon'], '-3.703800');
    expect(uri.queryParameters.containsKey('lang'), isFalse);
  });

  test('sin ubicación no envía lat ni lon', () {
    final uri = uriBusqueda('parque');

    expect(uri.queryParameters.containsKey('lat'), isFalse);
    expect(uri.queryParameters.containsKey('lon'), isFalse);
  });

  test('usa la calle cuando el resultado no tiene nombre', () {
    final lugar = lugarDesdeJson({
      'properties': {'street': 'Calle Gran Vía', 'city': 'Madrid'},
      'geometry': {
        'coordinates': [-3.7015, 40.4200],
      },
    });

    expect(lugar.nombre, 'Calle Gran Vía');
    expect(lugar.detalle, 'Madrid');
  });
}
