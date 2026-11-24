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

  test('ningún estilo mezcla propiedades de pintura en layout', () {
    // MapLibre rechaza el documento completo si, por ejemplo, text-halo-color
    // aparece en layout. Eso dejaba el mapa en blanco.
    const soloPintura = <String>{
      'text-color',
      'text-halo-color',
      'text-halo-width',
      'text-halo-blur',
      'line-color',
      'line-width',
      'fill-color',
      'fill-opacity',
      'raster-opacity',
      'background-color',
      'background-opacity',
    };
    for (final proveedor in proveedoresMapa) {
      final texto = proveedor.style;
      if (texto == null) continue;
      final estilo = jsonDecode(texto) as Map<String, dynamic>;
      for (final capa in (estilo['layers'] as List<dynamic>).cast<Map>()) {
        final layout = capa['layout'];
        if (layout is! Map) continue;
        for (final clave in layout.keys) {
          expect(
            soloPintura.contains(clave.toString()),
            isFalse,
            reason: '${proveedor.nombre}: ${capa['id']} -> $clave',
          );
        }
      }
    }
  });

  test('ninguna fuente de mapa usa Google Maps', () {
    for (final proveedor in proveedoresMapa) {
      final estilo = proveedor.style ?? '';
      expect(estilo.toLowerCase().contains('google'), isFalse);
    }
  });

  test('ninguna fuente usa CARTO (marchamo API KEY REQUIRED)', () {
    // CARTO devuelve HTTP 200 con un marchamo "API KEY REQUIRED" en la tesela.
    final estilos = <String>[
      MapaLocal.style,
      ...proveedoresMapa.where((p) => p.style != null).map((p) => p.style!),
    ];
    for (final texto in estilos) {
      final bajo = texto.toLowerCase();
      expect(bajo.contains('cartocdn'), isFalse);
      expect(bajo.contains('api key required'), isFalse);
    }
  });

  test('la versión de la interfaz coincide con pubspec.yaml', () {
    final pubspec = File('pubspec.yaml').readAsStringSync();
    expect(GameGpsApp.version, '0.1.0');
    expect(pubspec, contains('version: ${GameGpsApp.version}+1'));
  });
}
