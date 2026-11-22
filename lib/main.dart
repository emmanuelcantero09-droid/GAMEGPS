import 'dart:async';
import 'dart:io';

import 'package:geolocator/geolocator.dart' as geo;
import 'package:image_picker/image_picker.dart' as picker;
import 'package:maplibre/maplibre.dart';
import 'package:material_ui/material_ui.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'busqueda.dart';
import 'capa_ruta.dart';
import 'inventario.dart';
import 'mapa_local.dart';
import 'mapas.dart';
import 'puntos.dart';
import 'rutas.dart';
import 'skins.dart';
import 'tienda.dart';

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
  static const int _maxIntentosGps = 4;
  static const double _radioBusquedaMetros = 100000;

  MapController? _mapController;
  StreamSubscription<geo.Position>? _posicionStream;
  Timer? _reintentoGps;
  int _intentosGps = 0;
  bool _reintentando = false;
  bool _avisoEsGps = false;
  String? _mensaje;
  String? _etiquetaAccion;
  VoidCallback? _accionAviso;
  geo.Position? _posicion;
  geo.Position? _ultimaPosicionPuntos;
  Puntos _puntos = const Puntos();
  ProveedorMapaId _proveedor = ProveedorMapaId.cartoDark;
  bool _siguiendo = true;
  bool _centroFijado = false;
  double _centroLon = MapaLocal.centroPorDefectoLon;
  double _centroLat = MapaLocal.centroPorDefectoLat;
  String _skin = SkinId.clasico.name;
  List<DisenoPropio> _disenosPropios = const [];
  List<String> _comprados = const [];
  SharedPreferences? _prefs;

  /// Skins incluidos, comprados en la tienda y subidos por el usuario.
  List<Skin> get _skinsDisponibles => [
        ...skins,
        for (final articulo in tiendaSkins)
          if (_comprados.contains(articulo.id)) articulo.skin,
        for (final diseno in _disenosPropios)
          Skin(
            id: diseno.id,
            nombre: diseno.nombre,
            descripcion: 'Diseño propio',
            rutaImagen: diseno.rutaImagen,
          ),
      ];

  final TextEditingController _buscador = TextEditingController();
  Timer? _busquedaTimer;
  int _busquedaGeneracion = 0;
  List<Lugar> _resultados = const [];
  bool _buscando = false;
  Lugar? _destino;
  Ruta? _ruta;
  bool _calculandoRuta = false;
  int _rutaGeneracion = 0;
  OpcionesRuta _opciones = const OpcionesRuta();

  @override
  void initState() {
    super.initState();
    _cargarPreferencias();
  }

  @override
  void dispose() {
    // Evita que el GPS y la búsqueda sigan activos tras cerrar la pantalla.
    _posicionStream?.cancel();
    _reintentoGps?.cancel();
    _busquedaTimer?.cancel();
    _buscador.dispose();
    super.dispose();
  }

  Future<void> _cargarPreferencias() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    final nombre = prefs.getString('skin_indicador');
    final disenos = InventarioDisenos.leer(prefs);
    final provNombre = prefs.getString('proveedor_mapa');
    final proveedorGuardado = provNombre == null
        ? null
        : ProveedorMapaId.values.where((p) => p.name == provNombre).firstOrNull;
    final opciones = OpcionesRuta(
      modo: _valorGuardado(
        ModoRuta.values,
        prefs.getString('ruta_modo'),
        ModoRuta.coche,
      ),
      idioma: _valorGuardado(
        IdiomaInstrucciones.values,
        prefs.getString('ruta_idioma'),
        IdiomaInstrucciones.es,
      ),
      unidades: _valorGuardado(
        UnidadesRuta.values,
        prefs.getString('ruta_unidades'),
        UnidadesRuta.kilometros,
      ),
      color: prefs.getInt('ruta_color') ?? 0xFF00E5FF,
      grosor: prefs.getInt('ruta_grosor') ?? 5,
    );
    final puntos = Puntos.cargar(prefs).registrarDia(DateTime.now());
    final comprados = InventarioTienda.cargar(prefs);
    await puntos.guardar(prefs);
    if (!mounted) return;
    setState(() {
      _prefs = prefs;
      _disenosPropios = disenos;
      _comprados = comprados;
      if (nombre != null) _skin = nombre;
      if (proveedorGuardado != null) _proveedor = proveedorGuardado;
      _opciones = opciones;
      _puntos = puntos;
    });
  }

  /// Devuelve el valor guardado de un enum, o el valor por defecto.
  T _valorGuardado<T extends Enum>(List<T> valores, String? nombre, T porDefecto) {
    if (nombre == null) return porDefecto;
    for (final valor in valores) {
      if (valor.name == nombre) return valor;
    }
    return porDefecto;
  }

  /// Guarda las preferencias de la ruta para la próxima vez.
  Future<void> _guardarOpciones() async {
    final prefs = _prefs ?? await SharedPreferences.getInstance();
    _prefs = prefs;
    await prefs.setString('ruta_modo', _opciones.modo.name);
    await prefs.setString('ruta_idioma', _opciones.idioma.name);
    await prefs.setString('ruta_unidades', _opciones.unidades.name);
    await prefs.setInt('ruta_color', _opciones.color);
    await prefs.setInt('ruta_grosor', _opciones.grosor);
  }

  /// Pide el permiso y arranca el seguimiento continuo de la posición.
  Future<void> _ubicar() async {
    _reintentoGps?.cancel();
    _reintentando = false;
    _intentosGps = 0;
    setState(() {
      _mensaje = null;
      _avisoEsGps = false;
      _accionAviso = null;
      _etiquetaAccion = null;
    });
    await _iniciarSeguimiento(pedirPermiso: true);
  }

  /// Configura el GPS y se suscribe al flujo continuo de posiciones.
  Future<void> _iniciarSeguimiento({required bool pedirPermiso}) async {
    if (pedirPermiso) {
      final permiso = await Permission.locationWhenInUse.request();
      if (!permiso.isGranted) {
        _mostrarMensaje(
          permiso.isPermanentlyDenied
              ? 'Permiso denegado para siempre. Actívalo en Ajustes del sistema.'
              : 'Necesitamos tu permiso para mostrarte en el mapa.',
          etiquetaAccion: permiso.isPermanentlyDenied ? 'Abrir ajustes' : null,
          accion: permiso.isPermanentlyDenied ? openAppSettings : null,
        );
        return;
      }
    }

    if (!await geo.Geolocator.isLocationServiceEnabled()) {
      _mostrarMensaje(
        'Activa el GPS del dispositivo para continuar.',
        esGps: true,
      );
      return;
    }

    // Fuerza el LocationManager de Android: así no dependemos de Google Play.
    // En Android 12+ usa el proveedor fusionado del sistema cuando está activo.
    // La primera posición sí tiene límite: si no llega, avisamos al usuario.
    final inicialAjustes = geo.AndroidSettings(
      forceLocationManager: true,
      accuracy: geo.LocationAccuracy.high,
      distanceFilter: 3,
      intervalDuration: const Duration(seconds: 2),
      timeLimit: const Duration(seconds: 10),
    );

    // El seguimiento continuo NO lleva timeLimit: geolocator cierra el stream
    // con un TimeoutException si no llega un evento durante ese tiempo, y
    // estando quieto no hay eventos porque distanceFilter es 3 m. Eso causaba
    // el aviso falso de "señal perdida" cada pocos segundos.
    final streamAjustes = geo.AndroidSettings(
      forceLocationManager: true,
      accuracy: geo.LocationAccuracy.high,
      distanceFilter: 0,
      intervalDuration: const Duration(seconds: 2),
    );

    try {
      // Solo esperamos la primera posición; en los reintentos ya tenemos una.
      if (_posicion == null) {
        final inicial = await geo.Geolocator.getCurrentPosition(
          locationSettings: inicialAjustes,
        );
        _aplicarPosicion(inicial);
      }

      await _posicionStream?.cancel();
      _posicionStream = geo.Geolocator.getPositionStream(
        locationSettings: streamAjustes,
      ).listen(
        _aplicarPosicion,
        onError: (_) => _falloGps('Se perdió la señal GPS.'),
        onDone: () => _falloGps('Se cerró la señal GPS.'),
      );
    } on Exception {
      _falloGps('No se pudo obtener tu ubicación.');
    }
  }

  /// Programa un reintento real: antes el mensaje lo prometía y no lo hacía.
  void _falloGps(String motivo) {
    if (_reintentando || !mounted) return;
    _reintentando = true;
    _posicionStream?.cancel();
    _posicionStream = null;
    _intentosGps++;

    if (_intentosGps > _maxIntentosGps) {
      _mostrarMensaje(
        '$motivo No se pudo recuperar la señal.',
        etiquetaAccion: 'Reintentar',
        accion: _ubicar,
        esGps: true,
      );
      return;
    }

    final segundos = _intentosGps * 2;
    _mostrarMensaje('$motivo Reintentando en $segundos s…', esGps: true);
    _reintentoGps?.cancel();
    _reintentoGps = Timer(Duration(seconds: segundos), () {
      _reintentando = false;
      _iniciarSeguimiento(pedirPermiso: false);
    });
  }

  /// Actualiza el marcador, fija el centro del mapa local una sola vez
  /// y acerca la cámara si el modo "seguir" está activo.
  void _aplicarPosicion(geo.Position posicion) {
    if (!mounted) return;
    _reintentoGps?.cancel();
    _reintentando = false;
    _intentosGps = 0;
    final fijarCentro = !_centroFijado;

    // Puntos por distancia real recorrida, ignorando saltos bruscos del GPS.
    final anterior = _ultimaPosicionPuntos;
    _ultimaPosicionPuntos = posicion;
    var puntos = _puntos;
    if (anterior != null) {
      final metros = geo.Geolocator.distanceBetween(
        anterior.latitude,
        anterior.longitude,
        posicion.latitude,
        posicion.longitude,
      );
      if (metros > 0 && metros < 100) puntos = puntos.sumarDistancia(metros);
    }

    // Puntos por llegar al destino, una sola vez por lugar.
    var llegadaNueva = false;
    final destino = _destino;
    if (destino != null) {
      const radioLlegada = 30.0;
      final distancia = geo.Geolocator.distanceBetween(
        posicion.latitude,
        posicion.longitude,
        destino.lat,
        destino.lon,
      );
      if (distancia < radioLlegada) {
        final clave =
            '${destino.lat.toStringAsFixed(4)},${destino.lon.toStringAsFixed(4)}';
        final conLlegada = puntos.registrarLlegada(clave);
        if (conLlegada.saldo > puntos.saldo) llegadaNueva = true;
        puntos = conLlegada;
      }
    }

    final ganados = puntos.saldo - _puntos.saldo;
    setState(() {
      if (_avisoEsGps) {
        _mensaje = null;
        _etiquetaAccion = null;
        _accionAviso = null;
        _avisoEsGps = false;
      }
      _posicion = posicion;
      _puntos = puntos;
      if (fijarCentro) {
        _centroLon = posicion.longitude;
        _centroLat = posicion.latitude;
        _centroFijado = true;
      }
    });
    if (ganados > 0) {
      final prefs = _prefs;
      if (prefs != null) unawaited(puntos.guardar(prefs));
    }
    if (llegadaNueva) {
      _mostrarMensaje('¡Llegaste al destino! +${Puntos.puntosPorLlegada} puntos.');
    }
    if (_siguiendo) {
      _moverCamara(posicion.longitude, posicion.latitude);
    }
  }

  /// Mueve la cámara hasta unas coordenadas.
  /// Si no se indica [zoom], conserva el nivel actual del usuario.
  Future<void> _moverCamara(double lon, double lat, {double? zoom}) async {
    final controller = _mapController;
    if (controller == null) return;
    await controller.animateCamera(
      center: Geographic(lon: lon, lat: lat),
      zoom: zoom ?? controller.camera?.zoom ?? 16,
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

  /// Muestra la tienda de skins y permite comprarlos con los puntos ganados.
  Future<void> _abrirTienda() async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF0B1220),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, actualizarHoja) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Tienda de skins',
                        style: TextStyle(
                          color: Color(0xFF00E5FF),
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0x3326A8FF),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.star,
                            size: 14,
                            color: Color(0xFFFFD54F),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            '${_puntos.saldo}',
                            style: const TextStyle(
                              color: Color(0xFFFFD54F),
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                const Text(
                  'Ganá puntos caminando, llegando a destinos y por tu racha diaria.',
                  style: TextStyle(color: Color(0xFF8FA3BF), fontSize: 12),
                ),
                const SizedBox(height: 14),
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: tiendaSkins.length,
                    itemBuilder: (context, index) {
                      final articulo = tiendaSkins[index];
                      final comprado = _comprados.contains(articulo.id);
                      final alcanza = _puntos.saldo >= articulo.precio;
                      return Card(
                        color: const Color(0xFF10182B),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: ListTile(
                          leading: articulo.skin.build(seleccionado: false),
                          title: Text(
                            articulo.nombre,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                            ),
                          ),
                          subtitle: Text(
                            '${articulo.descripcion} · ${articulo.precio} puntos',
                            style: const TextStyle(
                              color: Color(0xFF8FA3BF),
                              fontSize: 11,
                            ),
                          ),
                          trailing: comprado
                              ? const Icon(
                                  Icons.check_circle,
                                  color: Color(0xFF00FFA3),
                                )
                              : FilledButton(
                                  onPressed: alcanza
                                      ? () =>
                                          _comprarSkin(articulo, actualizarHoja)
                                      : null,
                                  style: FilledButton.styleFrom(
                                    backgroundColor: const Color(0xFF7B2BFF),
                                    disabledBackgroundColor:
                                        const Color(0xFF222C42),
                                  ),
                                  child: Text(
                                    alcanza
                                        ? 'Comprar'
                                        : 'Faltan ${articulo.precio - _puntos.saldo}',
                                    style: const TextStyle(fontSize: 11),
                                  ),
                                ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Descuenta los puntos, guarda la compra y refresca la hoja de la tienda.
  Future<void> _comprarSkin(
    SkinTienda articulo,
    StateSetter actualizarHoja,
  ) async {
    if (_comprados.contains(articulo.id)) return;
    final nuevosPuntos = _puntos.gastar(articulo.precio);
    if (nuevosPuntos.saldo == _puntos.saldo) return;
    final prefs = _prefs ?? await SharedPreferences.getInstance();
    final nuevosComprados = [..._comprados, articulo.id];
    await Future.wait([
      InventarioTienda.guardar(prefs, nuevosComprados),
      nuevosPuntos.guardar(prefs),
    ]);
    if (!mounted) return;
    setState(() {
      _prefs = prefs;
      _puntos = nuevosPuntos;
      _comprados = nuevosComprados;
    });
    actualizarHoja(() {});
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${articulo.nombre} comprado. Ya podés usarlo en 🎨.'),
        backgroundColor: const Color(0xFF10182B),
      ),
    );
  }

  /// Muestra el inventario de skins y aplica la selección.
  Future<void> _abrirCatalogo() async {
    final elegido = await showModalBottomSheet<String>(
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
                          'Inventario: elegí o subí tu propio diseño',
                          style: TextStyle(
                            color: Color(0xFF8FA3BF),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.add_photo_alternate,
                      color: Color(0xFF00E5FF),
                    ),
                    tooltip: 'Agregar diseño propio',
                    onPressed: () => Navigator.pop(context, '_agregar'),
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
                itemCount: _skinsDisponibles.length,
                itemBuilder: (context, index) {
                  final skin = _skinsDisponibles[index];
                  final activo = skin.id == _skin;
                  return Stack(
                    children: [
                      InkWell(
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
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 4,
                                ),
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
                      ),
                      if (skin.esPropio)
                        Positioned(
                          top: 0,
                          right: 0,
                          child: IconButton(
                            icon: const Icon(
                              Icons.delete_outline,
                              color: Color(0xFFFF3D71),
                              size: 20,
                            ),
                            tooltip: 'Eliminar diseño',
                            onPressed: () async {
                              await _eliminarDiseno(skin.id);
                              if (context.mounted) {
                                Navigator.pop(context, '_recargar');
                              }
                            },
                          ),
                        ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
    if (elegido == '_agregar') {
      await _agregarDiseno();
      if (mounted) await _abrirCatalogo();
      return;
    }
    if (elegido == '_recargar') {
      if (mounted) await _abrirCatalogo();
      return;
    }
    if (elegido != null) {
      setState(() => _skin = elegido);
      await _prefs?.setString('skin_indicador', elegido);
    }
  }

  /// Elige una imagen de la galería, la copia al almacenamiento de la app
  /// y la agrega al inventario como un diseño más.
  Future<void> _agregarDiseno() async {
    final prefs = _prefs;
    if (prefs == null) return;
    final imagen = await picker.ImagePicker().pickImage(
      source: picker.ImageSource.gallery,
      imageQuality: 85,
      maxWidth: 512,
      maxHeight: 512,
    );
    if (imagen == null) return;

    final id = 'propio_${DateTime.now().millisecondsSinceEpoch}';
    try {
      final documentos = await getApplicationDocumentsDirectory();
      final carpeta = Directory('${documentos.path}/disenos');
      if (!await carpeta.exists()) await carpeta.create(recursive: true);
      final destino = '${carpeta.path}/$id.jpg';
      await File(imagen.path).copy(destino);

      final nuevo = DisenoPropio(
        id: id,
        nombre: 'Diseño ${_disenosPropios.length + 1}',
        rutaImagen: destino,
      );
      final actualizados = [..._disenosPropios, nuevo];
      await InventarioDisenos.guardar(prefs, actualizados);
      if (!mounted) return;
      setState(() {
        _disenosPropios = actualizados;
        _skin = id;
      });
      await prefs.setString('skin_indicador', id);
    } catch (_) {
      if (mounted) {
        _mostrarMensaje('No se pudo guardar la imagen. Inténtalo de nuevo.');
      }
    }
  }

  /// Quita un diseño propio del inventario y borra su archivo.
  Future<void> _eliminarDiseno(String id) async {
    final diseno = _disenosPropios.where((d) => d.id == id).firstOrNull;
    if (diseno == null) return;
    try {
      await File(diseno.rutaImagen).delete();
    } catch (_) {
      // Si el archivo ya no existe, igual lo quitamos del inventario.
    }
    final actualizados = _disenosPropios.where((d) => d.id != id).toList();
    final prefs = _prefs;
    if (prefs != null) await InventarioDisenos.guardar(prefs, actualizados);
    if (!mounted) return;
    setState(() {
      _disenosPropios = actualizados;
      if (_skin == id) _skin = SkinId.clasico.name;
    });
    if (_skin == SkinId.clasico.name) {
      await prefs?.setString('skin_indicador', SkinId.clasico.name);
    }
  }

  void _mostrarMensaje(
    String texto, {
    String? etiquetaAccion,
    VoidCallback? accion,
    bool esGps = false,
  }) {
    if (!mounted) return;
    setState(() {
      _mensaje = texto;
      _etiquetaAccion = etiquetaAccion;
      _accionAviso = accion;
      _avisoEsGps = esGps;
    });
  }

  /// Espera un momento después de escribir para no consultar en cada letra.
  void _alBuscar(String texto) {
    _busquedaTimer?.cancel();
    // Invalida cualquier respuesta que estuviera en camino: si el usuario
    // escribió otra cosa, un resultado viejo ya no debe pintarse.
    _busquedaGeneracion++;
    setState(() => _resultados = const []);
    if (texto.trim().length < 3) return;
    _busquedaTimer = Timer(
      const Duration(milliseconds: 500),
      () => _ejecutarBusqueda(texto, _busquedaGeneracion),
    );
  }

  Future<void> _ejecutarBusqueda(String texto, int generacion) async {
    setState(() => _buscando = true);
    try {
      final posicion = _posicion;
      final lugares = await ServicioBusqueda().buscar(
        texto,
        lat: posicion?.latitude,
        lon: posicion?.longitude,
      );
      if (!mounted || generacion != _busquedaGeneracion) return;
      final cercanos = posicion == null
          ? lugares
          : lugares
              .where(
                (lugar) =>
                    geo.Geolocator.distanceBetween(
                      posicion.latitude,
                      posicion.longitude,
                      lugar.lat,
                      lugar.lon,
                    ) <=
                _radioBusquedaMetros,
              )
              .toList();
      setState(() {
        _resultados = cercanos;
        _buscando = false;
      });
      if (cercanos.isEmpty && lugares.isNotEmpty) {
        _mostrarMensaje('No hay resultados a menos de 100 km de ti.');
      }
    } catch (error) {
      if (!mounted || generacion != _busquedaGeneracion) return;
      setState(() {
        _resultados = const [];
        _buscando = false;
      });
      _mostrarMensaje(
        error is BusquedaException
            ? error.mensaje
            : 'No se pudo buscar. Inténtalo de nuevo.',
      );
    }
  }

  /// Muestra el lugar elegido en el mapa y guarda la distancia hasta él.
  void _elegirLugar(Lugar lugar) {
    FocusScope.of(context).unfocus();
    setState(() {
      _destino = lugar;
      _resultados = const [];
      _mensaje = null;
      _etiquetaAccion = null;
      _accionAviso = null;
      _buscador.text = lugar.nombre;
    });
    _moverCamara(lugar.lon, lugar.lat);
    _calcularRuta(lugar);
  }

  void _limpiarBusqueda() {
    _busquedaTimer?.cancel();
    _busquedaGeneracion++;
    _rutaGeneracion++;
    setState(() {
      _buscador.clear();
      _resultados = const [];
      _destino = null;
      _ruta = null;
      _calculandoRuta = false;
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

  /// Pide una ruta desde mi posición hasta el destino elegido.
  Future<void> _calcularRuta(Lugar destino) async {
    final posicion = _posicion;
    if (posicion == null) {
      _mostrarMensaje('Esperando tu ubicación para calcular la ruta…');
      return;
    }
    final generacion = ++_rutaGeneracion;
    setState(() {
      _calculandoRuta = true;
      _ruta = null;
      // Si la cámara sigue al usuario, se alejaría de la ruta al caminar.
      _siguiendo = false;
    });
    try {
      final ruta = await ServicioRutas().obtener(
        lonOrigen: posicion.longitude,
        latOrigen: posicion.latitude,
        lonDestino: destino.lon,
        latDestino: destino.lat,
        modo: _opciones.modo,
        idioma: _opciones.idioma,
      );
      if (!mounted || generacion != _rutaGeneracion) return;
      setState(() {
        _ruta = ruta;
        _calculandoRuta = false;
      });
      final centro = centroRuta(ruta);
      await _moverCamara(centro.lon, centro.lat, zoom: zoomParaRuta(ruta));
    } on RutaException catch (error) {
      if (!mounted || generacion != _rutaGeneracion) return;
      setState(() => _calculandoRuta = false);
      _mostrarMensaje(error.mensaje);
    } catch (_) {
      if (!mounted || generacion != _rutaGeneracion) return;
      setState(() => _calculandoRuta = false);
      _mostrarMensaje('No se pudo calcular la ruta. Inténtalo de nuevo.');
    }
  }

  /// Permite elegir modo, estilo e instrucciones, y vuelve a calcular la ruta.
  Future<void> _abrirPersonalizacion() async {
    if (_destino == null) return;
    final elegidas = await showModalBottomSheet<OpcionesRuta>(
      context: context,
      backgroundColor: const Color(0xFF0B1220),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        var actuales = _opciones;
        const colores = <int>[
          0xFF00E5FF,
          0xFFFF3D71,
          0xFF4CAF50,
          0xFFFFC107,
          0xFF7B2BFF,
        ];
        const titulo = TextStyle(
          color: Color(0xFF00E5FF),
          fontSize: 14,
          fontWeight: FontWeight.bold,
        );
        const etiqueta = TextStyle(color: Color(0xFF8FA3BF), fontSize: 12);
        return SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
            child: StatefulBuilder(
              builder: (context, setModal) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Personalizar ruta',
                      style: TextStyle(
                        color: Color(0xFF00E5FF),
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text('Cambia el recorrido y cómo se muestra.', style: etiqueta),
                    const SizedBox(height: 18),
                    const Text('Modo de viaje', style: titulo),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: [
                        for (final modo in ModoRuta.values)
                          ChoiceChip(
                            label: Text(modo.etiqueta),
                            selected: actuales.modo == modo,
                            onSelected: (_) => setModal(() {
                              actuales = actuales.copyWith(modo: modo);
                            }),
                          ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    const Text('Color de la línea', style: titulo),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 12,
                      children: [
                        for (final color in colores)
                          GestureDetector(
                            onTap: () => setModal(() {
                              actuales = actuales.copyWith(color: color);
                            }),
                            child: Container(
                              width: 34,
                              height: 34,
                              decoration: BoxDecoration(
                                color: Color(color),
                                shape: BoxShape.circle,
                                border: actuales.color == color
                                    ? Border.all(color: Colors.white, width: 3)
                                    : null,
                              ),
                              child: actuales.color == color
                                  ? const Icon(
                                      Icons.check,
                                      color: Color(0xFF05070F),
                                      size: 18,
                                    )
                                  : null,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    const Text('Grosor de la línea', style: titulo),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: [
                        for (final grosor in <int>[3, 5, 8])
                          ChoiceChip(
                            label: Text(
                              grosor == 3
                                  ? 'Fino'
                                  : grosor == 5
                                      ? 'Medio'
                                      : 'Grueso',
                            ),
                            selected: actuales.grosor == grosor,
                            onSelected: (_) => setModal(() {
                              actuales = actuales.copyWith(grosor: grosor);
                            }),
                          ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    const Text('Idioma de las instrucciones', style: titulo),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: [
                        for (final idioma in IdiomaInstrucciones.values)
                          ChoiceChip(
                            label: Text(
                              idioma == IdiomaInstrucciones.es
                                  ? 'Español'
                                  : 'English',
                            ),
                            selected: actuales.idioma == idioma,
                            onSelected: (_) => setModal(() {
                              actuales = actuales.copyWith(idioma: idioma);
                            }),
                          ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    const Text('Unidades de distancia', style: titulo),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: [
                        for (final unidades in UnidadesRuta.values)
                          ChoiceChip(
                            label: Text(
                              unidades == UnidadesRuta.metros
                                  ? 'Metros'
                                  : 'Kilómetros',
                            ),
                            selected: actuales.unidades == unidades,
                            onSelected: (_) => setModal(() {
                              actuales = actuales.copyWith(unidades: unidades);
                            }),
                          ),
                      ],
                    ),
                    const SizedBox(height: 22),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: () => Navigator.pop(context, actuales),
                        icon: const Icon(Icons.check),
                        label: const Text('Aplicar y recalcular'),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        );
      },
    );
    if (elegidas == null || !mounted) return;
    setState(() => _opciones = elegidas);
    await _guardarOpciones();
    if (_destino != null) _calcularRuta(_destino!);
  }

  /// Etiqueta pequeña con un dato de la ruta.
  Widget _chipRuta(IconData icono, String texto) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0x3300E5FF),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icono, size: 12, color: const Color(0xFF00E5FF)),
          const SizedBox(width: 4),
          Text(texto, style: const TextStyle(color: Colors.white, fontSize: 11)),
        ],
      ),
    );
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
                '${_distanciaAlDestino(lugar)} · ${lugar.detalle}',
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

  /// Tarjeta con el destino, el resumen de la ruta y las instrucciones.
  Widget _panelDestino() {
    final lugar = _destino!;
    final ruta = _ruta;
    final opciones = _opciones;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xE610182B),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0x66FF3D71)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
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
                onPressed: () {
                  _rutaGeneracion++;
                  setState(() {
                    _destino = null;
                    _ruta = null;
                    _calculandoRuta = false;
                  });
                },
                tooltip: 'Quitar destino',
              ),
            ],
          ),
          if (_calculandoRuta)
            const Padding(
              padding: EdgeInsets.only(top: 10),
              child: LinearProgressIndicator(
                minHeight: 2,
                color: Color(0xFF00E5FF),
                backgroundColor: Color(0x3300E5FF),
              ),
            ),
          if (ruta != null) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                _chipRuta(
                  Icons.straighten,
                  formatoDistancia(ruta.distanciaMetros, opciones.unidades),
                ),
                _chipRuta(
                  Icons.schedule,
                  formatoDuracion(ruta.duracionSegundos, opciones.idioma),
                ),
                _chipRuta(Icons.directions, opciones.modo.etiqueta),
              ],
            ),
            ExpansionTile(
              title: const Text(
                'Instrucciones paso a paso',
                style: TextStyle(color: Colors.white, fontSize: 12),
              ),
              iconColor: const Color(0xFF00E5FF),
              collapsedIconColor: const Color(0xFF00E5FF),
              dense: true,
              tilePadding: EdgeInsets.zero,
              children: [
                SizedBox(
                  height: 150,
                  child: ListView.builder(
                    itemCount: ruta.pasos.length,
                    itemBuilder: (context, i) {
                      final paso = ruta.pasos[i];
                      return ListTile(
                        dense: true,
                        leading: CircleAvatar(
                          radius: 12,
                          backgroundColor: const Color(0xFF00E5FF),
                          child: Text(
                            '${i + 1}',
                            style: const TextStyle(
                              color: Color(0xFF05070F),
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        title: Text(
                          paso.instruccion,
                          style: const TextStyle(color: Colors.white, fontSize: 12),
                        ),
                        subtitle: paso.distanciaMetros > 0
                            ? Text(
                                formatoDistancia(
                                  paso.distanciaMetros,
                                  opciones.unidades,
                                ),
                                style: const TextStyle(
                                  color: Color(0xFF8FA3BF),
                                  fontSize: 10,
                                ),
                              )
                            : null,
                      );
                    },
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _abrirPersonalizacion,
                  icon: const Icon(Icons.tune, size: 16),
                  label: const Text('Personalizar'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FilledButton.icon(
                  onPressed: () => _calcularRuta(lugar),
                  icon: const Icon(Icons.refresh, size: 16),
                  label: const Text('Recalcular'),
                ),
              ),
            ],
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
        layers: [
          if (_proveedor == ProveedorMapaId.local)
            ...MapaLocal.layers(lon: _centroLon, lat: _centroLat),
          if (_ruta != null)
            ...capasRuta(
              _ruta!,
              color: Color(_opciones.color),
              grosor: _opciones.grosor,
            ),
        ],
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
                child: _skinsDisponibles
                    .firstWhere(
                      (s) => s.id == _skin,
                      orElse: () => skins.first,
                    )
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
              child: _Aviso(
                texto: _mensaje!,
                etiquetaAccion: _etiquetaAccion,
                accion: _accionAviso,
              ),
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
          if (_mensaje == null && _resultados.isEmpty && !_buscando)
            Positioned(
              top: 102,
              left: 16,
              child: GestureDetector(
                onTap: _abrirTienda,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xCC10182B),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0x99FFD54F)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.star,
                        size: 14,
                        color: Color(0xFFFFD54F),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        '${_puntos.saldo} puntos',
                        style: const TextStyle(
                          color: Color(0xFFFFD54F),
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Icon(
                        Icons.shopping_cart,
                        size: 13,
                        color: Color(0xFFFFD54F),
                      ),
                    ],
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
          if (_destino != null)
            Positioned(
              left: 76,
              bottom: 24,
              child: FloatingActionButton.small(
                heroTag: 'ruta',
                backgroundColor: const Color(0xFF10182B),
                foregroundColor: const Color(0xFFFF3D71),
                onPressed: _abrirPersonalizacion,
                tooltip: 'Personalizar ruta',
                child: const Icon(Icons.tune),
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
  const _Aviso({required this.texto, this.etiquetaAccion, this.accion});

  final String texto;
  final String? etiquetaAccion;
  final VoidCallback? accion;

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
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(texto),
                if (accion != null && etiquetaAccion != null)
                  TextButton(
                    onPressed: accion,
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFF00E5FF),
                      padding: EdgeInsets.zero,
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text(etiquetaAccion!),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
