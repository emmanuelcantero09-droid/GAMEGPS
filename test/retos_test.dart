import 'package:flutter_test/flutter_test.dart';
import 'package:game_gps/puntos.dart';
import 'package:game_gps/retos.dart';

void main() {
  Reto reto(String id) => retos.firstWhere((r) => r.id == id);

  test('el catálogo tiene retos diarios, de distancia y de destinos', () {
    expect(retos.length, 9);
    expect(retos.where((r) => r.tipo == TipoReto.diario).length, 3);
    expect(retos.where((r) => r.tipo == TipoReto.distancia).length, 3);
    expect(retos.where((r) => r.tipo == TipoReto.destinos).length, 3);

    for (final reto in retos) {
      expect(reto.meta, greaterThan(0));
      expect(reto.puntos, greaterThan(0));
      expect(reto.id, isNotEmpty);
    }
  });

  test('caminar 500 m hoy completa el reto diario y da 20 puntos', () {
    final puntos = Puntos(ultimoDia: '2026-11-21', metrosHoy: 500);

    final resultado = evaluarRetos(puntos);

    expect(resultado.ganados, 20);
    expect(resultado.nuevos.map((r) => r.id), ['caminar500']);
    expect(resultado.puntos.saldo, 20);
    expect(resultado.puntos.entregados, ['reto:caminar500:2026-11-21']);
  });

  test('un reto diario no se paga dos veces el mismo día', () {
    final puntos = Puntos(
      ultimoDia: '2026-11-21',
      metrosHoy: 800,
      entregados: const ['reto:caminar500:2026-11-21'],
    );

    final resultado = evaluarRetos(puntos);

    expect(resultado.ganados, 0);
    expect(resultado.nuevos, isEmpty);
    expect(resultado.puntos, same(puntos));
  });

  test('un reto diario vuelve a pagarse al día siguiente', () {
    final puntos = Puntos(
      ultimoDia: '2026-11-22',
      metrosHoy: 500,
      entregados: const ['reto:caminar500:2026-11-21'],
    );

    final resultado = evaluarRetos(puntos);

    expect(resultado.ganados, 20);
    expect(resultado.puntos.entregados, contains('reto:caminar500:2026-11-22'));
  });

  test('las metas totales usan la distancia acumulada', () {
    final puntos = Puntos(ultimoDia: '2026-11-21', metrosTotales: 5000);

    final resultado = evaluarRetos(puntos);

    expect(resultado.nuevos.map((r) => r.id), ['dist1km', 'dist5km']);
    expect(resultado.ganados, 45);
    expect(resultado.puntos.entregados, ['reto:dist1km', 'reto:dist5km']);
  });

  test('los retos de destinos cuentan lugares distintos', () {
    final puntos = Puntos(
      ultimoDia: '2026-11-21',
      entregados: const ['destino:1,2', 'destino:3,4', 'destino:5,6'],
    );

    final resultado = evaluarRetos(puntos);

    expect(resultado.nuevos.map((r) => r.id), ['dest3']);
    expect(resultado.ganados, 20);
  });

  test('la racha diaria reinicia el progreso de los retos de hoy', () {
    final puntos = Puntos(
      ultimoDia: '2026-11-20',
      metrosHoy: 500,
      destinosHoy: 1,
      busquedasHoy: 3,
      racha: 1,
    );

    final nuevoDia = puntos.registrarDia(DateTime(2026, 11, 21));

    expect(nuevoDia.metrosHoy, 0);
    expect(nuevoDia.destinosHoy, 0);
    expect(nuevoDia.busquedasHoy, 0);
    expect(evaluarRetos(nuevoDia).ganados, 0);
  });

  test('el progreso se muestra con unidades legibles', () {
    final puntos = Puntos(
      ultimoDia: '2026-11-21',
      metrosHoy: 250,
      metrosTotales: 1500,
      destinosHoy: 2,
    );

    expect(reto('caminar500').progresoTexto(puntos), '250 / 500 m');
    expect(reto('dist1km').progresoTexto(puntos), '1.0 / 1 km');
    expect(reto('buscar3').progresoTexto(puntos), '0 / 3');
    expect(reto('destinoDiario').estaCompleto(puntos), isTrue);
  });
}
