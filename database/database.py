"""
GeoQuest · Base de datos SQLite
================================

Esquema único (`geoquest.db`) con:
  · Las tablas originales del proyecto (usuarios, rutas, misiones, ...).
  · Una tabla por interfaz de la web: interfaz_auth, interfaz_mapa,
    interfaz_estadisticas, interfaz_tienda, interfaz_reportes,
    interfaz_admin_resumen, interfaz_admin_usuarios,
    interfaz_admin_catalogo e interfaz_admin_lugares.

Uso:  python3 database/database.py
"""

import sqlite3
from pathlib import Path

BASE_DIR = Path(__file__).resolve().parent
DB_PATH = BASE_DIR / "geoquest.db"


def conectar():
    conexion = sqlite3.connect(DB_PATH)
    conexion.row_factory = sqlite3.Row
    conexion.execute("PRAGMA foreign_keys = ON")
    return conexion


# ---------------------------------------------------------------------------
# Esquema original (se conserva)
# ---------------------------------------------------------------------------

TABLAS_ORIGINALES = [
    """
    CREATE TABLE IF NOT EXISTS usuarios (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nombre TEXT NOT NULL,
        correo TEXT UNIQUE NOT NULL,
        contrasena TEXT NOT NULL,
        nivel INTEGER DEFAULT 1,
        puntos INTEGER DEFAULT 0,
        estado TEXT DEFAULT 'activo'
    )
    """,
    """
    CREATE TABLE IF NOT EXISTS rutas (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        usuario_id INTEGER NOT NULL,
        distancia REAL DEFAULT 0,
        fecha TEXT NOT NULL,
        FOREIGN KEY (usuario_id) REFERENCES usuarios(id)
    )
    """,
    """
    CREATE TABLE IF NOT EXISTS misiones (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        titulo TEXT NOT NULL,
        descripcion TEXT,
        objetivo INTEGER NOT NULL,
        recompensa INTEGER DEFAULT 0,
        activa INTEGER DEFAULT 1
    )
    """,
    """
    CREATE TABLE IF NOT EXISTS progreso_misiones (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        usuario_id INTEGER NOT NULL,
        mision_id INTEGER NOT NULL,
        progreso INTEGER DEFAULT 0,
        completada INTEGER DEFAULT 0,
        FOREIGN KEY (usuario_id) REFERENCES usuarios(id),
        FOREIGN KEY (mision_id) REFERENCES misiones(id),
        UNIQUE(usuario_id, mision_id)
    )
    """,
    """
    CREATE TABLE IF NOT EXISTS lugares (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nombre TEXT NOT NULL,
        latitud REAL NOT NULL,
        longitud REAL NOT NULL,
        recompensa INTEGER DEFAULT 0,
        activo INTEGER DEFAULT 1
    )
    """,
    """
    CREATE TABLE IF NOT EXISTS equipamiento (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nombre TEXT NOT NULL,
        descripcion TEXT,
        precio INTEGER DEFAULT 0,
        activo INTEGER DEFAULT 1
    )
    """,
    """
    CREATE TABLE IF NOT EXISTS inventario (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        usuario_id INTEGER NOT NULL,
        equipamiento_id INTEGER NOT NULL,
        equipado INTEGER DEFAULT 0,
        FOREIGN KEY (usuario_id) REFERENCES usuarios(id),
        FOREIGN KEY (equipamiento_id) REFERENCES equipamiento(id),
        UNIQUE(usuario_id, equipamiento_id)
    )
    """,
    """
    CREATE TABLE IF NOT EXISTS reportes (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        usuario_id INTEGER NOT NULL,
        descripcion TEXT NOT NULL,
        fecha TEXT NOT NULL,
        estado TEXT DEFAULT 'pendiente',
        FOREIGN KEY (usuario_id) REFERENCES usuarios(id)
    )
    """,
]


# ---------------------------------------------------------------------------
# Una tabla por interfaz
# ---------------------------------------------------------------------------

TABLAS_INTERFAZ = [
    # 1. Pantalla de acceso / registro
    """
    CREATE TABLE IF NOT EXISTS interfaz_auth (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nombre TEXT NOT NULL,
        correo TEXT UNIQUE NOT NULL,
        contrasena TEXT NOT NULL,
        rol TEXT NOT NULL DEFAULT 'usuario',
        estado TEXT NOT NULL DEFAULT 'activo',
        puntos INTEGER DEFAULT 0,
        nivel TEXT DEFAULT 'Explorador',
        fecha_registro TEXT DEFAULT CURRENT_TIMESTAMP
    )
    """,
    # 2. Mapa y controles GPS
    """
    CREATE TABLE IF NOT EXISTS interfaz_mapa (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        usuario_id INTEGER NOT NULL,
        nombre TEXT NOT NULL,
        latitud REAL NOT NULL,
        longitud REAL NOT NULL,
        distancia_km REAL DEFAULT 0,
        fecha TEXT DEFAULT CURRENT_TIMESTAMP,
        estado TEXT DEFAULT 'finalizada',
        FOREIGN KEY (usuario_id) REFERENCES interfaz_auth(id)
    )
    """,
    # 3. Estadísticas del viajero
    """
    CREATE TABLE IF NOT EXISTS interfaz_estadisticas (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        usuario_id INTEGER NOT NULL UNIQUE,
        total_km REAL DEFAULT 0,
        rutas_completadas INTEGER DEFAULT 0,
        lugares_descubiertos INTEGER DEFAULT 0,
        puntos INTEGER DEFAULT 0,
        FOREIGN KEY (usuario_id) REFERENCES interfaz_auth(id)
    )
    """,
    # 4. Tienda de personalización
    """
    CREATE TABLE IF NOT EXISTS interfaz_tienda (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        codigo TEXT UNIQUE NOT NULL,
        nombre TEXT NOT NULL,
        descripcion TEXT,
        precio INTEGER NOT NULL,
        activo INTEGER DEFAULT 1,
        icono TEXT DEFAULT 'fa-gem'
    )
    """,
    """
    CREATE TABLE IF NOT EXISTS interfaz_inventario (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        usuario_id INTEGER NOT NULL,
        item_codigo TEXT NOT NULL,
        equipado INTEGER DEFAULT 0,
        UNIQUE(usuario_id, item_codigo),
        FOREIGN KEY (usuario_id) REFERENCES interfaz_auth(id),
        FOREIGN KEY (item_codigo) REFERENCES interfaz_tienda(codigo)
    )
    """,
    # 5. Reportes comunitarios
    """
    CREATE TABLE IF NOT EXISTS interfaz_reportes (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        usuario_id INTEGER NOT NULL,
        tipo TEXT NOT NULL,
        descripcion TEXT NOT NULL,
        latitud REAL,
        longitud REAL,
        estado TEXT DEFAULT 'pendiente',
        fecha TEXT DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (usuario_id) REFERENCES interfaz_auth(id)
    )
    """,
    # 6. Resumen del panel de administración
    """
    CREATE TABLE IF NOT EXISTS interfaz_admin_resumen (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        evento TEXT NOT NULL,
        detalle TEXT,
        hora TEXT DEFAULT CURRENT_TIMESTAMP
    )
    """,
    # 7. Usuarios dentro del panel de administración
    """
    CREATE TABLE IF NOT EXISTS interfaz_admin_usuarios (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        usuario_id INTEGER NOT NULL UNIQUE,
        puntos INTEGER DEFAULT 0,
        estado TEXT DEFAULT 'activo',
        ultima_actividad TEXT DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (usuario_id) REFERENCES interfaz_auth(id)
    )
    """,
    # 8. Catálogo (recompensas y misiones) del panel de administración
    """
    CREATE TABLE IF NOT EXISTS interfaz_admin_catalogo (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        seccion TEXT NOT NULL,
        codigo TEXT NOT NULL,
        nombre TEXT NOT NULL,
        precio INTEGER DEFAULT 0,
        meta INTEGER DEFAULT 0,
        recompensa INTEGER DEFAULT 0,
        activo INTEGER DEFAULT 1,
        UNIQUE(seccion, codigo)
    )
    """,
    # 9. Lugares especiales del panel de administración
    """
    CREATE TABLE IF NOT EXISTS interfaz_admin_lugares (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nombre TEXT NOT NULL,
        latitud REAL NOT NULL,
        longitud REAL NOT NULL,
        recompensa INTEGER DEFAULT 0,
        activo INTEGER DEFAULT 1,
        fecha_creacion TEXT DEFAULT CURRENT_TIMESTAMP
    )
    """,
]


def crear_base_datos():
    conexion = conectar()
    cursor = conexion.cursor()

    for sql in TABLAS_ORIGINALES + TABLAS_INTERFAZ:
        cursor.execute(sql)

    # --- Datos de ejemplo, vinculados a cada interfaz -----------------------
    cursor.execute("SELECT COUNT(*) FROM interfaz_auth")
    if cursor.fetchone()[0] == 0:
        cursor.executemany(
            """INSERT INTO interfaz_auth
               (nombre, correo, contrasena, rol, estado, puntos, nivel)
               VALUES (?, ?, ?, ?, ?, ?, ?)""",
            [
                ("Caballero Errante", "viajero@geoquest.local", "123456",
                 "usuario", "activo", 320, "Caballero"),
                ("Hornet Exploradora", "hornet@geoquest.local", "123456",
                 "usuario", "activo", 180, "Errante"),
                ("Vigilante del Consejo", "admin@geoquest.local", "admin123",
                 "admin", "activo", 999, "Cartógrafo"),
            ],
        )
        cursor.executemany(
            """INSERT INTO interfaz_estadisticas
               (usuario_id, total_km, rutas_completadas, lugares_descubiertos, puntos)
               VALUES (?, ?, ?, ?, ?)""",
            [(1, 12.4, 8, 5, 320), (2, 4.8, 3, 2, 180), (3, 31.6, 17, 11, 999)],
        )
        cursor.executemany(
            """INSERT INTO interfaz_mapa
               (usuario_id, nombre, latitud, longitud, distancia_km, estado)
               VALUES (?, ?, ?, ?, ?, ?)""",
            [
                (1, "Sendero del Bosque", 6.2706, -75.5656, 3.4, "finalizada"),
                (1, " Plaza del Consejo", 6.2520, -75.5685, 2.1, "finalizada"),
                (2, "Mirador de Cristal", 6.2359, -75.5801, 4.8, "finalizada"),
            ],
        )
        cursor.executemany(
            """INSERT INTO interfaz_tienda
               (codigo, nombre, descripcion, precio, icono)
               VALUES (?, ?, ?, ?, ?)""",
            [
                ("dark-theme", "Modo oscuro", "Tema oscuro para el mapa.", 100, "fa-moon"),
                ("cyberpunk-theme", "Modo Cyberpunk", "Estilo futurista para explorar.", 250, "fa-bolt"),
                ("custom-cursor", "Cursor especial", "Personaliza tu experiencia.", 150, "fa-arrow-pointer"),
                ("neon-route", "Ruta neón", "Personaliza el color de tus rutas.", 200, "fa-wand-magic-sparkles"),
            ],
        )
        cursor.executemany(
            """INSERT INTO interfaz_reportes
               (usuario_id, tipo, descripcion, latitud, longitud)
               VALUES (?, ?, ?, ?, ?)""",
            [
                (1, "traffic", "Tráfico denso en la avenida principal.", 6.2442, -75.5812),
                (2, "place", "Santuario de Cristal descubierto.", 6.2706, -75.5656),
            ],
        )
        cursor.executemany(
            """INSERT INTO interfaz_admin_usuarios (usuario_id, puntos, estado)
               VALUES (?, ?, ?)""",
            [(1, 320, "activo"), (2, 180, "activo"), (3, 999, "activo")],
        )
        cursor.executemany(
            """INSERT INTO interfaz_admin_catalogo
               (seccion, codigo, nombre, precio, meta, recompensa, activo)
               VALUES (?, ?, ?, ?, ?, ?, ?)""",
            [
                ("recompensa", "dark-theme", "Modo oscuro", 100, 0, 0, 1),
                ("recompensa", "cyberpunk-theme", "Modo Cyberpunk", 250, 0, 0, 1),
                ("recompensa", "custom-cursor", "Cursor especial", 150, 0, 0, 1),
                ("recompensa", "neon-route", "Ruta neón", 200, 0, 0, 1),
                ("mision", "mision-inicio", "Primeros pasos", 0, 2, 60, 1),
                ("mision", "mision-cartografo", "Cartógrafo urbano", 0, 5, 140, 1),
            ],
        )
        cursor.executemany(
            """INSERT INTO interfaz_admin_lugares
               (nombre, latitud, longitud, recompensa)
               VALUES (?, ?, ?, ?)""",
            [
                ("Santuario de Cristal", 6.2706, -75.5656, 100),
                ("Mirador Cerro Nutibara", 6.2359, -75.5801, 130),
                ("Plaza Botero · Centro", 6.2520, -75.5685, 90),
            ],
        )
        cursor.execute(
            "INSERT INTO interfaz_admin_resumen (evento, detalle) VALUES (?, ?)",
            ("Sistema iniciado", "GeoQuest listo para explorar"),
        )

    conexion.commit()
    conexion.close()
    print(f"Base de datos GeoQuest creada en {DB_PATH}")


if __name__ == "__main__":
    crear_base_datos()
