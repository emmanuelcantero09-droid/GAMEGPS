import 'package:flutter_test/flutter_test.dart';
import 'package:game_gps/auth.dart';

void main() {
  test('Usuario.fromJson lee la respuesta del API', () {
    final usuario = Usuario.fromJson({
      'id': 4,
      'nombre': 'Emmanuel',
      'correo': 'emmanuel@gamegps.local',
      'rol': 'usuario',
      'estado': 'activo',
      'puntos': 42,
      'nivel': 'Caballero',
    });

    expect(usuario.id, 4);
    expect(usuario.nombre, 'Emmanuel');
    expect(usuario.correo, 'emmanuel@gamegps.local');
    expect(usuario.puntos, 42);
    expect(usuario.nivel, 'Caballero');
    expect(usuario.esAdmin, isFalse);
    expect(usuario.inicial, 'E');
  });

  test('Usuario.fromJson tolera campos ausentes', () {
    final usuario = Usuario.fromJson({'id': 1, 'correo': 'a@b.com'});

    expect(usuario.nombre, 'Viajero');
    expect(usuario.rol, 'usuario');
    expect(usuario.puntos, 0);
    expect(usuario.esAdmin, isFalse);
  });

  test('perfil admin y avatar con nombre vacío', () {
    final usuario = Usuario.fromJson({
      'id': 3,
      'nombre': '  ',
      'correo': 'admin@geoquest.local',
      'rol': 'admin',
    });

    expect(usuario.esAdmin, isTrue);
    expect(usuario.nombre, 'Viajero');
    expect(usuario.inicial, 'V');
  });

  test('AuthExcepcion muestra el mensaje al usuario', () {
    const error = AuthExcepcion('Correo o contraseña incorrectos');
    expect(error.toString(), 'Correo o contraseña incorrectos');
  });
}
