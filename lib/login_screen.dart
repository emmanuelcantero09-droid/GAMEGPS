/// Pantalla de acceso/registro de GAME GPS contra la base de datos GeoQuest.
library;

import 'package:material_ui/material_ui.dart';

import 'auth.dart';
import 'main.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  static const Color _cyan = Color(0xFF00E5FF);
  static const Color _morado = Color(0xFF7B2BFF);
  static const Color _panel = Color(0xFF10182B);

  final TextEditingController _correo = TextEditingController();
  final TextEditingController _contrasena = TextEditingController();
  final TextEditingController _nombre = TextEditingController();

  bool _registrando = false;
  bool _cargando = false;
  bool _verContrasena = false;
  String? _error;
  String _urlBase = urlApiPorDefecto;

  @override
  void initState() {
    super.initState();
    _cargarPreferencias();
  }

  @override
  void dispose() {
    _correo.dispose();
    _contrasena.dispose();
    _nombre.dispose();
    super.dispose();
  }

  Future<void> _cargarPreferencias() async {
    final url = await AuthServicio.leerUrlBase();
    final correo = await AuthServicio.leerUltimoCorreo();
    if (!mounted) return;
    setState(() {
      _urlBase = url;
      _correo.text = correo;
    });
  }

  void _usarCuentaDemo() {
    setState(() {
      _registrando = false;
      _error = null;
      _correo.text = 'viajero@geoquest.local';
      _contrasena.text = '123456';
    });
  }

  Future<void> _editarServidor() async {
    final control = TextEditingController(text: _urlBase);
    final resultado = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _panel,
        title: const Text(
          'Servidor de la base de datos',
          style: TextStyle(color: _cyan),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Dirección del servidor de cuentas de GAME GPS. '
              'Déjala como está para usar el servidor local del proyecto.',
              style: TextStyle(color: Color(0xFF8FA3BF), fontSize: 12),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: control,
              autofocus: true,
              style: const TextStyle(color: Colors.white),
              decoration: _decoracion('http://127.0.0.1:8000'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, control.text),
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
    control.dispose();
    if (resultado == null || !mounted) return;
    await AuthServicio.guardarUrlBase(resultado);
    final normalizada = await AuthServicio.leerUrlBase();
    if (!mounted) return;
    setState(() => _urlBase = normalizada);
  }

  Future<void> _enviar() async {
    final correo = _correo.text.trim().toLowerCase();
    final contrasena = _contrasena.text;
    final nombre = _nombre.text.trim();

    if (_registrando && nombre.isEmpty) {
      setState(() => _error = 'Escribe tu nombre de viajero.');
      return;
    }
    if (!correo.contains('@') || !correo.contains('.')) {
      setState(() => _error = 'Escribe un correo válido.');
      return;
    }
    if (contrasena.length < 6) {
      setState(
        () => _error = 'La contraseña debe tener al menos 6 caracteres.',
      );
      return;
    }

    setState(() {
      _cargando = true;
      _error = null;
    });
    final servicio = AuthServicio(urlBase: _urlBase);
    try {
      final usuario = _registrando
          ? await servicio.registrar(
              nombre: nombre,
              correo: correo,
              contrasena: contrasena,
            )
          : await servicio.entrar(correo: correo, contrasena: contrasena);
      await AuthServicio.guardarUltimoCorreo(correo);
      await AuthServicio.guardarSesion(usuario);
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => MapScreen(usuario: usuario)),
      );
    } on AuthExcepcion catch (error) {
      if (mounted) setState(() => _error = error.mensaje);
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Error inesperado. Inténtalo de nuevo.');
      }
    } finally {
      servicio.dispose();
      if (mounted) setState(() => _cargando = false);
    }
  }

  InputDecoration _decoracion(String etiqueta) => InputDecoration(
    labelText: etiqueta,
    labelStyle: const TextStyle(color: Color(0xFF8FA3BF)),
    filled: true,
    fillColor: _panel,
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Color(0x6600E5FF)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: _cyan),
    ),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF05070F), Color(0xFF0B1330)],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Image.asset(
                      'assets/logo/app_icon.png',
                      width: 88,
                      height: 88,
                    ),
                    const SizedBox(height: 18),
                    const Text(
                      'GAME GPS',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: _cyan,
                        fontSize: 32,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _registrando
                          ? 'CREA TU CUENTA DE VIAJERO'
                          : 'ENTRA EN TU CUENTA DE VIAJERO',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Color(0xFF8FA3BF),
                        fontSize: 12,
                        letterSpacing: 1.4,
                      ),
                    ),
                    const SizedBox(height: 28),
                    Row(
                      children: [
                        Expanded(
                          child: _pestana('Iniciar sesión', !_registrando, () {
                            setState(() {
                              _registrando = false;
                              _error = null;
                            });
                          }),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _pestana('Crear cuenta', _registrando, () {
                            setState(() {
                              _registrando = true;
                              _error = null;
                            });
                          }),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    if (_registrando) ...[
                      TextField(
                        controller: _nombre,
                        textInputAction: TextInputAction.next,
                        style: const TextStyle(color: Colors.white),
                        decoration: _decoracion('Nombre de viajero'),
                      ),
                      const SizedBox(height: 14),
                    ],
                    TextField(
                      controller: _correo,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      style: const TextStyle(color: Colors.white),
                      decoration: _decoracion('Correo electrónico'),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: _contrasena,
                      obscureText: !_verContrasena,
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) => _cargando ? null : _enviar(),
                      style: const TextStyle(color: Colors.white),
                      decoration: _decoracion('Contraseña').copyWith(
                        suffixIcon: IconButton(
                          icon: Icon(
                            _verContrasena
                                ? Icons.visibility_off
                                : Icons.visibility,
                            color: const Color(0xFF8FA3BF),
                          ),
                          onPressed: () =>
                              setState(() => _verContrasena = !_verContrasena),
                        ),
                      ),
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: 14),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0x33FF3D71),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0x99FF3D71)),
                        ),
                        child: Text(
                          _error!,
                          style: const TextStyle(color: Color(0xFFFFCDD5)),
                        ),
                      ),
                    ],
                    const SizedBox(height: 22),
                    FilledButton(
                      onPressed: _cargando ? null : _enviar,
                      style: FilledButton.styleFrom(
                        backgroundColor: _morado,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _cargando
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              _registrando ? 'CREAR CUENTA' : 'ENTRAR',
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1,
                              ),
                            ),
                    ),
                    const SizedBox(height: 10),
                    TextButton(
                      onPressed: _usarCuentaDemo,
                      child: const Text(
                        'Usar cuenta de demostración',
                        style: TextStyle(color: _cyan, fontSize: 12),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextButton.icon(
                      onPressed: _editarServidor,
                      icon: const Icon(Icons.settings_ethernet, size: 15),
                      label: Text(
                        'Servidor: $_urlBase',
                        style: const TextStyle(
                          color: Color(0xFF8FA3BF),
                          fontSize: 11,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'GAME GPS v0.1.0 · beta · datos © OpenStreetMap',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Color(0xFF54657F), fontSize: 10),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _pestana(String texto, bool activa, VoidCallback alTocar) {
    return OutlinedButton(
      onPressed: alTocar,
      style: OutlinedButton.styleFrom(
        foregroundColor: activa ? _cyan : const Color(0xFF8FA3BF),
        side: BorderSide(color: activa ? _cyan : const Color(0x336080A0)),
        backgroundColor: activa ? const Color(0x3310B5E5) : Colors.transparent,
        padding: const EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      child: Text(texto, style: const TextStyle(fontSize: 12)),
    );
  }
}
