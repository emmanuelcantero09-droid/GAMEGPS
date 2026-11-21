"""
GeoQuest · Servidor local (sin dependencias y sin servicios de Google)
======================================================================

Sirve la carpeta web/ y expone un API JSON pequeño respaldado por geoquest.db.

    python3 database/api.py            # http://localhost:8000
"""

import json
from functools import partial
from http.server import SimpleHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path
from urllib.parse import urlparse

from database import BASE_DIR, conectar, crear_base_datos

WEB_DIR = BASE_DIR.parent / "web"
PUERTO = 8000


def filas(sql, parametros=()):
    conexion = conectar()
    try:
        return [dict(fila) for fila in conexion.execute(sql, parametros).fetchall()]
    finally:
        conexion.close()


def ejecutar(sql, parametros=()):
    conexion = conectar()
    try:
        cursor = conexion.execute(sql, parametros)
        conexion.commit()
        return cursor.lastrowid
    finally:
        conexion.close()


def estado_completo():
    usuarios = filas(
        """SELECT id, nombre, correo, rol, estado, puntos, nivel
           FROM interfaz_auth ORDER BY id"""
    )
    estadisticas = filas("SELECT * FROM interfaz_estadisticas")
    rutas = filas("SELECT * FROM interfaz_mapa ORDER BY fecha DESC, id DESC")
    tienda = filas("SELECT * FROM interfaz_tienda ORDER BY id")
    inventario = filas("SELECT * FROM interfaz_inventario")
    reportes = filas("SELECT * FROM interfaz_reportes ORDER BY fecha DESC, id DESC")
    lugares = filas("SELECT * FROM interfaz_admin_lugares ORDER BY id")
    catalogo = filas("SELECT * FROM interfaz_admin_catalogo ORDER BY id")
    actividad = filas("SELECT * FROM interfaz_admin_resumen ORDER BY id DESC LIMIT 10")
    return {
        "usuarios": usuarios,
        "estadisticas": estadisticas,
        "rutas": rutas,
        "tienda": tienda,
        "inventario": inventario,
        "reportes": reportes,
        "lugares": lugares,
        "catalogo": catalogo,
        "actividad": actividad,
    }


def aplicar_accion(datos):
    accion = datos.get("accion")

    if accion == "login":
        fila = filas(
            "SELECT id, nombre, correo, rol, estado, puntos, nivel FROM interfaz_auth "
            "WHERE correo = ? AND contrasena = ?",
            (datos["correo"].strip().lower(), datos["contrasena"]),
        )
        if not fila:
            return {"ok": False, "mensaje": "Correo o contraseña incorrectos"}
        return {"ok": True, "usuario": fila[0]}

    if accion == "registro":
        existe = filas("SELECT id FROM interfaz_auth WHERE correo = ?", (datos["correo"].lower(),))
        if existe:
            return {"ok": False, "mensaje": "Ese correo ya está registrado"}
        uid = ejecutar(
            "INSERT INTO interfaz_auth (nombre, correo, contrasena, puntos, nivel) VALUES (?, ?, ?, 0, 'Errante')",
            (datos["nombre"].strip(), datos["correo"].strip().lower(), datos["contrasena"]),
        )
        ejecutar(
            "INSERT INTO interfaz_estadisticas (usuario_id) VALUES (?)", (uid,)
        )
        ejecutar(
            "INSERT INTO interfaz_admin_usuarios (usuario_id, puntos) VALUES (?, 0)", (uid,)
        )
        return {
            "ok": True,
            "usuario": {
                "id": uid,
                "nombre": datos["nombre"].strip(),
                "correo": datos["correo"].strip().lower(),
                "rol": "usuario",
                "estado": "activo",
                "puntos": 0,
                "nivel": "Errante",
            },
        }

    if accion == "guardar_ruta":
        ejecutar(
            "INSERT INTO interfaz_mapa (usuario_id, nombre, latitud, longitud, distancia_km) "
            "VALUES (?, ?, ?, ?, ?)",
            (datos["usuario_id"], datos["nombre"], datos["latitud"], datos["longitud"], datos["distancia_km"]),
        )
        ejecutar(
            """UPDATE interfaz_estadisticas
               SET total_km = total_km + ?, rutas_completadas = rutas_completadas + 1
               WHERE usuario_id = ?""",
            (datos["distancia_km"], datos["usuario_id"]),
        )
        return {"ok": True}

    if accion == "crear_reporte":
        ejecutar(
            "INSERT INTO interfaz_reportes (usuario_id, tipo, descripcion, latitud, longitud) "
            "VALUES (?, ?, ?, ?, ?)",
            (datos["usuario_id"], datos["tipo"], datos["descripcion"], datos.get("latitud"), datos.get("longitud")),
        )
        return {"ok": True}

    if accion == "canjear":
        item = filas("SELECT * FROM interfaz_tienda WHERE codigo = ?", (datos["codigo"],))
        usuario = filas("SELECT puntos FROM interfaz_auth WHERE id = ?", (datos["usuario_id"],))
        if not item or not usuario:
            return {"ok": False, "mensaje": "Artículo no disponible"}
        if usuario[0]["puntos"] < item[0]["precio"]:
            return {"ok": False, "mensaje": "Puntos insuficientes"}
        ejecutar("UPDATE interfaz_auth SET puntos = puntos - ? WHERE id = ?", (item[0]["precio"], datos["usuario_id"]))
        ejecutar(
            "INSERT OR IGNORE INTO interfaz_inventario (usuario_id, item_codigo) VALUES (?, ?)",
            (datos["usuario_id"], datos["codigo"]),
        )
        return {"ok": True, "puntos": usuario[0]["puntos"] - item[0]["precio"]}

    if accion == "equipar":
        ejecutar(
            "UPDATE interfaz_inventario SET equipado = 0 WHERE usuario_id = ?",
            (datos["usuario_id"],),
        )
        ejecutar(
            "UPDATE interfaz_inventario SET equipado = 1 WHERE usuario_id = ? AND item_codigo = ?",
            (datos["usuario_id"], datos["codigo"]),
        )
        return {"ok": True}

    if accion == "admin_ajustar_puntos":
        ejecutar("UPDATE interfaz_auth SET puntos = MAX(0, puntos + ?) WHERE id = ?", (datos["delta"], datos["usuario_id"]))
        ejecutar("UPDATE interfaz_admin_usuarios SET puntos = MAX(0, puntos + ?) WHERE usuario_id = ?", (datos["delta"], datos["usuario_id"]))
        ejecutar(
            "INSERT INTO interfaz_admin_resumen (evento, detalle) VALUES (?, ?)",
            ("Puntos ajustados", f"Usuario #{datos['usuario_id']}: {datos['delta']:+} puntos"),
        )
        return {"ok": True}

    if accion == "admin_cambiar_estado":
        ejecutar("UPDATE interfaz_auth SET estado = ? WHERE id = ?", (datos["estado"], datos["usuario_id"]))
        ejecutar("UPDATE interfaz_admin_usuarios SET estado = ? WHERE usuario_id = ?", (datos["estado"], datos["usuario_id"]))
        return {"ok": True}

    if accion == "admin_cambiar_precio":
        ejecutar("UPDATE interfaz_tienda SET precio = ? WHERE codigo = ?", (datos["precio"], datos["codigo"]))
        ejecutar("UPDATE interfaz_admin_catalogo SET precio = ? WHERE seccion = 'recompensa' AND codigo = ?", (datos["precio"], datos["codigo"]))
        return {"ok": True}

    if accion == "admin_activar_item":
        ejecutar("UPDATE interfaz_tienda SET activo = ? WHERE codigo = ?", (datos["activo"], datos["codigo"]))
        ejecutar("UPDATE interfaz_admin_catalogo SET activo = ? WHERE seccion = 'recompensa' AND codigo = ?", (datos["activo"], datos["codigo"]))
        return {"ok": True}

    if accion == "admin_crear_mision":
        codigo = "mision-" + str(datos["nombre"]).lower().replace(" ", "-")[:24]
        ejecutar(
            "INSERT OR REPLACE INTO interfaz_admin_catalogo (seccion, codigo, nombre, meta, recompensa) "
            "VALUES ('mision', ?, ?, ?, ?)",
            (codigo, datos["nombre"], datos["meta"], datos["recompensa"]),
        )
        return {"ok": True}

    if accion == "admin_eliminar_mision":
        ejecutar("DELETE FROM interfaz_admin_catalogo WHERE id = ? AND seccion = 'mision'", (datos["id"],))
        return {"ok": True}

    if accion == "admin_crear_lugar":
        ejecutar(
            "INSERT INTO interfaz_admin_lugares (nombre, latitud, longitud, recompensa) VALUES (?, ?, ?, ?)",
            (datos["nombre"], datos["latitud"], datos["longitud"], datos["recompensa"]),
        )
        return {"ok": True}

    if accion == "admin_eliminar_lugar":
        ejecutar("DELETE FROM interfaz_admin_lugares WHERE id = ?", (datos["id"],))
        return {"ok": True}

    return {"ok": False, "mensaje": f"Acción desconocida: {accion}"}


class Manejador(SimpleHTTPRequestHandler):
    def do_GET(self):
        ruta = urlparse(self.path).path
        if ruta == "/api/estado":
            self.enviar_json(estado_completo())
        else:
            super().do_GET()

    def do_POST(self):
        if urlparse(self.path).path != "/api/accion":
            self.send_error(404)
            return
        longitud = int(self.headers.get("Content-Length", 0))
        try:
            datos = json.loads(self.rfile.read(longitud).decode("utf-8"))
            respuesta = aplicar_accion(datos)
        except Exception as error:  # errors de validación del demo
            respuesta = {"ok": False, "mensaje": str(error)}
        self.enviar_json(respuesta)

    def enviar_json(self, objeto):
        cuerpo = json.dumps(objeto, ensure_ascii=False).encode("utf-8")
        self.send_response(200)
        self.send_header("Content-Type", "application/json; charset=utf-8")
        self.send_header("Content-Length", str(len(cuerpo)))
        self.end_headers()
        self.wfile.write(cuerpo)

    def log_message(self, formato, *args):
        pass  # salida limpia


if __name__ == "__main__":
    crear_base_datos()
    manejador = partial(Manejador, directory=str(WEB_DIR))
    servidor = ThreadingHTTPServer(("0.0.0.0", PUERTO), manejador)
    print(f"GeoQuest en http://localhost:{PUERTO}  (base de datos: {BASE_DIR / 'geoquest.db'})")
    try:
        servidor.serve_forever()
    except KeyboardInterrupt:
        print("\nServidor detenido.")
