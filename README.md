# GAME GPS

Aplicación de navegación GPS para Android con una interfaz futurista inspirada en videojuegos modernos, construida con Flutter.

> Estado actual: **app Flutter en desarrollo**. Ya funcionan el mapa interactivo oscuro (1) y la ubicación del dispositivo con permiso (2).

> Versión actual: **0.1.0** (build 1). Se muestra en la esquina inferior izquierda del mapa.

## Stack previsto

| Capa | Tecnología |
|---|---|
| App | Flutter 3.50.0 / Dart 3.14.0 |
| Mapas | MapLibre |
| Datos geográficos | OpenStreetMap |
| Backend (futuro) | Supabase + PostgreSQL |
| Control de versiones | Git + GitHub |

## Funciones previstas

1. ✅ Mapa interactivo.
2. ✅ Mapa local propio (sin internet, sin API key y sin permisos).
3. ✅ Ubicación del dispositivo con permiso y seguimiento en tiempo real (el indicador se mueve contigo y la cámara te sigue; puedes desactivarlo con el botón GPS).
4. Acercar / alejar.
5. Marcadores personalizados.
6. Ubicaciones favoritas.
7. ✅ Catálogo de skins para el indicador de posición.
8. ✅ Logo propio gamer/GPS.
9. Personalización de colores y apariencia.
10. Rutas y navegación (futuras versiones).

## Modos de mapa

- **Mapa local** (predeterminado): calles, manzanas, parques y marcador generados en
  `lib/mapa_local.dart` con GeoJSON embebido. No descarga teselas, no usa API key y
  funciona en modo avión. Se alterna con el botón ⚡ / 🌐 de la pantalla.
- **Fuentes online**: el botón de **capas** de la izquierda abre un selector con **CARTO Dark**,
  **OpenStreetMap**, **OSM HOT** y **OpenTopoMap**. Todas son gratuitas, sin API key y
  **ninguna usa Google Maps**. Requieren conexión.

El skin elegido y la fuente de mapa se guardan con `shared_preferences` y se restauran
al reiniciar la app.

## Skins del indicador

El botón violeta 🎨 abre un catálogo con seis skins dibujados en `lib/skins.dart`:
Clásico, Caballero Neo (guerrero enmascarado original), Sonda Rover, Brújula, Nave y
Explorador. Todos son vectores generados con `CustomPainter`, sin assets de terceros
ni personajes con copyright. El indicador se ancla a la posición real con `WidgetLayer`.

## Logo

El icono de launcher se genera con `python3 tools/generate_assets.py` (PNG puro, sin
dependencias) y se copia a las carpetas `mipmap-*`. La misma imagen se usa dentro de la
app en `assets/logo/app_icon.png`.

## Entorno verificado

- Flutter 3.50.0 (stable), Dart 3.14.0.
- JDK Temurin 17.0.21.1.
- Android SDK Platform 36, Build-Tools 36.0.0, Platform-Tools 37.0.1.
- Todas las licencias de Android aceptadas.
- Telemetría de Flutter desactivada.

Los detalles están en [`docs/ENTORNO.md`](docs/ENTORNO.md).

## Privacidad

La ubicación del usuario solo se solicitará con permiso explícito y se usará en el dispositivo. No se almacenarán coordenadas personales en el repositorio ni se enviarán a servicios externos sin consentimiento.

## Recursos

- [`game-gps-mockup.svg`](game-gps-mockup.svg): mockup visual de la interfaz.
