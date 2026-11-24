import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:game_gps/estilo_custom.dart';
import 'package:game_gps/mapas.dart';

void main() {
  test('el estilo propio usa teselas vectoriales de OpenFreeMap', () {
    final estilo = jsonDecode(estiloGameGps) as Map<String, dynamic>;
    final fuentes = estilo['sources'] as Map<String, dynamic>;
    final openmaptiles = fuentes['openmaptiles'] as Map<String, dynamic>;

    expect(estilo['version'], 8);
    expect(openmaptiles['type'], 'vector');
    expect(openmaptiles['url'], 'https://tiles.openfreemap.org/planet');
    expect(openmaptiles['attribution'], contains('OpenStreetMap'));
  });

  test('el estilo propio aplica la paleta de GAME GPS', () {
    final estilo = jsonDecode(estiloGameGps) as Map<String, dynamic>;
    final capas = estilo['layers'] as List<dynamic>;
    Map<String, dynamic> capa(String id) =>
        capas.cast<Map<String, dynamic>>().firstWhere((c) => c['id'] == id);
    Map<String, dynamic> paint(String id) =>
        capa(id)['paint'] as Map<String, dynamic>;
    bool usaColor(dynamic valor, String color) =>
        valor is String ? valor == color : jsonEncode(valor).contains(color);

    expect(paint('background')['background-color'], '#060A14');
    expect(paint('water')['fill-color'], '#123C63');
    expect(paint('park')['fill-color'], '#16432F');
    expect(paint('road_minor')['line-color'], '#7C9AC0');
    expect(paint('road_trunk_primary')['line-color'], '#00E5FF');
    expect(usaColor(paint('road_motorway')['line-color'], '#2FE39A'), isTrue);
    expect(paint('building')['fill-color'], '#1B2D4A');
    // Aspecto GPS: calles legibles y halo bajo las arterias principales.
    expect(paint('highway-name-major')['text-color'], '#FFFFFF');
    expect(paint('highway-name-major')['text-halo-color'], '#050D1A');
    expect(paint('gps_glow_primary')['line-color'], '#00E5FF');
    expect(capas.any((c) => c['id'] == 'gps_glow_motorway'), isTrue);
  });

  test('el proveedor propio está en el catálogo y no quita los demás', () {
    final custom = proveedoresMapa.firstWhere(
      (p) => p.id == ProveedorMapaId.custom,
    );

    expect(custom.style, isNotNull);
    expect(custom.nombre, 'GAME GPS Custom');
    expect(
      proveedoresMapa.map((p) => p.id),
      containsAll([
        ProveedorMapaId.local,
        ProveedorMapaId.gps,
        ProveedorMapaId.hollowNoche,
        ProveedorMapaId.hollowNiebla,
        ProveedorMapaId.hollowCristal,
        ProveedorMapaId.hollowCarmesi,
      ]),
    );
  });

  test('el GPS muestra calles reales de OpenStreetMap', () {
    final gps = proveedoresMapa.firstWhere((p) => p.id == ProveedorMapaId.gps);
    final estilo = jsonDecode(gps.style!) as Map<String, dynamic>;
    final fuentes = estilo['sources'] as Map<String, dynamic>;
    final capas = estilo['layers'] as List<dynamic>;
    final teselas = jsonEncode((fuentes['calles'] as Map)['tiles']);

    expect(estilo['version'], 8);
    expect(capas.map((c) => c['type']), containsAll(['background', 'raster']));
    expect(teselas, contains('tile.openstreetmap.org'));
    expect(teselas, contains('tile.openstreetmap.fr'));
    // Acabado de navegación: sin parpadeo, contraste y tinete GPS.
    final calles = capas.cast<Map<String, dynamic>>().firstWhere(
      (c) => c['id'] == 'calles',
    );
    expect(calles['paint']['raster-fade-duration'], 0);
    expect(calles['paint']['raster-contrast'], greaterThan(0));
    expect(capas.any((c) => c['id'] == 'tinete_gps'), isTrue);
    // CARTO respondía 200 con teselas transparentes: ya no se usa.
    expect(teselas.contains('cartocdn'), isFalse);
    expect(jsonEncode(estilo).toLowerCase().contains('google'), isFalse);
  });

  test('el mapa propio trae teselas reales embebidas', () {
    final centro = File('assets/tiles/16-19010-31628.png').readAsBytesSync();
    final vecina = File('assets/tiles/16-19011-31629.png').readAsBytesSync();
    expect(centro.length, greaterThan(1000));
    expect(vecina.length, greaterThan(1000));
    // Si todas las teselas fueran iguales, el mapa se vería en blanco.
    expect(centro, isNot(vecina));
  });

  test(
    'los cuatro reinos Hollow Knight recolorean el mapa y cambian los iconos',
    () {
      for (final proveedor in proveedoresMapa.where(
        (p) => p.id.name.startsWith('hollow'),
      )) {
        final estilo = jsonDecode(proveedor.style!) as Map<String, dynamic>;
        final capas = estilo['layers'] as List<dynamic>;
        Map<String, dynamic> capa(String id) =>
            capas.cast<Map<String, dynamic>>().firstWhere((c) => c['id'] == id);

        // Ningún color del estilo original queda intacto.
        final texto = jsonEncode(estilo);
        for (final color in ['#060A14', '#16432F', '#3D506B', '#22D3EE']) {
          expect(texto.contains(color), isFalse, reason: proveedor.nombre);
        }
        // La base raster real va al 100%: no hay capas de relleno opacas
        // que dejen las calles vacías.
        expect(capa('base_detalle')['type'], 'raster');
        expect(capa('base_detalle')['paint']['raster-opacity'], 1.0);
        expect(capa('tinete_reino')['paint']['background-opacity'], 0.16);
        expect(
          capas
              .cast<Map<String, dynamic>>()
              .where((c) => c['type'] == 'fill' || c['type'] == 'line')
              .map((c) => c['id']),
          isEmpty,
        );
        final iconos = jsonEncode(capa('poi_r20')['layout']['icon-image']);
        expect(iconos, contains('hollow_hospital'));
        expect(iconos, contains('hollow_comida'));
        expect(iconos, contains('hollow_runa'));
      }
    },
  );
}
