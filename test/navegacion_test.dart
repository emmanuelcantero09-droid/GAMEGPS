import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:game_gps/hud_navegacion.dart';
import 'package:game_gps/rutas.dart';

void main() {
  final ruta = Ruta(
    puntos: const [
      [0.0, 0.0],
      [0.01, 0.0],
    ],
    distanciaMetros: 1000,
    duracionSegundos: 200,
    pasos: const [
      PasoRuta(
        instruccion: 'Gira a la derecha hacia Calle A',
        distanciaMetros: 400,
        tipo: 'turn',
        modifier: 'right',
        nombreCalle: 'Calle A',
        desdeInicioMetros: 400,
      ),
      PasoRuta(
        instruccion: 'Llegaste a tu destino',
        distanciaMetros: 600,
        tipo: 'arrive',
        desdeInicioMetros: 1000,
      ),
    ],
  );

  test('el progreso sigue la posición sobre la geometría de la ruta', () {
    final inicio = progresoRuta(ruta, 0, 0);
    final mitad = progresoRuta(ruta, 0, 0.005);
    final fin = progresoRuta(ruta, 0, 0.02);

    expect(inicio.recorrido, closeTo(0, 5));
    expect(mitad.recorrido, closeTo(500, 5));
    expect(mitad.restante, closeTo(500, 5));
    expect(fin.recorrido, 1000);
    expect(fin.restante, 0);
  });

  test('las maniobras pendientes son las que faltan con su distancia', () {
    final primeras = maniobrasPendientes(ruta, 0);
    expect(primeras.first.paso.modifier, 'right');
    expect(primeras.first.metros, closeTo(400, 1));

    final finales = maniobrasPendientes(ruta, 500);
    expect(finales.first.paso.esLlegada, isTrue);
    expect(finales.first.metros, closeTo(500, 1));
  });

  test('el tiempo restante usa la velocidad media de la ruta', () {
    expect(segundosRestantes(ruta, 500), closeTo(100, 1));
    expect(segundosRestantes(ruta, 1000), closeTo(200, 1));
  });

  test('rumbo, cardinal e icono de la maniobra', () {
    expect(rumboGeo(0, 0, 0, 1), closeTo(90, 0.1));
    expect(cardinal(90), 'E');
    expect(cardinal(350), 'N');
    expect(iconoManiobra(ruta.pasos.first), Icons.turn_right);
    expect(iconoManiobra(ruta.pasos.last), Icons.flag);
  });
}
