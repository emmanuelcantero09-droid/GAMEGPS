import 'package:flutter_test/flutter_test.dart';
import 'package:game_gps/rutas.dart';

Map<String, dynamic> respuestaEjemplo() => {
  'code': 'Ok',
  'routes': [
    {
      'distance': 1520.4,
      'duration': 480.0,
      'geometry': {
        'type': 'LineString',
        'coordinates': [
          [-3.7038, 40.4168],
          [-3.7010, 40.4180],
          [-3.6833, 40.4149],
        ],
      },
      'legs': [
        {
          'steps': [
            {
              'distance': 120.5,
              'name': 'Calle de Alcalá',
              'maneuver': {'type': 'depart', 'bearing_after': 90},
            },
            {
              'distance': 300.0,
              'name': 'Gran Vía',
              'maneuver': {'type': 'turn', 'modifier': 'right'},
            },
            {
              'distance': 0.0,
              'name': '',
              'maneuver': {'type': 'arrive'},
            },
          ],
        },
      ],
    },
  ],
};

void main() {
  test('la URL usa el servidor correcto según el modo', () {
    final coche = uriRuta(
      lonOrigen: -3.7038,
      latOrigen: 40.4168,
      lonDestino: -3.6833,
      latDestino: 40.4149,
      modo: ModoRuta.coche,
    );
    final pie = uriRuta(
      lonOrigen: -3.7038,
      latOrigen: 40.4168,
      lonDestino: -3.6833,
      latDestino: 40.4149,
      modo: ModoRuta.aPie,
    );

    expect(coche.host, 'router.project-osrm.org');
    expect(pie.host, 'routing.openstreetmap.de');
    expect(pie.path, contains('/routed-foot/'));
    expect(coche.queryParameters['overview'], 'full');
    expect(coche.queryParameters['steps'], 'true');
    expect(coche.path, contains('40.416800'));
  });

  test('convierte una respuesta de OSRM en una ruta', () {
    final ruta = rutaDesdeJson(respuestaEjemplo());

    expect(ruta.puntos.length, 3);
    expect(ruta.puntos.first, [-3.7038, 40.4168]);
    expect(ruta.distanciaMetros, closeTo(1520.4, 0.01));
    expect(ruta.duracionSegundos, closeTo(480, 0.01));
    expect(ruta.pasos.length, 3);
    expect(ruta.pasos[0].instruccion, 'Sal hacia Calle de Alcalá');
    expect(ruta.pasos[1].instruccion, 'Gira a la derecha hacia Gran Vía');
    expect(ruta.pasos[2].instruccion, 'Llegaste a tu destino');
  });

  test('acepta maniobras con location [lon, lat] de OSRM geojson', () {
    final datos = respuestaEjemplo();
    final paso = (datos['routes'][0]['legs'][0]['steps'] as List<dynamic>)[1]
        as Map<String, dynamic>;
    final maniobra = Map<String, dynamic>.from(paso['maneuver'] as Map);
    maniobra['location'] = [-3.7010, 40.4180];
    paso['maneuver'] = maniobra;

    final ruta = rutaDesdeJson(datos);
    expect(ruta.pasos[1].lon, closeTo(-3.7010, 0.0001));
    expect(ruta.pasos[1].lat, closeTo(40.4180, 0.0001));
  });

  test('las instrucciones pueden salir en inglés', () {
    final ruta = rutaDesdeJson(
      respuestaEjemplo(),
      idioma: IdiomaInstrucciones.en,
    );

    expect(ruta.pasos[1].instruccion, 'Turn right onto Gran Vía');
    expect(ruta.pasos[2].instruccion, 'You have arrived');
  });

  test('formatea distancias y duraciones', () {
    expect(formatoDistancia(350, UnidadesRuta.metros), '350 m');
    expect(formatoDistancia(2400, UnidadesRuta.metros), '2400 m');
    expect(formatoDistancia(2400, UnidadesRuta.kilometros), '2.4 km');
    expect(formatoDuracion(480, IdiomaInstrucciones.es), '8 min');
    expect(formatoDuracion(3900, IdiomaInstrucciones.es), '1 h 5 min');
  });

  test('avisa si el servicio devuelve un error', () {
    expect(
      () => rutaDesdeJson({'code': 'NoRoute'}),
      throwsA(isA<RutaException>()),
    );
  });

  test('calcula el centro y el zoom para encuadrar la ruta', () {
    final ruta = rutaDesdeJson(respuestaEjemplo());
    final centro = centroRuta(ruta);

    expect(centro.lon, closeTo(-3.69355, 0.0001));
    expect(centro.lat, closeTo(40.41645, 0.0001));
    expect(zoomParaRuta(ruta), greaterThan(12));
    expect(zoomParaRuta(ruta), lessThan(16));
  });

  test('una ruta muy larga se ve con menos zoom', () {
    final corta = rutaDesdeJson(respuestaEjemplo());
    final larga = Ruta(
      puntos: const [
        [-3.70, 40.41],
        [2.10, 41.40],
      ],
      distanciaMetros: 500000,
      duracionSegundos: 18000,
      pasos: const [],
    );

    expect(zoomParaRuta(larga), lessThan(zoomParaRuta(corta)));
    expect(zoomParaRuta(larga), greaterThanOrEqualTo(9));
  });

  test('las opciones se copian cambiando solo un valor', () {
    const opciones = OpcionesRuta();
    final cambiadas = opciones.copyWith(modo: ModoRuta.bici, color: 0xFFFF3D71);

    expect(opciones.modo, ModoRuta.coche);
    expect(cambiadas.modo, ModoRuta.bici);
    expect(cambiadas.color, 0xFFFF3D71);
    expect(cambiadas.idioma, IdiomaInstrucciones.es);
    expect(cambiadas.grosor, 5);
  });
}
