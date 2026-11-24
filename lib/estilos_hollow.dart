/// Estilos vectoriales inspirados en Hollow Knight: obsidiana, piedra,
/// hueso y acentos de luz. Se construyen recoloreando el mapa propio de
/// OpenFreeMap, así que conservan calles, agua, edificios y etiquetas.
library;

import 'dart:convert';

import 'estilo_custom.dart';

/// Paleta de un reino. Todos los valores son hexadecimales `#RRGGBB`.
class PaletaHollow {
  const PaletaHollow({
    required this.id,
    required this.nombre,
    required this.detalle,
    required this.fondo,
    required this.superficie,
    required this.superficie2,
    required this.borde,
    required this.calleBorde,
    required this.calleBorde2,
    required this.calle,
    required this.calleClara,
    required this.texto,
    required this.textoClaro,
    required this.acento,
    required this.acentoClaro,
    required this.agua,
    required this.aguaClara,
    required this.parque,
    required this.parqueClaro,
  });

  final String id;
  final String nombre;
  final String detalle;
  final String fondo;
  final String superficie;
  final String superficie2;
  final String borde;
  final String calleBorde;
  final String calleBorde2;
  final String calle;
  final String calleClara;
  final String texto;
  final String textoClaro;
  final String acento;
  final String acentoClaro;
  final String agua;
  final String aguaClara;
  final String parque;
  final String parqueClaro;
}

/// Los cuatro reinos disponibles en el selector de fuentes.
const List<PaletaHollow> paletasHollow = [
  PaletaHollow(
    id: 'hollow_noche',
    nombre: 'Hallownest · Noche',
    detalle: 'Obsidiana y hueso · acento carmesí',
    fondo: '#080910',
    superficie: '#141622',
    superficie2: '#1D2030',
    borde: '#2B2E3F',
    calleBorde: '#3A3E52',
    calleBorde2: '#4E5268',
    calle: '#898B96',
    calleClara: '#CFCCBE',
    texto: '#9A9AA2',
    textoClaro: '#E8E3D4',
    acento: '#C8404A',
    acentoClaro: '#F07078',
    agua: '#16243C',
    aguaClara: '#3F6E94',
    parque: '#1B3329',
    parqueClaro: '#2E5A43',
  ),
  PaletaHollow(
    id: 'hollow_niebla',
    nombre: 'Hallownest · Niebla',
    detalle: 'Verde de brezo y piedra húmeda',
    fondo: '#0A0F0E',
    superficie: '#151E1B',
    superficie2: '#1D2925',
    borde: '#2C3B35',
    calleBorde: '#3E514A',
    calleBorde2: '#557068',
    calle: '#8FA79B',
    calleClara: '#D4DED3',
    texto: '#9FB5A9',
    textoClaro: '#E9EFE4',
    acento: '#7FCFA8',
    acentoClaro: '#B6F0CE',
    agua: '#173632',
    aguaClara: '#4C8C80',
    parque: '#234537',
    parqueClaro: '#3C6B50',
  ),
  PaletaHollow(
    id: 'hollow_cristal',
    nombre: 'Hallownest · Cristal',
    detalle: 'Azul de cristal y brillo polar',
    fondo: '#060B14',
    superficie: '#101A28',
    superficie2: '#152438',
    borde: '#223B54',
    calleBorde: '#33506C',
    calleBorde2: '#4B7192',
    calle: '#8FAEC4',
    calleClara: '#D8EAF2',
    texto: '#A2BDD0',
    textoClaro: '#ECF6FA',
    acento: '#58C8E0',
    acentoClaro: '#9BE8F4',
    agua: '#12314C',
    aguaClara: '#3E82AC',
    parque: '#17363C',
    parqueClaro: '#2B5C60',
  ),
  PaletaHollow(
    id: 'hollow_carmesi',
    nombre: 'Hallownest · Carmesí',
    detalle: 'Rojo de sangre y rosa de luna',
    fondo: '#0B070B',
    superficie: '#1A1018',
    superficie2: '#251720',
    borde: '#38212D',
    calleBorde: '#4E2E3D',
    calleBorde2: '#6C4152',
    calle: '#A9808D',
    calleClara: '#E8CDD2',
    texto: '#B5949E',
    textoClaro: '#F5E4E7',
    acento: '#E35C86',
    acentoClaro: '#FF9FBC',
    agua: '#2A1626',
    aguaClara: '#6C3E5B',
    parque: '#2C1E2C',
    parqueClaro: '#4B3045',
  ),
];

/// Clases OSM que se dibujan con un icono propio en lugar del genérico.
const Map<String, String> iconosPorClasePoi = {
  'hospital': 'hollow_hospital',
  'clinic': 'hollow_hospital',
  'doctors': 'hollow_hospital',
  'pharmacy': 'hollow_pocion',
  'restaurant': 'hollow_comida',
  'cafe': 'hollow_comida',
  'fast_food': 'hollow_comida',
  'bar': 'hollow_comida',
  'pub': 'hollow_comida',
  'hotel': 'hollow_descanso',
  'hostel': 'hollow_descanso',
  'guest_house': 'hollow_descanso',
  'bank': 'hollow_tesoro',
  'atm': 'hollow_tesoro',
  'shop': 'hollow_tesoro',
  'supermarket': 'hollow_tesoro',
  'fuel': 'hollow_pocion',
  'museum': 'hollow_runa',
  'attraction': 'hollow_runa',
  'viewpoint': 'hollow_runa',
  'school': 'hollow_runa',
  'university': 'hollow_runa',
};

final Map<String, String> _estilosPorPaleta = {};

/// Devuelve el documento MapLibre para una paleta, ya con los iconos propios.
String estiloHollow(PaletaHollow paleta) {
  final guardado = _estilosPorPaleta[paleta.id];
  if (guardado != null) return guardado;

  final original = jsonDecode(estiloGameGps) as Map<String, dynamic>;
  final capasOriginales = original['layers'] as List<dynamic>;

  // Las teselas raster de OpenStreetMap traen calles, nombres y números sin
  // clave ni marchamo. CARTO dejó de servirlas gratis: ahora estampa
  // "API KEY REQUIRED" en cada tesela, así que ya no se usa. De las 111 capas
  // vectoriales solo conservamos los puntos de interés para los iconos propios.
  final simbolos = <Map<String, dynamic>>[];
  for (final crudo in capasOriginales) {
    if (crudo is! Map<String, dynamic>) continue;
    final id = crudo['id'].toString();
    if (crudo['type'] != 'symbol' || !id.startsWith('poi_')) continue;
    final capa = Map<String, dynamic>.from(crudo);
    _recolor(capa, paleta);
    final layout = Map<String, dynamic>.from(
      (capa['layout'] as Map?) ?? const <dynamic, dynamic>{},
    );
    final paint = Map<String, dynamic>.from(
      (capa['paint'] as Map?) ?? const <dynamic, dynamic>{},
    );
    layout
      ..remove('text-field')
      ..remove('text-font')
      ..remove('text-offset')
      ..remove('text-anchor')
      ..['icon-image'] = _expresionIconos()
      ..['icon-size'] = 0.9
      ..['icon-allow-overlap'] = true;
    paint
      ..remove('text-halo-color')
      ..remove('text-halo-width')
      ..remove('text-halo-blur')
      ..remove('text-color');
    capa['layout'] = layout;
    capa['paint'] = paint;
    simbolos.add(capa);
  }

  final documento = <String, dynamic>{
    'version': 8,
    'name': 'Hallownest · ${paleta.nombre}',
    'sources': {
      'osm_base': {
        'type': 'raster',
        'tiles': [
          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          'https://a.tile.openstreetmap.fr/osmfr/{z}/{x}/{y}.png',
        ],
        'tileSize': 256,
        'attribution': '© OpenStreetMap contributors',
      },
      'openmaptiles':
          (original['sources'] as Map<String, dynamic>)['openmaptiles'],
    },
    'layers': [
      <String, dynamic>{
        'id': 'base_detalle',
        'type': 'raster',
        'source': 'osm_base',
        // Oscurecemos la tesela clara de OSM para conservar el aspecto nocturno.
        'paint': {
          'raster-opacity': 1.0,
          'raster-brightness-max': 0.28,
          'raster-brightness-min': 0.0,
          'raster-saturation': -0.7,
          'raster-contrast': 0.12,
        },
      },
      <String, dynamic>{
        'id': 'tinete_reino',
        'type': 'background',
        'paint': {'background-color': paleta.fondo, 'background-opacity': 0.16},
      },
      ...simbolos,
    ],
  };

  final texto = jsonEncode(documento);
  _estilosPorPaleta[paleta.id] = texto;
  return texto;
}

/// Sustituye los colores del estilo base por los de la paleta elegida.
void _recolor(Object? nodo, PaletaHollow paleta) {
  if (nodo is Map) {
    for (final entrada in nodo.entries.toList()) {
      final valor = entrada.value;
      if (valor is String && valor.startsWith('#')) {
        nodo[entrada.key] = _traducirColor(valor.toUpperCase(), paleta);
      } else {
        _recolor(valor, paleta);
      }
    }
  } else if (nodo is List) {
    for (var i = 0; i < nodo.length; i++) {
      final valor = nodo[i];
      if (valor is String && valor.startsWith('#')) {
        nodo[i] = _traducirColor(valor.toUpperCase(), paleta);
      } else {
        _recolor(valor, paleta);
      }
    }
  }
}

String _traducirColor(String color, PaletaHollow p) {
  switch (color) {
    case '#060A14':
      return p.fondo;
    case '#0B1424':
    case '#0E1626':
      return p.superficie;
    case '#16243C':
    case '#1A2740':
    case '#1C2340':
      return p.superficie2;
    case '#2A3F5C':
    case '#33445E':
      return p.borde;
    case '#3D506B':
      return p.calleBorde;
    case '#5B7391':
      return p.calleBorde2;
    case '#93A9C4':
      return p.calle;
    case '#9FB3CC':
      return p.texto;
    case '#DCE9FA':
      return p.calleClara;
    case '#E6F1FF':
    case '#FDE':
      return p.textoClaro;
    case '#22D3EE':
    case '#2FE39A':
      return p.acento;
    case '#67E8F9':
      return p.acentoClaro;
    case '#1E6FA8':
    case '#2B5A78':
    case '#123C63':
    case '#367CA0':
      return p.agua;
    case '#4FA3D1':
    case '#5EC8FF':
    case '#9FD8E8':
      return p.aguaClara;
    case '#16432F':
    case '#173A2B':
    case '#1F5C3F':
      return p.parque;
    case '#2A7A54':
      return p.parqueClaro;
    default:
      return color;
  }
}

List<Object?> _expresionIconos() {
  final expr = <Object?>[
    'match',
    [
      'coalesce',
      ['get', 'subclass'],
      ['get', 'class'],
    ],
  ];
  iconosPorClasePoi.forEach((clase, icono) {
    expr
      ..add(clase)
      ..add(icono);
  });
  expr.add('hollow_runa');
  return expr;
}
