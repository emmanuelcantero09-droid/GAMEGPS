import 'dart:async';

import 'package:geolocator/geolocator.dart' as geo;
import 'package:maplibre/maplibre.dart';
import 'package:material_ui/material_ui.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'busqueda.dart';
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
  ProveedorMapaId _proveedor = ProveedorMapaId.cartoDark;
  bool _siguiendo = true;
  bool _centroFijado = false;
  double _centroLon = MapaLocal.centroPorDefectoLon;
  double _centroLat = MapaLocal.centroPorDefectoLat;
  SkinId _skin = SkinId.clasico;
  SharedPreferences? _prefs;

  final TextEditingController _buscador = TextEditingController();
  Timer? _busquedaTimer;
  List<Lugar> _resultados = const [];
  bool _buscando = false;
  Lugar? _destino;

  @override
  void initState() {
    super.initState();
    _cargarPreferencias();
  }

  @override
  void dispose() {
    // Evita que el GPS y la búsqueda sigan activos tras cerrar la pantalla.
    _posicionStream?.cancel();
    _busquedaTimer?.cancel();
    _buscador.dispose();
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
    if (_siguiendo) {
      _moverCamara(posicion.longitude, posicion.latitude);
    }
  }

  /// Mueve la cámara hasta unas coordenadas conservando el zoom del usuario.
  Future<void> _moverCamara(double lon, double lat) async {
    final controller = _mapController;
    if (controller == null) return;
    await controller.animateCamera(
      center: Geographic(lon: lon, lat: lat),
      zoom: controller.camera?.zoom ?? 16,
      nativeDuration: const Duration(milliseconds: 700),
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

  /// Espera un momento después de escribir para no consultar en cada letra.
  void _alBuscar(String texto) {
    _busquedaTimer?.cancel();
    setState(() => _resultados = const []);
    if (texto.trim().length < 3) return;
    _busquedaTimer = Timer(
      const Duration(milliseconds: 500),
      () => _ejecutarBusqueda(texto),
    );
  }

  Future<void> _ejecutarBusqueda(String texto) async {
    setState(() => _buscando = true);
    try {
      final lugares = await ServicioBusqueda().buscar(texto);
      if (!mounted) return;
      setState(() {
        _resultados = lugares;
        _buscando = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _resultados = const [];
        _buscando = false;
        _mensaje = 'No se pudo buscar. Revisa tu conexión a internet.';
      });
    }
  }

  /// Muestra el lugar elegido en el mapa y guarda la distancia hasta él.
  void _elegirLugar(Lugar lugar) {
    FocusScope.of(context).unfocus();
    setState(() {
      _destino = lugar;
      _resultados = const [];
      _mensaje = null;
      _buscador.text = lugar.nombre;
    });
    _moverCamara(lugar.lon, lugar.lat);
  }

  void _limpiarBusqueda() {
    _busquedaTimer?.cancel();
    setState(() {
      _buscador.clear();
      _resultados = const [];
      _destino = null;
      _buscando = false;
    });
  }

  /// Distancia en línea recta desde tu posición hasta el destino.
  String _distanciaAlDestino(Lugar lugar) {
    final posicion = _posicion;
    if (posicion == null) return 'Esperando tu ubicación…';
    final metros = geo.Geolocator.distanceBetween(
      posicion.latitude,
      posicion.longitude,
      lugar.lat,
      lugar.lon,
    );
    return metros < 1000
        ? '${metros.round()} m de ti'
        : '${(metros / 1000).toStringAsFixed(1)} km de ti';
  }

  /// Caja de búsqueda con sus resultados debajo.
  Widget _panelBusqueda() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xE610182B),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0x6600E5FF)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _buscador,
            onChanged: _alBuscar,
            style: const TextStyle(color: Colors.white, fontSize: 14),
            decoration: InputDecoration(
              hintText: 'Buscar calle, lugar o ciudad…',
              hintStyle: const TextStyle(
                color: Color(0xFF8FA3BF),
                fontSize: 13,
              ),
              prefixIcon: const Icon(
                Icons.search,
                color: Color(0xFF00E5FF),
                size: 20,
              ),
              suffixIcon: _buscador.text.isEmpty
                  ? null
                  : IconButton(
                      icon: const Icon(
                        Icons.close,
                        color: Color(0xFF8FA3BF),
                        size: 18,
                      ),
                      onPressed: _limpiarBusqueda,
                      tooltip: 'Limpiar búsqueda',
                    ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 12,
              ),
            ),
          ),
          if (_buscando)
            const LinearProgressIndicator(
              minHeight: 2,
              color: Color(0xFF00E5FF),
              backgroundColor: Color(0x3300E5FF),
            ),
          ..._resultados.map(
            (lugar) => ListTile(
              dense: true,
              leading: const Icon(
                Icons.place_outlined,
                color: Color(0xFF00E5FF),
                size: 20,
              ),
              title: Text(
                lugar.nombre,
                style: const TextStyle(color: Colors.white, fontSize: 13),
              ),
              subtitle: Text(
                lugar.detalle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xFF8FA3BF),
                  fontSize: 10,
                ),
              ),
              onTap: () => _elegirLugar(lugar),
            ),
          ),
        ],
      ),
    );
  }

  /// Tarjeta con el destino elegido y su distancia.
  Widget _panelDestino() {
    final lugar = _destino!;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xE610182B),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0x66FF3D71)),
      ),
      child: Row(
        children: [
          const Icon(Icons.flag, color: Color(0xFFFF3D71)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  lugar.nombre,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${_distanciaAlDestino(lugar)} · '
                  '${lugar.lat.toStringAsFixed(4)}, '
                  '${lugar.lon.toStringAsFixed(4)}',
                  style: const TextStyle(
                    color: Color(0xFF8FA3BF),
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, color: Color(0xFF8FA3BF)),
            onPressed: () => setState(() => _destino = null),
            tooltip: 'Quitar destino',
          ),
        ],
      ),
    );
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
            if (_posicion != null) {
              _moverCamara(_posicion!.longitude, _posicion!.latitude);
            }
          } else {
            _ubicar();
          }
        },
        children: [
          // Indicador anclado a la posición geográfica (cambia con el skin).
          WidgetLayer(
            markers: [
              if (_destino != null)
                Marker(
                  point: Geographic(lon: _destino!.lon, lat: _destino!.lat),
                  size: const Size(40, 40),
                  child: const Icon(
                    Icons.place,
                    color: Color(0xFFFF3D71),
                    size: 40,
                    shadows: [Shadow(color: Color(0xFF05070F), blurRadius: 6)],
                  ),
                ),
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
          // Buscador arriba; el botón de seguir queda libre a la derecha.
          Positioned(
            top: 16,
            left: 16,
            right: 72,
            child: _panelBusqueda(),
          ),
          if (_mensaje != null)
            Positioned(
              top: 68,
              left: 16,
              right: 72,
              child: _Aviso(texto: _mensaje!),
            ),
          // Versión de la app, bajo el botón de seguir y sin capturar toques.
          const Positioned(
            right: 16,
            top: 72,
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
          if (_mensaje == null && _resultados.isEmpty && !_buscando)
            Positioned(
              top: 68,
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
                if (_siguiendo && _posicion != null) {
                  _moverCamara(_posicion!.longitude, _posicion!.latitude);
                }
              },
              tooltip: _siguiendo
                  ? 'Dejar de seguir mi posición'
                  : 'Seguir mi posición',
              child: Icon(
                _siguiendo ? Icons.gps_fixed : Icons.gps_not_fixed,
              ),
            ),
          ),
          if (_destino != null)
            Positioned(
              left: 16,
              right: 16,
              bottom: 88,
              child: _panelDestino(),
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
