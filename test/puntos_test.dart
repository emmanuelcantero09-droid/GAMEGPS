import 'package:flutter_test/flutter_test.dart';
import 'package:game_gps/puntos.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('un punto por cada 100 metros y conserva el sobrante', () {
    var puntos = const Puntos();

    puntos = puntos.sumarDistancia(60);
    expect(puntos.saldo, 0);
    expect(puntos.metrosPendientes, 60);

    puntos = puntos.sumarDistancia(60);
    expect(puntos.saldo, 1);
    expect(puntos.metrosPendientes, closeTo(20, 0.0001));
  });

  test('ignora distancias negativas o nulas', () {
    const puntos = Puntos(saldo: 3, metrosPendientes: 10);

    expect(puntos.sumarDistancia(-5), same(puntos));
    expect(puntos.sumarDistancia(0), same(puntos));
  });

  test('comprar resta puntos y no permite saldo negativo', () {
    const puntos = Puntos(saldo: 100);

    expect(puntos.gastar(80).saldo, 20);
    expect(puntos.gastar(120), same(puntos));
    expect(puntos.gastar(-5), same(puntos));
  });

  test('la llegada al destino solo puntúa una vez', () {
    const puntos = Puntos(saldo: 2);

    final primera = puntos.registrarLlegada('40.4168,-3.7038');
    final segunda = primera.registrarLlegada('40.4168,-3.7038');

    expect(primera.saldo, 17);
    expect(segunda.saldo, 17);
    expect(segunda.entregados, ['destino:40.4168,-3.7038']);
  });

  test('el mismo día no vuelve a dar puntos de racha', () {
    final puntos = Puntos(saldo: 10, racha: 3, ultimoDia: '2026-11-21');

    expect(puntos.registrarDia(DateTime(2026, 11, 21, 15)).saldo, 10);
  });

  test('un dia seguido suma racha y puntos; un salto la reinicia', () {
    final puntos = Puntos(saldo: 10, racha: 3, ultimoDia: '2026-11-20');

    final seguido = puntos.registrarDia(DateTime(2026, 11, 21));
    expect(seguido.saldo, 15);
    expect(seguido.racha, 4);

    final saltado = puntos.registrarDia(DateTime(2026, 11, 25));
    expect(saltado.saldo, 15);
    expect(saltado.racha, 1);
  });

  test('el séptimo dia consecutivo da un bonus extra una sola vez', () {
    final puntos = Puntos(saldo: 0, racha: 6, ultimoDia: '2026-11-20');

    final diaSiete = puntos.registrarDia(DateTime(2026, 11, 21));
    expect(diaSiete.saldo, 10);
    expect(diaSiete.entregados, contains('racha:7'));

    final repetido = Puntos(
      saldo: 0,
      racha: 7,
      ultimoDia: '2026-11-20',
      entregados: const ['racha:7'],
    ).registrarDia(DateTime(2026, 11, 21));
    expect(repetido.saldo, 5);
  });

  test('los puntos se conservan al guardar y cargar', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final original = Puntos(
      saldo: 42,
      metrosPendientes: 35.5,
      racha: 4,
      ultimoDia: '2026-11-21',
      entregados: const ['destino:1,2'],
    );

    await original.guardar(prefs);
    final cargado = Puntos.cargar(prefs);

    expect(cargado.saldo, 42);
    expect(cargado.metrosPendientes, 35.5);
    expect(cargado.racha, 4);
    expect(cargado.ultimoDia, '2026-11-21');
    expect(cargado.entregados, ['destino:1,2']);
  });
}
