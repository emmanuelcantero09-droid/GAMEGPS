import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:game_gps/main.dart';
import 'package:game_gps/mapa_local.dart';
import 'package:game_gps/mapas.dart';

void main() {
  test('todos los estilos son documentos MapLibre válidos', () {
    final estilos = <String>[
      MapaLocal.style,
      ...proveedoresMapa.where((p) => p.style != null).map((p) => p.style!),
    ];

    for (final texto in estilos) {
      final estilo = jsonDecode(texto) as Map<String, dynamic>;
      expect(estilo['version'], 8);
      expect(estilo['sources'], isA<Map<String, dynamic>>());
      expect(estilo['layers'], isA<List<dynamic>>());
    }
  });

  test('ninguna fuente de mapa usa Google Maps', () {
    for (final proveedor in proveedoresMapa) {
      final estilo = proveedor.style ?? '';
      expect(estilo.toLowerCase().contains('google'), isFalse);
    }
  });

  test('la versión de la interfaz coincide con pubspec.yaml', () {
    final pubspec = File('pubspec.yaml').readAsStringSync();
    expect(GameGpsApp.version, '0.1.0');
    expect(pubspec, contains('version: ${GameGpsApp.version}+1'));
  });
}
