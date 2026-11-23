# Guion de presentación — GAME GPS (8 diapositivas)

**Cómo usarlo:** no lo memorices. Lee una vez antes de entrar, pon el archivo al lado y mira la diapositiva mientras hablas. Si te quedas en blanco, busca la frase en negrita diapositiva por diapositiva y sigue desde ahí.

**Duración total:** entre 5 y 7 minutos. Habla despacio y haz pausas.

---

## Diapositiva 1 — Portada (20 segundos)

> Buenos días. Les presento **GAME GPS**, una aplicación de navegación con mecánicas de videojuego. La idea es sencilla: que ir de un punto a otro deje de ser algo monótono y se convierta en algo donde exploras, compites y ganas recompensas. Está en desarrollo, hoy se encuentra en versión beta.

**Si te quedas en blanco:** «Es un mapa que se siente como un juego».

---

## Diapositiva 2 — Qué es GAME GPS (45 segundos)

> Las aplicaciones de mapas de siempre son utilitarias: te dicen por dónde ir y ya. No te dan ninguna razón para salir a explorar ni para volver a usarlas.
>
> GAME GPS mezcla navegación real con mecánicas de juego. Es una aplicación con mapa interactivo y GPS en tiempo real, búsqueda de lugares y rutas desde tu posición. Cada recorrido suma puntos, cada punto desbloquea skins y los retos te dan algo que perseguir.
>
> **Lo importante:** funciona sin cuenta, sin anuncios y sin pagar API keys.

**Si te quedas en blanco:** «Navegación real + puntos, retos y skins».

---

## Diapositiva 3 — Mapa y ubicación (40 segundos)

> El mapa tiene identidad propia: fondo azul noche, caminos cian y parques verdes. No es el mapa de siempre con otro color encima.
>
> Trabajamos con OpenStreetMap y teselas de OpenFreeMap, así que **no necesitamos una API key de pago**. El indicador de posición se mueve con el GPS y la cámara lo sigue. Si la señal se pierde, la app lo reintenta sola y, si sigue fallando, ofrece reintentar o abrir los ajustes del teléfono.

**Si te quedas en blanco:** «Mapa propio, sin API key, y el GPS te sigue».

---

## Diapositiva 4 — Rutas (35 segundos)

> Para buscar un lugar usamos Photon, que trabaja con datos de OpenStreetMap y no recibe tu ubicación. Cuando eliges un resultado, se calcula la ruta sola con OSRM.
>
> Hay tres modos: coche, a pie y bicicleta. Además se puede cambiar el color y el grosor de la línea, el idioma y las unidades. La cámara encuadra la ruta completa y se muestran distancia, duración e instrucciones.

**Si te quedas en blanco:** «Buscas un lugar y la ruta se calcula sola».

---

## Diapositiva 5 — Gamificación (45 segundos)

> Acá está la parte divertida. Se gana **1 punto cada 100 metros** recorridos de verdad, y **15 puntos al llegar a un destino**, una sola vez por lugar. También hay 5 puntos diarios por abrir la app y 5 extra por mantener la racha de 7 días.
>
> Hay retos diarios —caminar 500 metros, llegar a un destino, buscar tres lugares— y metas generales de 1, 5 y 10 kilómetros. Los premios se cobran solos al llegar.
>
> Con esos puntos se compran skins en la tienda: dragón, ninja, medusa, astronauta, rey, mecha y cohete. También puedes subir tu propia imagen desde la galería.

**Si te quedas en blanco:** «Cada paso cuenta puntos, y los puntos se cambian por skins».

---

## Diapositiva 6 — Datos y privacidad (50 segundos)

Esta es la diapositiva que más me preguntaron, así que la explico con calma.

> **En esta versión no hay base de datos de servidor ni cuentas de usuario.** Puntos, skins, racha, retos y preferencias se guardan en el propio teléfono con SharedPreferences. Los diseños que subes quedan en el almacenamiento privado de la app.
>
> Lo único que se envía a internet son coordenadas puntuales a Photon y OSRM, solo para buscar lugares y calcular rutas. No guardamos un historial de viajes ni coordenadas personales en el repositorio.
>
> Dos cosas importantes: si desinstalas la app se pierden los datos locales, y esa es una limitación conocida de la beta. El siguiente paso es un backend con Supabase y PostgreSQL para poder tener cuentas y guardar el progreso en la nube.

**Si te quedas en blanco:** «Los datos están en el teléfono; la nube es el siguiente paso».

---

## Diapositiva 7 — Estado actual y próximos pasos (40 segundos)

> Hoy ya funcionan el mapa, el GPS, la búsqueda, las rutas, los skins, la tienda, los puntos, los retos y el rastro del recorrido.
>
> Falta terminar el zoom, los marcadores propios, los favoritos y la navegación guiada con voz —por ahora las instrucciones son de texto—. También falta la sincronización en la nube y la versión para iOS; hoy solo está en Android.
>
> Tecnológicamente es Flutter con Dart, MapLibre y servicios abiertos de OpenStreetMap. La versión actual es la 0.1.0.

**Si te quedas en blanco:** «Ya funciona casi todo; falta la voz, la nube y iOS».

---

## Diapositiva 8 — Cierre (15 segundos)

> Para cerrar: GAME GPS convierte un trayecto cualquiera en una experiencia de juego, y ya funciona en beta. Explora, compite, llega más lejos. Muchas gracias. ¿Preguntas?

**Si te quedas en blanco:** «Gracias. ¿Preguntas?»

---

## Cómo voy a vender GAME GPS (esto es lo que más les interesa a los profesores)

Di esto con calma, como si se lo explicaras a alguien en un café:

> Profesor, GAME GPS no es solo un mapa: es un producto con un modelo claro.

**1. A quién le vendo — mi cliente**
Jóvenes entre 15 y 30 años, estudiantes, corredores y ciclistas que ya usan apps de mapas o de retos como Strava o Pokémon GO. Gente que quiere moverse pero necesita un motivo extra para hacerlo.

**2. Qué problema le resuelvo**
Los mapas tradicionales cumplen, pero no enganchan: la gente los abre, llega y se va. Yo le devuelvo la motivación: cada salida suma puntos, desbloquea skins y tiene un reto. Eso hace que la persona vuelva a usar la app todos los días.

**3. Por qué es diferente**
- Strava mide tu ejercicio, pero es serio.
- Pokémon GO es divertido, pero no te lleva a donde quieres ir.
- Waze te lleva, pero no te premia.

**GAME GPS hace las tres cosas a la vez: te lleva, te entretiene y te recompensa.**

**4. Cómo se gana dinero — modelo de negocio**
Hoy no hay pagos reales; los puntos Geo son moneda interna. El modelo pensado es **freemium**:

- La app, el mapa y las rutas son **gratis**.
- Se venden **skins premium y temas de mapa** especiales (en una fase futura, con pago real).
- **Santuarios patrocinados:** negocios como cafeterías, gimnasios o la propia universidad aparecen como puntos de interés y dan bonificación a quien llega. Les llevamos clientes y nos pagan por eso.
- **Panel administrativo para empresas (B2B):** el mismo sistema sirve para gestionar campañas, métricas y catálogos.

**5. Cómo lo lanzo**
Beta cerrada en el SENA y con grupos de running y ciclismo, recoger feedback, ajustar y abrir por fases. Como usamos OpenStreetMap y no pagamos API keys, el costo de operación es muy bajo.

**6. Qué mido para saber si funciona**
Usuarios activos diarios, rutas completadas, retención a los 7 días y canjes en la tienda.

### Pitch de 45 segundos (para decirlo seguido)

> «GAME GPS es un mapa que se siente como un juego. Lo vamos a vender con un modelo **freemium**: la navegación es gratis y los ingresos vienen de skins premium, temas de mapa y de **santuarios patrocinados**, locales que nos pagan para aparecer como destino y recibir clientes. A diferencia de Strava, que es serio, o Pokémon GO, que no te lleva a ningún lado, aquí te llevas a tu destino, te diviertes y ganas puntos. Y lo hacemos con tecnología abierta, sin pagar API keys, así que es barato de operar. Empezamos con una beta en el SENA, medimos retención y rutas completadas, y crecemos por fases.»

**Frase para cerrar el tema:** «No estoy vendiendo un mapa, estoy vendiendo el motivo para salir a caminar».

---

## Si te hacen estas preguntas

**¿Por qué no usaste Google Maps?**
Porque requiere API key y pago. OpenStreetMap es abierto, gratis y no depende de una cuenta de Google.

**¿Dónde se guardan mis datos?**
En el teléfono. No hay servidor ni base de datos en la nube todavía.

**¿Qué pasa si desinstalo la app?**
Se pierden los puntos y los skins. Por eso queremos pasar el progreso a la nube.

**¿Hay pagos reales?**
No. Los puntos Geo son moneda virtual, no se compra nada con dinero.

**¿Por qué está en beta?**
Porque faltan funciones como la voz, los favoritos, la nube y la versión iOS. Lo dejamos dicho abiertamente en la presentación.

**¿Qué fue lo más difícil?**
Integrar el mapa con estilo propio y que la acreditación de puntos por distancia funcionara sin duplicar recorridos.

**¿Es app o es web?**
El producto es la app GAME GPS. La web es el soporte de presentación y difusión.

**¿Cómo lo van a monetizar?**
Con un modelo freemium: navegación gratis, skins y temas premium, y santuarios patrocinados por negocios que quieren recibir clientes.

**¿Quién es su competencia?**
Strava, Pokémon GO y Waze. La diferencia es que nosotros unimos navegación, diversión y recompensa en un solo lugar.

**¿Cuánto cuesta operarlo?**
Muy poco: OpenStreetMap es libre y no pagamos API keys. El gasto principal es el servidor cuando pongamos la nube.

**¿Ya tiene usuarios?**
Está en beta. El primer paso es probarlo con un grupo cerrado del SENA y medir rutas completadas y retención.

---

## Frase de emergencia

Si en algún momento te bloqueas, di esto y sigue:

> «Lo importante de GAME GPS es esto: toma algo que todos hacemos —ir de un lugar a otro— y le añade puntos, retos y personalización. Ya funciona en beta, y lo que viene es la nube y la voz.»

---

## Extra: si te piden hablar de la parte web / SENA

> «La ficha del proyecto plantea GAMEGPS como aplicación web: interfaz en HTML5, CSS3 y JavaScript con Leaflet y OpenStreetMap, persistencia en SQLite y un panel administrativo para gestionar viajeros, saldos Geo, skins, misiones y santuarios. La matriz de requisitos ya está adaptada a ese alcance.»
