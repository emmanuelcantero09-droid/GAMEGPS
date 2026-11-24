# Base de datos GeoQuest

La app Flutter/Android usa esta base de datos a través de `api.py`: al abrir pide
cuenta (login/registro) y muestra el avatar del usuario en el mapa. Configura la
dirección del API desde la propia pantalla de acceso (`http://127.0.0.1:8000` por
defecto; con el celular por USB usa `adb reverse tcp:8000 tcp:8000`). Ventana del
API: `python3 database/api.py`.

Un solo archivo SQLite (`geoquest.db`) con el esquema original del proyecto más
**una tabla por interfaz**:

| Interfaz | Tabla |
| --- | --- |
| Acceso / registro | `interfaz_auth` |
| Mapa y GPS | `interfaz_mapa` |
| Estadísticas | `interfaz_estadisticas` |
| Tienda | `interfaz_tienda`, `interfaz_inventario` |
| Reportes | `interfaz_reportes` |
| Resumen del admin | `interfaz_admin_resumen` |
| Usuarios del admin | `interfaz_admin_usuarios` |
| Catálogo y misiones | `interfaz_admin_catalogo` |
| Lugares especiales | `interfaz_admin_lugares` |

## Uso

```bash
python3 database/database.py   # crear/actualizar esquema y datos de ejemplo
python3 database/api.py        # servir la web + API JSON en http://localhost:8000
```

`database.py` es una extensión del script original (`base de datos/python database.py`),
que fue eliminado junto con la carpeta `base de datos/` a petición del usuario.
`api.py` no tiene dependencias externas: usa solo `http.server` y `sqlite3` de la
biblioteca estándar.
