# GAME GPS

Aplicación de navegación GPS para Android con una interfaz futurista inspirada en videojuegos modernos, construida con Flutter.

> Estado actual: **app Flutter en desarrollo**. Funcionan el mapa interactivo, la ubicación en tiempo real, la búsqueda cercana, el inventario de skins y el cálculo de rutas personalizables.

> Versión actual: **0.1.0** (build 1). Se muestra en la esquina inferior izquierda del mapa.

> Novedad: al abrir la app ahora pide **cuenta** (iniciar sesión / crear cuenta) y muestra un avatar pequeño arriba-derecha con los datos de la cuenta.

## Cuenta y base de datos

La app usa la base de datos SQLite del proyecto (`database/geoquest.db`) a través del API Python `database/api.py`, que sirve el JSON en el puerto 8000 sin dependencias externas. Al iniciar sesión se validan correo y contraseña contra la tabla `interfaz_auth`; el registro crea la cuenta, sus estadísticas y su fila en el panel de administración.

La cuenta verificada se guarda en `SharedPreferences`, así que **no hace falta iniciar sesión cada vez que se abre la app**: arranca directamente en el mapa. Solo se vuelve a pedir la contraseña después de tocar **Cerrar sesión**. Nunca se almacena la contraseña en el teléfono.

### Cuentas listas para usar

| Correo | Contraseña | Perfil |
| --- | --- | --- |
| `emmanuel@gamegps.local` | `gamegps123` | Cuenta personal (Emmanuel) |
| `viajero@geoquest.local` | `123456` | Viajero de demostración (320 puntos) |
| `admin@geoquest.local` | `admin123` | Administrador |

La pantalla de acceso tiene un botón **Usar cuenta de demostración** que rellena la segunda automáticamente.

### Encender el API antes de abrir la app

```bash
python3 database/api.py          # http://localhost:8000
```

Con el celular conectado por USB/WSL, redirige el puerto para que el teléfono alcance el API:

```bash
adb reverse tcp:8000 tcp:8000
```

Si usas WiFi en lugar de USB, toca **Servidor** en la pantalla de acceso y escribe la IP del ordenador, por ejemplo `http://192.168.1.10:8000`. La dirección queda recordada.

> En esta beta las contraseñas se guardan en texto plano en la base de datos de demostración y el progreso de cada partida (puntos, skins, retos) sigue en el teléfono. Para producción habría que hashear contraseñas y sincronizar el progreso.

## Stack previsto

| Capa | Tecnología |
|---|---|
| App | Flutter 3.50.0 / Dart 3.14.0 |
| Mapas | MapLibre |
| Datos geográficos | OpenStreetMap |
| Backend | SQLite (`database/geoquest.db`) + API Python (`database/api.py`) |
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
10. ✅ Estilos vectoriales propios: GAME GPS Custom (cian/esmeralda) y cuatro paletas Hollow Knight (Noche, Niebla, Cristal y Carmesí), con iconos de juego en los puntos de interés.
11. ✅ Cálculo de rutas desde tu posición con OSRM/OpenStreetMap, personalizables (modo, color, grosor, idioma y unidades). La navegación guiada con voz queda para futuras versiones.
12. ✅ Puntos por distancia real recorrida, por llegar al destino y por racha diaria.
13. ✅ Tienda de skins: se compran con puntos y pasan a tu inventario.
14. ✅ Retos diarios, de distancia total y de destinos, con progreso y puntos automáticos.
15. ✅ Rastro del recorrido real detrás del indicador y animación al llegar al destino.

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

Los saldos, las compras, la racha y el progreso de la partida se guardan en tu teléfono (SharedPreferences); la cuenta y el saldo del perfil se consultan en la base de datos SQLite del proyecto.

La tienda incluye 8 diseños de [game-icons.net](https://game-icons.net/) bajo licencia
**CC BY 3.0**: Dragón (Faithtoken), Androide clásico y Astronauta (Lorc), Ninja (DarkZaitzev),
Medusa y Rey (Cathelineau), Mecha (Delapouite) y Cohete (Sbed). Los PNG se teñen con el color
de cada skin dentro de la app.

## Indicador, rastro y llegada

El indicador sigue tu GPS en tiempo real y deja detrás una línea cian con el
**recorrido real** que haces (se guardan hasta 600 puntos y solo se añade uno
cuando te mueves al menos 2 m). Al elegir un destino, el rastro empieza de cero
desde tu posición actual; al borrar la búsqueda también se limpia.
Al llegar a menos de 30 m del destino aparece una animación de ondas y destellos
con el texto **¡Llegaste!** (dura 1,7 s y no bloquea el mapa).

## Modos de mapa

- **Propio · calles reales offline** (predeterminado): el APK incluye **2.397 teselas reales
  de OpenStreetMap** en `assets/tiles` (área metropolitana de Medellín y corredor oeste,
  zooms 14–17). `lib/teselas_locales.dart` abre un servidor en `127.0.0.1` que se las entrega
  a MapLibre, así que el mapa muestra calles, nombres y números **sin internet y sin clave**.
  Las teselas se dibujan sin desvanecido (no parpadean); el botón 🌙 alterna un tema nocturno
  que mantiene las calles reales. Si te alejas de la zona cubierta, el servidor pide la tesela
  a OpenStreetMap, la guarda en caché (memoria + disco) y la reenvía. Datos © OpenStreetMap.
- **GPS · Calles reales**: calles de OpenStreetMap con espejo de respaldo y **acabado de
  navegación**: tinete azul noche, contraste reforzado y teselas sin desvanecido (no
  parpadean). El chip superior muestra el distintivo **GPS** con el rumbo, y el botón 🧭
  (junto al de seguir posición) gira el mapa en la dirección del viaje como un GPS real;
  al iniciar una ruta se activa automáticamente y al detenerla vuelve al norte. No depende
  de glifos ni sprites remotos. Datos © OpenStreetMap.
- **Hallownest · Noche**, **Niebla**, **Cristal** y **Carmesí**: cuatro paletas inspiradas en
  Hollow Knight (`lib/estilos_hollow.dart`). Usan **teselas de OpenStreetMap oscurecidas**
  con una capa fina de tinte del reino y los seis iconos propios sobre los puntos de interés.
  Se retiraron las 111 capas vectoriales y el texto remoto: apagaban las calles y, si los
  glifos fallaban, el documento completo era rechazado y el mapa quedaba vacío.
- **GAME GPS Custom**: estilo vectorial propio (`lib/estilo_custom.dart`) con teselas de
  **OpenFreeMap** y la paleta de la app aplicada a 114 capas con aspecto de GPS: vías
  jerárquicas (autopistas esmeralda, arterias cian, calles secundarias azul claro),
  halo luminoso bajo las vías principales, edificios perfilados y nombres de calles en
  blanco con contorno oscuro. Incluye flechas de sentido único y escudos de ruta.
  Gratis, sin registro. Datos © OpenStreetMap, estilo © OpenFreeMap/OpenMapTiles (MIT).
  Requiere conexión.
- Las fuentes anteriores se migran automáticamente al mapa propio offline para que siempre
  abras sobre un mapa con calles y nombres. **Ninguna fuente usa Google Maps** y todas son
  gratuitas y sin registro.

> Nota: los servidores raster de CARTO (`rastertiles/voyager` y `dark_all`) estampan
> **«API KEY REQUIRED»** en las teselas cuando no hay clave, con estado HTTP 200. Por eso
> **ningún estilo usa CARTO**: las calles viven en teselas embebidas de OpenStreetMap, en
> OpenStreetMap en línea o en OpenFreeMap. No hay Google Maps ni claves en la app.

### Iconos de juego

Los puntos de interés ya no muestran el símbolo genérico del mapa. Se dibujan en Dart
(`lib/iconos_hollow.dart`) y se registran como imágenes del estilo MapLibre:

| Icono | Sustituye a | Uso |
| --- | --- | --- |
| **Sanctuario** | hospital / clínica | cruz de bordes afilados con núcleo luminoso |
| **Manjar** | restaurantes, cafés | seta con sombrero decorado |
| **Refugio** | hoteles, hostales | casa tejada |
| **Tesoro** | tiendas, bancos | diamante con brillo interior |
| **Poción** | farmacias, combustible | frasco con líquido |
| **Runa** | museos, miradores, escuelas | ojo con espiral |

La asignación se hace por clase OSM con una expresión `icon-image` dentro del estilo.

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

El parser de maniobras acepta la ubicación tanto como `[longitud, latitud]` —el formato
geojson que envía OSRM— como en el objeto `{longitude, latitude}`. Además, los movimientos
de cámara están aislados del cálculo: si el GPS cancela una animación, la ruta ya calculada
se dibuja igualmente. Ambos casos están cubiertos en `test/rutas_test.dart`.

### Navegación guiada (HUD direccional)

Al calcular la ruta entra en **modo navegación**, como un GPS: la cámara sigue al viajero con
zoom de calle y aparece un HUD (`lib/hud_navegacion.dart`) con:

- **Próxima maniobra:** flecha grande, distancia hasta el giro y nombre de la calle.
- **Siguiente maniobra** ya visible debajo, con su distancia.
- **Distancia y tiempo restantes**, hora estimada de llegada y barra de progreso.
- **Velocidad** en km/h y **rumbo** con letra cardinal (N, NE, E…), girando con el móvil.
- **Flechas sobre la línea de la ruta** para ver el sentido del recorrido de un vistazo.
- Botones para **volver a encuadrar** y **terminar la navegación**.

La posición sobre la ruta se calcula proyectando el GPS sobre la geometría
(`progresoRuta` en `lib/rutas.dart`), así que el avance no salta cuando la señal se desvía
unos metros de la calle. El HUD se prueba en `test/navegacion_test.dart`.

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
