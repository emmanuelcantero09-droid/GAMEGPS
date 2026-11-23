# GAME GPS · Web

Web de presentación de **GAME GPS** (versión beta). Punto de entrada:
`web/index.html`.

Es un único archivo HTML con el CSS y el JavaScript integrados: no usa frameworks,
ni CDN, ni Google Fonts, ni Google Maps. El teléfono de la portada y los iconos
están dibujados con SVG/CSS dentro del propio archivo.

La web promociona la app y muestra lo que se puede hacer: funciones, skins,
estado real de la beta y botón de descarga del APK.

## Descarga

El botón apunta al APK real del proyecto:

```
../build/app/outputs/flutter-apk/app-release.apk
```

La ruta empieza con `../` porque el HTML está dentro de `web/`. Si mueves el
archivo a otra carpeta, ajusta ese `href`.

> Antes de publicar en Internet: el APK es local. Súbelo a una URL pública y
> cambia ese `href`, o el botón no funcionará fuera de tu PC.

## Cómo verla

Abre `web/index.html` con doble clic en el navegador. Si prefieres servirla por HTTP:

```bash
python3 -m http.server 8000
# http://localhost:8000/web/
```

## Restos de la web anterior

Las carpetas `css/`, `js/` e `img/` pertenecían a la antigua web GeoQuest y **ya no se
usan**. Se pueden borrar sin afectar a esta web.
Se conserva una copia del antiguo `index.html` en `/tmp/opencode/geoquest-index-backup.html`.
