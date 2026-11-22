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
3. ✅ Ubicación del dispositivo con permiso y seguimiento en tiempo real (el indicador se mueve contigo y la cámara te sigue; puedes desactivarlo con el botón GPS). Si se pierde la señal, la app reintenta automáticamente cada 2, 4, 6 y 8 segundos; tras 4 intentos ofrece un botón **Reintentar**. Si el permiso fue denegado permanentemente, el aviso incluye **Abrir ajustes**.
4. ✅ Barra de búsqueda de lugares reales (OpenStreetMap vía Photon, sin API key): marcador, coordenadas y distancia desde ti.
5. Acercar / alejar.
6. Marcadores personalizados.
7. Ubicaciones favoritas.
8. ✅ Catálogo de skins para el indicador de posición, con opción de subir diseños propios desde la galería (inventario persistente).
9. ✅ Logo propio gamer/GPS.
10. Personalización de colores y apariencia.
11. Rutas y navegación (futuras versiones).

## Modos de mapa

- **CARTO Dark** (predeterminado): calles reales de OpenStreetMap con estilo oscuro, sin API key.
- **Mapa local** (opcional): calles, manzanas, parques y marcador generados en
  `lib/mapa_local.dart` con GeoJSON embebido. No descarga teselas, no usa API key y
  funciona en modo avión. Se alterna con el botón de **capas** de la izquierda.
- **Otras fuentes online**: el selector incluye **OpenStreetMap**, **OSM HOT** y
  **OpenTopoMap**. Todas son gratuitas, sin API key y **ninguna usa Google Maps**. Requieren conexión.

## Búsqueda de lugares

La barra superior consulta **Photon** (`photon.komoot.io`), un geocodificador libre basado en
datos de OpenStreetMap. No necesita API key, no envía tu ubicación y espera 500 ms tras
escribir para no consultar en cada letra. Al elegir un resultado se coloca un marcador
rosa, se abre la cámara y se muestra la distancia en línea recta desde tu posición.
Los resultados se analizan en `lib/busqueda.dart` y se prueban sin internet en
`test/busqueda_test.dart`.

El skin elegido y la fuente de mapa se guardan con `shared_preferences` y se restauran
al reiniciar la app.

## Skins del indicador

El botón violeta 🎨 abre el inventario con seis skins dibujados en `lib/skins.dart`:
Clásico, Caballero Neo (guerrero enmascarado original), Sonda Rover, Brújula, Nave y
Explorador. Todos son vectores generados con `CustomPainter`, sin assets de terceros
ni personajes con copyright. El indicador se ancla a la posición real con `WidgetLayer`.

El botón **➕** del inventario abre la galería y permite agregar tus propias imágenes como
marcadores (`image_picker`). Cada imagen se copia al almacenamiento privado de la app, se
recorta en círculo y se guarda en la lista de diseños propios (`lib/inventario.dart`), junto
con el skin seleccionado. Los diseños propios se pueden borrar con el icono 🗑️ de su tarjeta.
No se suben a ningún servidor: solo viven en tu teléfono.

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
