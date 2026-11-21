import 'dart:async';

import 'package:geolocator/geolocator.dart' as geo;
import 'package:maplibre/maplibre.dart';
import 'package:material_ui/material_ui.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'mapa_local.dart';
import 'mapas.dart';
import 'skins.dart';

void main() => runApp(const GameGpsApp());

class GameGpsApp extends StatelessWidget {
  const GameGpsApp({super.key});

  /// Versión visible en la interfaz. Debe coincidir con `pubspec.yaml`.
  static const String version = '0.1.0';

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
  StreamSubscription<geo.Position>? _posicionStream;
  String? _mensaje;
  geo.Position? _posicion;
  ProveedorMapaId _proveedor = ProveedorMapaId.local;
  bool _siguiendo = true;
  bool _centroFijado = false;
  double _centroLon = MapaLocal.centroPorDefectoLon;
  double _centroLat = MapaLocal.centroPorDefectoLat;
  SkinId _skin = SkinId.clasico;
  SharedPreferences? _prefs;

  @override
  void initState() {
    super.initState();
    _cargarPreferencias();
  }

  @override
  void dispose() {
    // Evita que el GPS siga enviando eventos después de cerrar la pantalla.
    _posicionStream?.cancel();
    super.dispose();
  }

  Future<void> _cargarPreferencias() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    final nombre = prefs.getString('skin_indicador');
    final guardado = nombre == null
        ? null
        : SkinId.values.where((s) => s.name == nombre).firstOrNull;
    final provNombre = prefs.getString('proveedor_mapa');
    final proveedorGuardado = provNombre == null
        ? null
        : ProveedorMapaId.values.where((p) => p.name == provNombre).firstOrNull;
    setState(() {
      _prefs = prefs;
      if (guardado != null) _skin = guardado;
      if (proveedorGuardado != null) _proveedor = proveedorGuardado;
    });
  }

  /// Pide el permiso y arranca el seguimiento continuo de la posición.
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

    if (!await geo.Geolocator.isLocationServiceEnabled()) {
      _mostrarMensaje('Activa el GPS del dispositivo para continuar.');
      return;
    }

    // Fuerza el LocationManager de Android: así no dependemos de Google Play.
    final ajustes = geo.AndroidSettings(
      forceLocationManager: true,
      accuracy: geo.LocationAccuracy.high,
      distanceFilter: 3,
      intervalDuration: const Duration(seconds: 2),
      timeLimit: const Duration(seconds: 10),
    );

    try {
      final inicial = await geo.Geolocator.getCurrentPosition(
        locationSettings: ajustes,
      );
      _aplicarPosicion(inicial);

      await _posicionStream?.cancel();
      _posicionStream = geo.Geolocator.getPositionStream(
        locationSettings: ajustes,
      ).listen(
        _aplicarPosicion,
        onError: (_) =>
            _mostrarMensaje('Se perdió la señal GPS. Reintentando…'),
      );

    } on Exception {
      _mostrarMensaje('No se pudo obtener tu ubicación. Inténtalo de nuevo.');
    }
  }

  /// Actualiza el marcador, fija el centro del mapa local una sola vez
  /// y acerca la cámara si el modo "seguir" está activo.
  void _aplicarPosicion(geo.Position posicion) {
    if (!mounted) return;
    final fijarCentro = !_centroFijado;
    setState(() {
      _posicion = posicion;
      if (fijarCentro) {
        _centroLon = posicion.longitude;
        _centroLat = posicion.latitude;
        _centroFijado = true;
      }
    });
    if (_siguiendo) _centrarEn(posicion);
  }

  /// Mueve la cámara hasta [posicion] conservando el zoom elegido por el usuario.
  Future<void> _centrarEn(geo.Position posicion) async {
    final controller = _mapController;
    if (controller == null) return;
    await controller.animateCamera(
      center: Geographic(lon: posicion.longitude, lat: posicion.latitude),
      zoom: controller.camera?.zoom ?? 16,
      nativeDuration: const Duration(milliseconds: 500),
    );
  }

  /// Muestra las fuentes de mapa gratuitas y aplica la selección.
  Future<void> _abrirFuentes() async {
    final elegido = await showModalBottomSheet<ProveedorMapaId>(
      context: context,
      backgroundColor: const Color(0xFF0B1220),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Fuente del mapa',
                style: TextStyle(
                  color: Color(0xFF00E5FF),
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Ninguna usa Google Maps ni requiere API key',
                style: TextStyle(color: Color(0xFF8FA3BF), fontSize: 12),
              ),
              const SizedBox(height: 12),
              ...proveedoresMapa.map(
                (p) => ListTile(
                  leading: Icon(
                    p.id == _proveedor
                        ? Icons.check_circle
                        : Icons.circle_outlined,
                    color: const Color(0xFF00E5FF),
                  ),
                  title: Text(
                    p.nombre,
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                  ),
                  subtitle: Text(
                    p.detalle,
                    style: const TextStyle(
                      color: Color(0xFF8FA3BF),
                      fontSize: 11,
                    ),
                  ),
                  onTap: () => Navigator.pop(context, p.id),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    if (elegido != null) {
      setState(() => _proveedor = elegido);
      await _prefs?.setString('proveedor_mapa', elegido.name);
    }
  }

  /// Muestra el catálogo de skins y aplica la selección.
  Future<void> _abrirCatalogo() async {
    final elegido = await showModalBottomSheet<SkinId>(
      context: context,
      backgroundColor: const Color(0xFF0B1220),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.asset(
                      'assets/logo/app_icon.png',
                      width: 48,
                      height: 48,
                    ),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Skins del indicador',
                          style: TextStyle(
                            color: Color(0xFF00E5FF),
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Elegí cómo aparece tu posición en el mapa',
                          style: TextStyle(
                            color: Color(0xFF8FA3BF),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 0.78,
                ),
                itemCount: skins.length,
                itemBuilder: (context, index) {
                  final skin = skins[index];
                  final activo = skin.id == _skin;
                  return InkWell(
                    onTap: () => Navigator.pop(context, skin.id),
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      decoration: BoxDecoration(
                        color: activo
                            ? const Color(0x3326A8FF)
                            : const Color(0xFF10182B),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: activo
                              ? const Color(0xFF00E5FF)
                              : const Color(0x3300E5FF),
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          skin.build(seleccionado: activo),
                          const SizedBox(height: 4),
                          Text(
                            skin.nombre,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: activo
                                  ? const Color(0xFF00E5FF)
                                  : Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: Text(
                              skin.descripcion,
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              style: const TextStyle(
                                color: Color(0xFF8FA3BF),
                                fontSize: 9,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
    if (elegido != null) {
      setState(() => _skin = elegido);
      await _prefs?.setString('skin_indicador', elegido.name);
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
        // Se reconstruye al cambiar de fuente para aplicar el nuevo estilo.
        key: ValueKey(_proveedor),
        options: MapOptions(
          initStyle:
              proveedoresMapa.firstWhere((p) => p.id == _proveedor).style ??
              MapaLocal.style,
          initCenter: Geographic(lon: _centroLon, lat: _centroLat),
          initZoom: 16,
          minZoom: 3,
        ),
        layers: _proveedor == ProveedorMapaId.local
            ? MapaLocal.layers(lon: _centroLon, lat: _centroLat)
            : <Layer>[],
        onMapCreated: (controller) {
          _mapController = controller;
          if (_posicionStream != null) {
            // El mapa se recreó al cambiar de fuente: volver a centrar.
            if (_posicion != null) _centrarEn(_posicion!);
          } else {
            _ubicar();
          }
        },
        children: [
          // Indicador anclado a la posición geográfica (cambia con el skin).
          WidgetLayer(
            markers: [
              Marker(
                point: Geographic(
                  lon: _posicion?.longitude ?? MapaLocal.centroPorDefectoLon,
                  lat: _posicion?.latitude ?? MapaLocal.centroPorDefectoLat,
                ),
                size: const Size(56, 56),
                child: skins
                    .firstWhere((s) => s.id == _skin)
                    .build(seleccionado: true),
              ),
            ],
          ),
          if (_mensaje != null)
            Positioned(
              top: 16,
              left: 16,
              right: 72,
              child: _Aviso(texto: _mensaje!),
            ),
          // Versión de la app, arriba del botón de fuentes y sin capturar toques.
          const Positioned(
            left: 16,
            bottom: 92,
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Color(0x9910182B),
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                ),
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  child: Text(
                    'GAME GPS v${GameGpsApp.version}',
                    style: TextStyle(
                      color: Color(0xFF8FA3BF),
                      fontSize: 10,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
              ),
            ),
          ),
          if (_mensaje == null)
            Positioned(
              top: 16,
              left: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xCC10182B),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0x6600E5FF)),
                ),
                child: Text(
                  proveedoresMapa
                      .firstWhere((p) => p.id == _proveedor)
                      .nombre
                      .toUpperCase(),
                  style: const TextStyle(
                    color: Color(0xFF00E5FF),
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          // Botón para activar/desactivar que la cámara siga al usuario.
          Positioned(
            top: 16,
            right: 16,
            child: FloatingActionButton.small(
              heroTag: 'seguir',
              backgroundColor: const Color(0xCC10182B),
              foregroundColor: _siguiendo
                  ? const Color(0xFF00E5FF)
                  : const Color(0xFF8FA3BF),
              onPressed: () {
                setState(() => _siguiendo = !_siguiendo);
                if (_siguiendo && _posicion != null) _centrarEn(_posicion!);
              },
              tooltip: _siguiendo
                  ? 'Dejar de seguir mi posición'
                  : 'Seguir mi posición',
              child: Icon(
                _siguiendo ? Icons.gps_fixed : Icons.gps_not_fixed,
              ),
            ),
          ),
          Positioned(
            left: 16,
            bottom: 24,
            child: FloatingActionButton(
              heroTag: 'fuentes',
              backgroundColor: const Color(0xFF10182B),
              foregroundColor: const Color(0xFF00E5FF),
              onPressed: _abrirFuentes,
              tooltip: 'Elegir fuente del mapa',
              child: const Icon(Icons.layers),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 24,
            child: Center(
              child: FloatingActionButton(
                heroTag: 'skins',
                backgroundColor: const Color(0xFF7B2BFF),
                foregroundColor: Colors.white,
                onPressed: _abrirCatalogo,
                tooltip: 'Cambiar skin del indicador',
                child: const Icon(Icons.palette),
              ),
            ),
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
