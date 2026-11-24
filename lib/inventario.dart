/// Inventario de diseños propios: imágenes que el usuario elige desde su galería.
library;

import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Un diseño creado por el usuario.
class DisenoPropio {
  const DisenoPropio({
    required this.id,
    required this.nombre,
    required this.rutaImagen,
  });

  factory DisenoPropio.fromJson(Map<String, dynamic> json) {
    return DisenoPropio(
      id: json['id'] as String,
      nombre: json['nombre'] as String,
      rutaImagen: json['rutaImagen'] as String,
    );
  }

  final String id;
  final String nombre;
  final String rutaImagen;

  Map<String, dynamic> toJson() => {
    'id': id,
    'nombre': nombre,
    'rutaImagen': rutaImagen,
  };
}

/// Guarda y lee la lista de diseños propios en las preferencias de la app.
class InventarioDisenos {
  static const String clave = 'disenos_propios';

  /// Devuelve una lista vacía si no hay datos o si el guardado se corrompió.
  static List<DisenoPropio> leer(SharedPreferences prefs) {
    final texto = prefs.getString(clave);
    if (texto == null) return const <DisenoPropio>[];
    try {
      final datos = jsonDecode(texto) as List<dynamic>;
      return datos
          .whereType<Map<String, dynamic>>()
          .map(DisenoPropio.fromJson)
          .toList(growable: false);
    } catch (_) {
      return const <DisenoPropio>[];
    }
  }

  static Future<void> guardar(
    SharedPreferences prefs,
    List<DisenoPropio> disenos,
  ) {
    return prefs.setString(
      clave,
      jsonEncode(disenos.map((d) => d.toJson()).toList()),
    );
  }
}
