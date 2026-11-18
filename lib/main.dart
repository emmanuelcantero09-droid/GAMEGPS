import 'package:maplibre/maplibre.dart';
import 'package:material_ui/material_ui.dart';

void main() => runApp(const GameGpsApp());

class GameGpsApp extends StatelessWidget {
  const GameGpsApp({super.key});

  /// Estilo oscuro basado en teselas CARTO (datos OpenStreetMap).
  /// No requiere API key y mantiene las calles legibles.
  static const String darkStyle = '''
{
  "version": 8,
  "name": "GAME GPS Dark",
  "sources": {
    "carto": {
      "type": "raster",
      "tiles": [
        "https://a.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}.png",
        "https://b.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}.png",
        "https://c.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}.png"
      ],
      "tileSize": 256,
      "attribution": "© OpenStreetMap contributors © CARTO"
    }
  },
  "layers": [
    {
      "id": "fondo",
      "type": "background",
      "paint": {"background-color": "#05070F"}
    },
    {
      "id": "callejero",
      "type": "raster",
      "source": "carto"
    }
  ]
}
''';

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GAME GPS',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF00E5FF),
          brightness: Brightness.dark,
        ),
        scaffoldBackgroundColor: const Color(0xFF05070F),
      ),
      home: const MapScreen(),
    );
  }
}

class MapScreen extends StatelessWidget {
  const MapScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: MapLibreMap(
        options: MapOptions(
          initStyle: GameGpsApp.darkStyle,
          initCenter: Geographic(lon: -73.9857, lat: 40.7484),
          initZoom: 14,
          minZoom: 3,
        ),
      ),
    );
  }
}
