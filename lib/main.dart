import 'package:geolocator/geolocator.dart';
import 'package:maplibre/maplibre.dart';
import 'package:material_ui/material_ui.dart';
import 'package:permission_handler/permission_handler.dart';

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

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  MapController? _mapController;
  String? _mensaje;

  /// Pide el permiso, obtiene la posición y lleva el mapa hasta ella.
  Future<void> _ubicar() async {
    setState(() => _mensaje = null);

    final permiso = await Permission.locationWhenInUse.request();
    if (!permiso.isGranted) {
      _mostrarMensaje(
        permiso.isPermanentlyDenied
            ? 'Permiso denegado para siempre. Actívalo en Ajustes del sistema.'
            : 'Necesitamos tu permiso para mostrarte en el mapa.',
      );
      return;
    }

    if (!await Geolocator.isLocationServiceEnabled()) {
      _mostrarMensaje('Activa el GPS del dispositivo para continuar.');
      return;
    }

    try {
      final posicion = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );
      if (!mounted) return;

      final controller = _mapController;
      if (controller == null) return;

      await controller.animateCamera(
        center: Geographic(lon: posicion.longitude, lat: posicion.latitude),
        zoom: 16,
        nativeDuration: const Duration(milliseconds: 900),
      );
      await controller.enableLocation(
        pulse: true,
        pulseFade: true,
        accuracyAnimation: true,
        bearingRenderMode: BearingRenderMode.gps,
      );
    } on Exception {
      _mostrarMensaje('No se pudo obtener tu ubicación. Inténtalo de nuevo.');
    }
  }

  void _mostrarMensaje(String texto) {
    if (!mounted) return;
    setState(() => _mensaje = texto);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: MapLibreMap(
        options: MapOptions(
          initStyle: GameGpsApp.darkStyle,
          initCenter: const Geographic(lon: -73.9857, lat: 40.7484),
          initZoom: 14,
          minZoom: 3,
        ),
        onMapCreated: (controller) {
          _mapController = controller;
          _ubicar();
        },
        children: [
          if (_mensaje != null)
            Positioned(
              top: 16,
              left: 16,
              right: 16,
              child: _Aviso(texto: _mensaje!),
            ),
          Positioned(
            right: 16,
            bottom: 24,
            child: FloatingActionButton(
              heroTag: 'ubicacion',
              backgroundColor: const Color(0xFF00E5FF),
              foregroundColor: const Color(0xFF05070F),
              onPressed: _ubicar,
              tooltip: 'Centrar en mi ubicación',
              child: const Icon(Icons.my_location),
            ),
          ),
        ],
      ),
    );
  }
}

/// Aviso sencillo cuando el permiso o el GPS no están disponibles.
class _Aviso extends StatelessWidget {
  const _Aviso({required this.texto});

  final String texto;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF10182B),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF00E5FF).withValues(alpha: 0.5),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, color: Color(0xFF00E5FF)),
          const SizedBox(width: 10),
          Expanded(child: Text(texto)),
        ],
      ),
    );
  }
}
