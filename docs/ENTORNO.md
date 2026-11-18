# Entorno de desarrollo — GAME GPS

Sistema detectado: **WSL2 / Ubuntu 26.04.1 LTS**, arquitectura x86_64.

## Herramientas instaladas

Todo se instaló en el directorio del usuario, sin `sudo`:

| Herramienta | Ruta | Versión |
|---|---|---|
| Flutter | `~/tools/flutter` | 3.50.0 (stable) |
| Dart | incluido en Flutter | 3.14.0 |
| JDK Temurin | `~/tools/jdk17` | 17.0.21.1+2 |
| Android SDK | `~/tools/android-sdk` | Platform 36 / Build-Tools 36.0.0 |
| Platform Tools | `~/tools/android-sdk/platform-tools` | adb 1.0.41 |

## Variables de entorno

Añadidas en `~/.bashrc` y `~/.profile` bajo el bloque `GAMEGPS_TOOLCHAIN`:

```bash
export FLUTTER_HOME="$HOME/tools/flutter"
export JAVA_HOME="$HOME/tools/jdk17"
export ANDROID_HOME="$HOME/tools/android-sdk"
export ANDROID_SDK_ROOT="$ANDROID_HOME"
export PATH="$FLUTTER_HOME/bin:$JAVA_HOME/bin:$ANDROID_HOME/cmdline-tools/latest/bin:$ANDROID_HOME/platform-tools:$PATH"
```

## Verificación

```bash
flutter --version
java -version
sdkmanager --version
flutter doctor -v
```

Resultado de `flutter doctor -v`:

- ✅ Flutter 3.50.0 / Dart 3.14.0
- ✅ Android toolchain (SDK 36, JDK 17, licencias aceptadas)
- ✅ Recursos de red

Los avisos de **Chrome** y **Linux desktop** se ignoran porque el objetivo es Android.

## Decisiones

- Se desactivó la telemetría de Flutter: `flutter --disable-analytics`.
- Se usaron hashes `sha256` oficiales para verificar las tres descargas.
- `sdkmanager` aparece como obsoleto en Google, pero Flutter 3.50 todavía lo usa para las licencias; se mantiene por compatibilidad.
- El emulador se dejó para más adelante: `/dev/kvm` existe, pero el usuario no pertenece al grupo `kvm`.
