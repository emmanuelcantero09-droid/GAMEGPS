/*
 * GEOQUEST · Datos compartidos
 * Intenta usar el API local (database/api.py); si se abre el HTML directamente,
 * trabaja con una copia en localStorage para que la demo siga funcionando.
 */

const API_DISPONIBLE = location.protocol.startsWith("http");

const CLAVES_DEMO = {
  "viajero@geoquest.local": "123456",
  "hornet@geoquest.local": "123456",
  "admin@geoquest.local": "admin123",
};

const estadoDemo = {
  usuarios: [
    { id: 1, nombre: "Caballero Errante", correo: "viajero@geoquest.local", rol: "usuario", estado: "activo", puntos: 320, nivel: "Caballero" },
    { id: 2, nombre: "Hornet Exploradora", correo: "hornet@geoquest.local", rol: "usuario", estado: "activo", puntos: 180, nivel: "Errante" },
    { id: 3, nombre: "Vigilante del Consejo", correo: "admin@geoquest.local", rol: "admin", estado: "activo", puntos: 999, nivel: "Cartógrafo" },
  ],
  estadisticas: [
    { id: 1, usuario_id: 1, total_km: 12.4, rutas_completadas: 8, lugares_descubiertos: 5, puntos: 320 },
    { id: 2, usuario_id: 2, total_km: 4.8, rutas_completadas: 3, lugares_descubiertos: 2, puntos: 180 },
    { id: 3, usuario_id: 3, total_km: 31.6, rutas_completadas: 17, lugares_descubiertos: 11, puntos: 999 },
  ],
  rutas: [
    { id: 1, usuario_id: 1, nombre: "Sendero del Bosque", latitud: 6.2706, longitud: -75.5656, distancia_km: 3.4, fecha: "Hoy" },
    { id: 2, usuario_id: 1, nombre: "Plaza del Consejo", latitud: 6.2520, longitud: -75.5685, distancia_km: 2.1, fecha: "Hoy" },
  ],
  tienda: [
    { id: 1, codigo: "dark-theme", nombre: "Modo oscuro", descripcion: "Tema oscuro para el mapa.", precio: 100, activo: 1, icono: "fa-moon" },
    { id: 2, codigo: "cyberpunk-theme", nombre: "Modo Cyberpunk", descripcion: "Estilo futurista para explorar.", precio: 250, activo: 1, icono: "fa-bolt" },
    { id: 3, codigo: "custom-cursor", nombre: "Cursor especial", descripcion: "Personaliza tu experiencia.", precio: 150, activo: 1, icono: "fa-arrow-pointer" },
    { id: 4, codigo: "neon-route", nombre: "Ruta neón", descripcion: "Personaliza el color de tus rutas.", precio: 200, activo: 1, icono: "fa-wand-magic-sparkles" },
  ],
  inventario: [],
  reportes: [
    { id: 1, usuario_id: 1, tipo: "traffic", descripcion: "Tráfico denso en la avenida principal.", latitud: 6.2442, longitud: -75.5812, fecha: "Hoy" },
  ],
  lugares: [
    { id: 1, nombre: "Santuario de Cristal", latitud: 6.2706, longitud: -75.5656, recompensa: 100, activo: 1 },
    { id: 2, nombre: "Mirador Cerro Nutibara", latitud: 6.2359, longitud: -75.5801, recompensa: 130, activo: 1 },
    { id: 3, nombre: "Plaza Botero · Centro", latitud: 6.2520, longitud: -75.5685, recompensa: 90, activo: 1 },
  ],
  catalogo: [
    { id: 1, seccion: "mision", codigo: "mision-inicio", nombre: "Primeros pasos", meta: 2, recompensa: 60, activo: 1 },
    { id: 2, seccion: "mision", codigo: "mision-cartografo", nombre: "Cartógrafo urbano", meta: 5, recompensa: 140, activo: 1 },
  ],
  actividad: [{ id: 1, evento: "Sistema iniciado", detalle: "GeoQuest listo para explorar", hora: "Ahora" }],
};

let estado = null;
let usuarioActual = null;
let posUsuario = [6.2442, -75.5812];
let mapa = null;
let marcadorUsuario = null;
let lineaRuta = null;
let intervaloRuta = null;
let distanciaRuta = 0;

function clonar(objeto) {
  return JSON.parse(JSON.stringify(objeto));
}

function guardarLocal() {
  if (API_DISPONIBLE) return;
  localStorage.setItem("geoquest_estado", JSON.stringify(estado));
}

async function cargarEstado() {
  if (API_DISPONIBLE) {
    try {
      const respuesta = await fetch("/api/estado");
      if (respuesta.ok) {
        estado = await respuesta.json();
        return;
      }
    } catch (_) { /* se usa la copia local */ }
  }
  try {
    estado = JSON.parse(localStorage.getItem("geoquest_estado")) || clonar(estadoDemo);
  } catch (_) {
    estado = clonar(estadoDemo);
  }
}

function aplicarAccionLocal(datos) {
  const accion = datos.accion;
  const uid = datos.usuario_id;

  if (accion === "login") {
    const usuario = estado.usuarios.find(u => u.correo === datos.correo);
    if (!usuario || CLAVES_DEMO[datos.correo] !== datos.contrasena) {
      return { ok: false, mensaje: "Correo o contraseña incorrectos" };
    }
    return { ok: true, usuario: { ...usuario } };
  }

  if (accion === "registro") {
    const correo = datos.correo.toLowerCase();
    if (estado.usuarios.some(u => u.correo === correo)) {
      return { ok: false, mensaje: "Ese correo ya está registrado" };
    }
    const usuario = {
      id: Math.max(0, ...estado.usuarios.map(u => u.id)) + 1,
      nombre: datos.nombre, correo, rol: "usuario", estado: "activo", puntos: 0, nivel: "Errante",
    };
    estado.usuarios.push(usuario);
    estado.estadisticas.push({ usuario_id: usuario.id, total_km: 0, rutas_completadas: 0, lugares_descubiertos: 0, puntos: 0 });
    CLAVES_DEMO[correo] = datos.contrasena;
    return { ok: true, usuario: { ...usuario } };
  }

  if (accion === "guardar_ruta") {
    estado.rutas.unshift({ ...datos, id: Date.now(), fecha: "Hoy" });
    const stats = estado.estadisticas.find(s => s.usuario_id === uid);
    if (stats) {
      stats.total_km += datos.distancia_km;
      stats.rutas_completadas += 1;
    }
  } else if (accion === "crear_reporte") {
    estado.reportes.unshift({ ...datos, id: Date.now(), fecha: "Hoy" });
  } else if (accion === "canjear") {
    const item = estado.tienda.find(i => i.codigo === datos.codigo);
    const usuario = estado.usuarios.find(u => u.id === uid);
    if (!item || !usuario || usuario.puntos < item.precio) {
      return { ok: false, mensaje: "Puntos insuficientes" };
    }
    usuario.puntos -= item.precio;
    if (!estado.inventario.some(i => i.usuario_id === uid && i.item_codigo === datos.codigo)) {
      estado.inventario.push({ usuario_id: uid, item_codigo: datos.codigo, equipado: 0 });
    }
  } else if (accion === "equipar") {
    estado.inventario.forEach(i => { if (i.usuario_id === uid) i.equipado = 0; });
    const item = estado.inventario.find(i => i.usuario_id === uid && i.item_codigo === datos.codigo);
    if (item) item.equipado = 1;
  } else if (accion === "admin_ajustar_puntos") {
    const usuario = estado.usuarios.find(u => u.id === uid);
    if (usuario) usuario.puntos = Math.max(0, usuario.puntos + datos.delta);
  } else if (accion === "admin_cambiar_estado") {
    const usuario = estado.usuarios.find(u => u.id === uid);
    if (usuario) usuario.estado = datos.estado;
  } else if (accion === "admin_cambiar_precio") {
    const item = estado.tienda.find(i => i.codigo === datos.codigo);
    if (item) item.precio = datos.precio;
  } else if (accion === "admin_activar_item") {
    const item = estado.tienda.find(i => i.codigo === datos.codigo);
    if (item) item.activo = datos.activo;
  } else if (accion === "admin_crear_mision") {
    estado.catalogo.push({
      id: Date.now(), seccion: "mision", codigo: "mision-" + Date.now(),
      nombre: datos.nombre, meta: datos.meta, recompensa: datos.recompensa, activo: 1,
    });
  } else if (accion === "admin_eliminar_mision") {
    estado.catalogo = estado.catalogo.filter(c => c.id !== datos.id);
  } else if (accion === "admin_crear_lugar") {
    estado.lugares.push({ ...datos, id: Date.now(), activo: 1 });
  } else if (accion === "admin_eliminar_lugar") {
    estado.lugares = estado.lugares.filter(l => l.id !== datos.id);
  }

  guardarLocal();
  return { ok: true };
}

async function enviarAccion(datos) {
  if (API_DISPONIBLE) {
    try {
      const respuesta = await fetch("/api/accion", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify(datos),
      });
      const resultado = await respuesta.json();
      if (resultado.ok) await cargarEstado();
      return resultado;
    } catch (_) { /* fallback local */ }
  }
  return aplicarAccionLocal(datos);
}

function notificar(mensaje, tipo = "info") {
  const contenedor = document.getElementById("toast-container");
  if (!contenedor) return;
  const toast = document.createElement("div");
  toast.className = `toast ${tipo === "error" ? "error" : ""}`;
  toast.innerHTML = `<i class="fa-solid ${tipo === "error" ? "fa-triangle-exclamation" : "fa-sparkles"}"></i><span>${mensaje}</span>`;
  contenedor.appendChild(toast);
  setTimeout(() => toast.remove(), 3600);
}

function statsDe(usuario) {
  return estado.estadisticas.find(s => s.usuario_id === usuario.id) || {
    total_km: 0, rutas_completadas: 0, lugares_descubiertos: 0,
  };
}

document.addEventListener("DOMContentLoaded", async () => {
  await cargarEstado();
  if (window.iniciarInterfazUsuario) window.iniciarInterfazUsuario();
});
