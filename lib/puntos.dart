/// Puntos de GAME GPS: se ganan caminando, llegando al destino y por racha diaria.
library;

import 'package:shared_preferences/shared_preferences.dart';

/// Estado de los puntos del jugador. Todas las operaciones devuelven un
/// [Puntos] nuevo para que sea fácil probarlas sin depender de la interfaz.
class Puntos {
  const Puntos({
    this.saldo = 0,
    this.metrosPendientes = 0,
    this.racha = 0,
    this.ultimoDia = '',
    this.entregados = const [],
  });

  factory Puntos.cargar(SharedPreferences prefs) {
    return Puntos(
      saldo: prefs.getInt('puntos_saldo') ?? 0,
      metrosPendientes: prefs.getDouble('puntos_metros') ?? 0,
      racha: prefs.getInt('puntos_racha') ?? 0,
      ultimoDia: prefs.getString('puntos_dia') ?? '',
      entregados: prefs.getStringList('puntos_entregados') ?? const [],
    );
  }

  /// Distancia que recorres con el GPS: 1 punto por cada 100 metros.
  static const double metrosPorPunto = 100;

  /// Puntos por alcanzar un destino y por abrir la app cada día.
  static const int puntosPorLlegada = 15;
  static const int puntosPorDia = 5;
  static const int bonusSemanal = 5;

  final int saldo;
  final double metrosPendientes;
  final int racha;
  final String ultimoDia;
  final List<String> entregados;

  Puntos _copiar({
    int? saldo,
    double? metrosPendientes,
    int? racha,
    String? ultimoDia,
    List<String>? entregados,
  }) {
    return Puntos(
      saldo: saldo ?? this.saldo,
      metrosPendientes: metrosPendientes ?? this.metrosPendientes,
      racha: racha ?? this.racha,
      ultimoDia: ultimoDia ?? this.ultimoDia,
      entregados: entregados ?? this.entregados,
    );
  }

  /// Suma distancia recorrida. El sobrante se guarda para el siguiente punto.
  Puntos sumarDistancia(double metros) {
    if (metros <= 0) return this;
    final total = metrosPendientes + metros;
    final puntos = (total / metrosPorPunto).floor();
    if (puntos == 0) {
      return _copiar(metrosPendientes: total);
    }
    return _copiar(
      saldo: saldo + puntos,
      metrosPendientes: total - puntos * metrosPorPunto,
    );
  }

  /// Resta puntos al comprar un skin. Nunca deja un saldo negativo.
  Puntos gastar(int cantidad) {
    if (cantidad <= 0 || cantidad > saldo) return this;
    return _copiar(saldo: saldo - cantidad);
  }

  /// Cuenta el día actual. Solo entrega puntos una vez por día y da un
  /// bonus extra cada siete días consecutivos.
  Puntos registrarDia(DateTime ahora) {
    final dia = _claveDia(ahora);
    if (dia == ultimoDia) return this;

    final consecutivo =
        _claveDia(ahora.subtract(const Duration(days: 1))) == ultimoDia;
    final nuevaRacha = consecutivo ? racha + 1 : 1;
    final bonos = List<String>.from(entregados);
    var ganado = puntosPorDia;

    if (nuevaRacha % 7 == 0) {
      final clave = 'racha:$nuevaRacha';
      if (!bonos.contains(clave)) {
        bonos.add(clave);
        ganado += bonusSemanal;
      }
    }

    return _copiar(
      saldo: saldo + ganado,
      racha: nuevaRacha,
      ultimoDia: dia,
      entregados: bonos,
    );
  }

  /// Entrega los puntos de llegada una sola vez por destino.
  Puntos registrarLlegada(String claveDestino) {
    final clave = 'destino:$claveDestino';
    if (entregados.contains(clave)) return this;
    return _copiar(
      saldo: saldo + puntosPorLlegada,
      entregados: [...entregados, clave],
    );
  }

  /// Guarda el estado para conservarlo al cerrar la app.
  Future<void> guardar(SharedPreferences prefs) async {
    await prefs.setInt('puntos_saldo', saldo);
    await prefs.setDouble('puntos_metros', metrosPendientes);
    await prefs.setInt('puntos_racha', racha);
    await prefs.setString('puntos_dia', ultimoDia);
    await prefs.setStringList('puntos_entregados', entregados);
  }

  static String _claveDia(DateTime fecha) {
    final anio = fecha.year.toString().padLeft(4, '0');
    final mes = fecha.month.toString().padLeft(2, '0');
    final dia = fecha.day.toString().padLeft(2, '0');
    return '$anio-$mes-$dia';
  }
}
