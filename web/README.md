# GEOQUEST · Web

Página construida con las interfaces que estaban en `html/`
(`interfas de usurios}` y `administrador`), rediseñadas con la paleta
Hollow Knight. **No usa nada de Google**: ni Google Fonts, ni Material Design,
ni Google Maps (el mapa es Leaflet + OpenStreetMap).

El archivo `gamegps_aplicaci_n_completa_con_mapa_tienda_y_skins.html` de la raíz
se conserva solo como referencia histórica: **no se usa ni se referencia** desde
esta web. El punto de entrada es `web/index.html`.

## Estructura

```
web/
├── index.html              # Acceso + vista Viajero + panel Administrador
├── css/
│   ├── base.css            # Variables, tipografía del sistema, formularios, toasts
│   ├── usuario.css         # Mapa, GPS, estadísticas, tienda y reportes
│   ├── admin.css           # Resumen, usuarios, catálogo y lugares
│   └── responsive.css      # Tablet y móvil
├── js/
│   ├── datos.js            # Estado, API/localStorage y utilidades
│   ├── usuario.js          # Login, mapa, recorridos, tienda y reportes
│   └── admin.js            # Panel de administración
└── img/avatar.svg          # Avatar propio dibujado en SVG
```

## Arranque recomendado (con base de datos real)

```bash
python3 database/api.py
# http://localhost:8000
```

El servidor sirve `web/` y expone `/api/estado` y `/api/accion`, respaldados por
`database/geoquest.db`. Si abres `index.html` directamente, la web usa una copia
en `localStorage` para que la demo siga funcionando sin servidor.

## Cuentas de ejemplo

| Correo | Contraseña | Rol |
| --- | --- | --- |
| viajero@geoquest.local | 123456 | usuario |
| hornet@geoquest.local | 123456 | usuario |
| admin@geoquest.local | admin123 | administrador |

También está el botón **Entrar como invitado / Modo Demo**.
