import 'dart:convert';

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
    expect(
      openmaptiles['attribution'],
      contains('OpenStreetMap'),
    );
  });

  test('el estilo propio aplica la paleta de GAME GPS', () {
    final estilo = jsonDecode(estiloGameGps) as Map<String, dynamic>;
    final capas = estilo['layers'] as List<dynamic>;
    Map<String, dynamic> capa(String id) => capas.cast<Map<String, dynamic>>()
        .firstWhere((c) => c['id'] == id);
    Map<String, dynamic> paint(String id) =>
        capa(id)['paint'] as Map<String, dynamic>;
    bool usaColor(dynamic valor, String color) => valor is String
        ? valor == color
        : jsonEncode(valor).contains(color);

    expect(paint('background')['background-color'], '#060A14');
    expect(paint('water')['fill-color'], '#123C63');
    expect(paint('park')['fill-color'], '#16432F');
    expect(paint('road_minor')['line-color'], '#3D506B');
    expect(paint('road_trunk_primary')['line-color'], '#22D3EE');
    expect(usaColor(paint('road_motorway')['line-color'], '#67E8F9'), isTrue);
    expect(paint('building')['fill-color'], '#16243C');
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
        ProveedorMapaId.cartoDark,
        ProveedorMapaId.osm,
        ProveedorMapaId.hot,
        ProveedorMapaId.topo,
      ]),
    );
  });
}
