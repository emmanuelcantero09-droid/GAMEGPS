# GAME GPS

Aplicación de navegación GPS para Android con una interfaz futurista inspirada en videojuegos modernos, construida con Flutter.

> Estado actual: **app Flutter en desarrollo**. Funcionan el mapa interactivo, la ubicación en tiempo real, la búsqueda cercana, el inventario de skins y el cálculo de rutas personalizables.

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
3. ✅ Ubicación del dispositivo con permiso y seguimiento en tiempo real (el indicador se mueve contigo y la cámara te sigue; puedes desactivarlo con el botón GPS). El flujo continuo no usa `timeLimit` y actualiza cada 2 s aunque estés quieto, para que no aparezca un aviso falso de "señal perdida". Si hay un error real, la app reintenta automáticamente cada 2, 4, 6 y 8 segundos; tras 4 intentos ofrece un botón **Reintentar**. Si el permiso fue denegado permanentemente, el aviso incluye **Abrir ajustes**.
4. ✅ Barra de búsqueda de lugares reales (OpenStreetMap vía Photon, sin API key): marcador, coordenadas y distancia desde ti. Al elegir un resultado se calcula automáticamente cómo llegar.
5. Acercar / alejar.
6. Marcadores personalizados.
7. Ubicaciones favoritas.
8. ✅ Catálogo de skins para el indicador de posición, con opción de subir diseños propios desde la galería (inventario persistente).
9. ✅ Logo propio gamer/GPS.
10. ✅ Estilo de mapa propio con colores de GAME GPS (fondo azul noche, caminos cian, zonas verdes esmeralda).
11. ✅ Cálculo de rutas desde tu posición con OSRM/OpenStreetMap, personalizables (modo, color, grosor, idioma y unidades). La navegación guiada con voz queda para futuras versiones.
12. ✅ Puntos por distancia real recorrida, por llegar al destino y por racha diaria.
13. ✅ Tienda de skins: se compran con puntos y pasan a tu inventario.
14. ✅ Retos diarios, de distancia total y de destinos, con progreso y puntos automáticos.

## Puntos, retos y tienda

Tocando el contador **⭐ puntos 🛒** (esquina superior izquierda) se abre la hoja con
dos pestañas: **Tienda** y **Retos**. Los retos se cobran solos al alcanzar la meta.

- **1 punto cada 100 m** caminados o corridos. Se descartan saltos bruscos del GPS
  (más de 100 m entre lecturas) para no sumar distancia falsa.
- **15 puntos** por llegar a un destino (una sola vez por lugar, a menos de 30 m).
- **5 puntos diarios** por abrir la app, con **5 extra cada 7 días consecutivos**.

**Retos diarios** (se reinician cada día): caminar 500 m (+20), llegar a 1 destino (+10)
y buscar 3 lugares (+10).

**Metas totales** (una sola vez): 1/5/10 km recorridos (+15/+30/+50) y
3/10/25 destinos distintos (+20/+50/+100).

Los saldos, las compras, la racha y el progreso se guardan solo en tu teléfono.

La tienda incluye 8 diseños de [game-icons.net](https://game-icons.net/) bajo licencia
**CC BY 3.0**: Dragón (Faithtoken), Androide clásico y Astronauta (Lorc), Ninja (DarkZaitzev),
Medusa y Rey (Cathelineau), Mecha (Delapouite) y Cohete (Sbed). Los PNG se teñen con el color
de cada skin dentro de la app.

## Modos de mapa

- **GAME GPS Custom**: estilo vectorial propio (`lib/estilo_custom.dart`) con teselas de
  **OpenFreeMap** y la paleta de la app aplicada a 111 capas: caminos cian, parques verdes,
  agua azul, edificios gris azulado y etiquetas claras. Gratis, sin key ni registro.
  Datos © OpenStreetMap, estilo © OpenFreeMap/OpenMapTiles (MIT). Requiere conexión.
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

## Cómo llegar

Al tocar un resultado de la búsqueda se calcula una ruta desde tu posición hasta ese punto. Se usa
**OSRM** sin API key: el servidor público para coche y los servidores de OpenStreetMap para ir a pie
o en bicicleta (`lib/rutas.dart`). La línea se dibuja sobre cualquier fuente de mapa
(`lib/capa_ruta.dart`) y la cámara encuadra el recorrido completo.

El botón **Personalizar** del panel del destino (o el icono 🎚️ junto a las capas) abre un panel para elegir:

- **Modo de viaje:** coche, a pie o bicicleta.
- **Color y grosor** de la línea dibujada.
- **Idioma** de las instrucciones (español o inglés).
- **Unidades** de distancia (metros o kilómetros).

Las preferencias se guardan en el teléfono y la ruta se recalcula al aplicarlas. El panel muestra
distancia total, duración estimada y las instrucciones paso a paso. Las respuestas antiguas se
descartan mediante un número de generación, igual que en la búsqueda, para que una ruta anterior
no sobrescriba la última.

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

Para compilar: `flutter build apk --debug` o `flutter build apk --release`. El release usa
`android/app/proguard-rules.pro` para ignorar las referencias a Google Play Services de
`geolocator`, que nunca se ejecutan porque la app usa el `LocationManager` nativo y excluye GMS.

## Privacidad

La ubicación del usuario solo se solicita con permiso explícito y se usa en el dispositivo. No se almacenan coordenadas personales en el repositorio ni se guarda un histórico de viajes. Para buscar lugares y calcular rutas se envían coordenadas puntuales a Photon y a OSRM/OpenStreetMap (sin cuenta ni API key). Los diseños propios y las preferencias solo viven en tu teléfono.

## Recursos

- [`game-gps-mockup.svg`](game-gps-mockup.svg): mockup visual de la interfaz.
