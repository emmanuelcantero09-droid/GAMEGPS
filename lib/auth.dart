/// Acceso a la base de datos GAME GPS a través del API local (`database/api.py`).
library;

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

const String _claveUrlApi = 'api_base_url';
const String urlApiPorDefecto = 'http://127.0.0.1:8000';

/// Usuario devuelto por el API (tabla `interfaz_auth` de geoquest.db).
class Usuario {
  const Usuario({
    required this.id,
    required this.nombre,
    required this.correo,
    this.rol = 'usuario',
    this.estado = 'activo',
    this.puntos = 0,
    this.nivel = 'Errante',
  });

  factory Usuario.fromJson(Map<dynamic, dynamic> json) {
    return Usuario(
      id: (json['id'] as num?)?.toInt() ?? 0,
      nombre: (json['nombre'] as String?)?.trim().isNotEmpty == true
          ? json['nombre'] as String
          : 'Viajero',
      correo: (json['correo'] as String?) ?? '',
      rol: (json['rol'] as String?) ?? 'usuario',
      estado: (json['estado'] as String?) ?? 'activo',
      puntos: (json['puntos'] as num?)?.toInt() ?? 0,
      nivel: (json['nivel'] as String?) ?? 'Errante',
    );
  }

  final int id;
  final String nombre;
  final String correo;
  final String rol;
  final String estado;
  final int puntos;
  final String nivel;

  bool get esAdmin => rol == 'admin';

  /// Inicial que se muestra en el avatar compacto del mapa.
  String get inicial {
    final nombreLimpio = nombre.trim();
    return nombreLimpio.isEmpty ? 'G' : nombreLimpio[0].toUpperCase();
  }
}

/// Error usable directamente en la interfaz (mensaje en español).
class AuthExcepcion implements Exception {
  const AuthExcepcion(this.mensaje);

  final String mensaje;

  @override
  String toString() => mensaje;
}

/// Cliente del API de acceso. No guarda contraseñas en el dispositivo.
class AuthServicio {
  AuthServicio({required this.urlBase, http.Client? cliente})
    : _cliente = cliente ?? http.Client();

  final String urlBase;
  final http.Client _cliente;

  /// Dirección recordada del servidor. Por defecto, el puerto local del API.
  static Future<String> leerUrlBase() async {
    final prefs = await SharedPreferences.getInstance();
    return _normalizarUrl(prefs.getString(_claveUrlApi) ?? urlApiPorDefecto);
  }

  static Future<void> guardarUrlBase(String url) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_claveUrlApi, _normalizarUrl(url));
  }

  /// Recuerda el último correo para que el login sea más cómodo.
  static Future<void> guardarUltimoCorreo(String correo) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('ultimo_correo', correo.trim().toLowerCase());
  }

  static Future<String> leerUltimoCorreo() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('ultimo_correo') ?? '';
  }

  /// Guarda la cuenta ya verificada para no pedirla en cada arranque.
  /// Nunca se guarda la contraseña.
  static Future<void> guardarSesion(Usuario usuario) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'sesion_usuario',
      jsonEncode(<String, Object?>{
        'id': usuario.id,
        'nombre': usuario.nombre,
        'correo': usuario.correo,
        'rol': usuario.rol,
        'estado': usuario.estado,
        'puntos': usuario.puntos,
        'nivel': usuario.nivel,
      }),
    );
  }

  static Future<Usuario?> leerSesion() async {
    final prefs = await SharedPreferences.getInstance();
    final texto = prefs.getString('sesion_usuario');
    if (texto == null || texto.isEmpty) return null;
    try {
      final decodificado = jsonDecode(texto);
      if (decodificado is Map) return Usuario.fromJson(decodificado);
    } on FormatException {
      return null;
    }
    return null;
  }

  static Future<void> cerrarSesion() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('sesion_usuario');
  }

  Future<Usuario> entrar({required String correo, required String contrasena}) {
    return _accion('login', {
      'correo': correo.trim().toLowerCase(),
      'contrasena': contrasena,
    });
  }

  Future<Usuario> registrar({
    required String nombre,
    required String correo,
    required String contrasena,
  }) {
    return _accion('registro', {
      'nombre': nombre.trim(),
      'correo': correo.trim().toLowerCase(),
      'contrasena': contrasena,
    });
  }

  Future<Usuario> _accion(String accion, Map<String, dynamic> datos) async {
    final uri = Uri.parse('$urlBase/api/accion');
    late final http.Response respuesta;
    try {
      respuesta = await _cliente
          .post(
            uri,
            headers: const {'Content-Type': 'application/json; charset=utf-8'},
            body: jsonEncode({'accion': accion, ...datos}),
          )
          .timeout(const Duration(seconds: 10));
    } on SocketException {
      throw const AuthExcepcion(
        'No se pudo conectar con el servidor de cuentas. '
        'Revisa la dirección del servidor e inténtalo de nuevo.',
      );
    } on TimeoutException {
      throw const AuthExcepcion(
        'El servidor tardó demasiado en responder. Inténtalo de nuevo.',
      );
    } on http.ClientException {
      throw const AuthExcepcion(
        'No se pudo contactar al servidor. Revisa la dirección configurada.',
      );
    }

    if (respuesta.statusCode != 200) {
      throw AuthExcepcion(
        'El servidor respondió con error ${respuesta.statusCode}.',
      );
    }

    final dynamic decodificado;
    try {
      decodificado = jsonDecode(respuesta.body);
    } on FormatException {
      throw const AuthExcepcion('El servidor devolvió una respuesta inválida.');
    }
    if (decodificado is! Map) {
      throw const AuthExcepcion('El servidor devolvió una respuesta inválida.');
    }
    final Map cuerpo = decodificado;
    if (cuerpo['ok'] != true) {
      throw AuthExcepcion(
        cuerpo['mensaje']?.toString() ?? 'No se pudo completar la operación.',
      );
    }
    final usuario = cuerpo['usuario'];
    if (usuario is! Map) {
      throw const AuthExcepcion(
        'El servidor no devolvió los datos de la cuenta.',
      );
    }
    return Usuario.fromJson(usuario);
  }

  void dispose() => _cliente.close();

  static String _normalizarUrl(String valor) {
    var url = valor.trim();
    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      url = 'http://$url';
    }
    while (url.endsWith('/')) {
      url = url.substring(0, url.length - 1);
    }
    return url;
  }
}
