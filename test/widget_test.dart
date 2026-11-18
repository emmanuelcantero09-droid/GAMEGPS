import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:game_gps/main.dart';

void main() {
  test('el estilo oscuro es un documento MapLibre válido', () {
    final estilo = jsonDecode(GameGpsApp.darkStyle) as Map<String, dynamic>;

    expect(estilo['version'], 8);
    expect(estilo['sources'], isA<Map<String, dynamic>>());
    expect(estilo['layers'], isA<List<dynamic>>());
  });
}
