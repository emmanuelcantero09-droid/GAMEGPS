/// Tienda de skins: diseños de licencia libre que se compran con puntos.
library;

import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'skins.dart';

/// Un skin que se puede comprar con puntos.
class SkinTienda {
  const SkinTienda({
    required this.id,
    required this.nombre,
    required this.descripcion,
    required this.asset,
    required this.color,
    required this.precio,
  });

  final String id;
  final String nombre;
  final String descripcion;
  final String asset;
  final Color color;
  final int precio;

  /// Skin listo para usar en el inventario del marcador.
  Skin get skin => Skin(
    id: id,
    nombre: nombre,
    descripcion: descripcion,
    asset: asset,
    color: color,
  );
}

/// Iconos de game-icons.net, licencia CC BY 3.0. Créditos en README.md.
const List<SkinTienda> tiendaSkins = [
  SkinTienda(
    id: 'dragon',
    nombre: 'Dragón',
    descripcion: 'Cabeza de dragón roja',
    asset: 'assets/tienda/dragon-head.png',
    color: Color(0xFFFF3D71),
    precio: 80,
  ),
  SkinTienda(
    id: 'androide',
    nombre: 'Androide clásico',
    descripcion: 'Robot vintage verde',
    asset: 'assets/tienda/vintage-robot.png',
    color: Color(0xFF00FFA3),
    precio: 90,
  ),
  SkinTienda(
    id: 'ninja',
    nombre: 'Ninja',
    descripcion: 'Guerrero enmascarado cian',
    asset: 'assets/tienda/ninja-head.png',
    color: Color(0xFF00E5FF),
    precio: 100,
  ),
  SkinTienda(
    id: 'medusa',
    nombre: 'Medusa',
    descripcion: 'Mirada morada',
    asset: 'assets/tienda/medusa-head.png',
    color: Color(0xFFB06BFF),
    precio: 120,
  ),
  SkinTienda(
    id: 'astronauta',
    nombre: 'Astronauta',
    descripcion: 'Traje espacial blanco',
    asset: 'assets/tienda/space-suit.png',
    color: Color(0xFFFFFFFF),
    precio: 130,
  ),
  SkinTienda(
    id: 'rey',
    nombre: 'Rey',
    descripcion: 'Corona dorada',
    asset: 'assets/tienda/old-king.png',
    color: Color(0xFFFFD54F),
    precio: 150,
  ),
  SkinTienda(
    id: 'mecha',
    nombre: 'Mecha',
    descripcion: 'Robot de batalla naranja',
    asset: 'assets/tienda/battle-mech.png',
    color: Color(0xFFFF8A3D),
    precio: 200,
  ),
  SkinTienda(
    id: 'cohete',
    nombre: 'Cohete',
    descripcion: 'Mochila propulsora azul',
    asset: 'assets/tienda/jet-pack.png',
    color: Color(0xFF26A8FF),
    precio: 250,
  ),
];

/// Guarda los identificadores de los skins ya comprados.
class InventarioTienda {
  static const String clave = 'skins_comprados';

  static List<String> cargar(SharedPreferences prefs) =>
      prefs.getStringList(clave) ?? const [];

  static Future<void> guardar(SharedPreferences prefs, List<String> ids) =>
      prefs.setStringList(clave, ids);
}
