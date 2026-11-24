import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'package:game_gps/hud_navegacion.dart';
import 'package:game_gps/rutas.dart';

void main() {
  final maniobras = <({PasoRuta paso, double metros})>[
    (
      paso: const PasoRuta(
        instruccion: 'Gira a la derecha hacia Calle A',
        distanciaMetros: 400,
        tipo: 'turn',
        modifier: 'right',
        nombreCalle: 'Calle A',
      ),
      metros: 400,
    ),
    (
      paso: const PasoRuta(
        instruccion: 'Llegaste a tu destino',
        distanciaMetros: 0,
        tipo: 'arrive',
      ),
      metros: 1200,
    ),
  ];

  testWidgets('el HUD muestra la maniobra, la calle y la siguiente', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: HudManiobra(
            maniobras: maniobras,
            unidades: UnidadesRuta.kilometros,
            restante: 1200,
            duracionRestante: 300,
          ),
        ),
      ),
    );

    expect(find.text('400 m'), findsOneWidget);
    expect(find.text('Calle A'), findsOneWidget);
    expect(find.textContaining('Después:'), findsOneWidget);
    expect(find.text('1.2 km · 5 min'), findsOneWidget);
    expect(find.byIcon(Icons.turn_right), findsWidgets);
    expect(find.byIcon(Icons.flag), findsWidgets);
  });

  testWidgets('el resumen muestra velocidad, rumbo, llegada y progreso', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: HudResumen(
            velocidadKmh: 42,
            rumbo: 90,
            progreso: 0.5,
            llegada: DateTime(2026, 11, 23, 18, 45),
            onDetener: () {},
            onReencuadrar: () {},
          ),
        ),
      ),
    );

    expect(find.text('42'), findsOneWidget);
    expect(find.text('E'), findsOneWidget);
    expect(find.text('18:45'), findsOneWidget);
    expect(find.byIcon(Icons.speed), findsOneWidget);
    expect(find.byType(LinearProgressIndicator), findsOneWidget);
  });

  testWidgets('el resumen detalla lo que falta y el porcentaje', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: HudResumen(
            velocidadKmh: 42,
            rumbo: 90,
            progreso: 0.5,
            restanteMetros: 1200,
            segundosRestantes: 300,
            llegada: DateTime(2026, 11, 23, 18, 45),
            onDetener: () {},
            onReencuadrar: () {},
          ),
        ),
      ),
    );

    expect(find.textContaining('Faltan 1.2 km'), findsOneWidget);
    expect(find.textContaining('5 min'), findsOneWidget);
    expect(find.textContaining('50%'), findsOneWidget);
    expect(find.byIcon(Icons.route), findsOneWidget);
  });

  test('la maniobra usa un anillo de proximidad', () {
    expect(iconoManiobra(maniobras.first.paso), Icons.turn_right);
    expect(cardinal(90), 'E');
  });
}
