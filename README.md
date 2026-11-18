# GAME GPS

Aplicación de navegación GPS para Android con una interfaz futurista inspirada en videojuegos modernos, construida con Flutter.

> Estado actual: **entorno de desarrollo listo y verificado**. El proyecto Flutter se creará en el siguiente paso.

## Stack previsto

| Capa | Tecnología |
|---|---|
| App | Flutter 3.50.0 / Dart 3.14.0 |
| Mapas | MapLibre |
| Datos geográficos | OpenStreetMap |
| Backend (futuro) | Supabase + PostgreSQL |
| Control de versiones | Git + GitHub |

## Funciones previstas

1. Mapa interactivo.
2. Ubicación del dispositivo con permiso del usuario.
3. Acercar / alejar.
4. Marcadores personalizados.
5. Ubicaciones favoritas.
6. Personalización de colores y apariencia.
7. Rutas y navegación (futuras versiones).

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
