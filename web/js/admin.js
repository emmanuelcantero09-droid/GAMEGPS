/*
 * GEOQUEST · Panel de administración
 * Usuarios, catálogo, misiones y lugares, respaldados por una tabla por interfaz.
 */

const PRECIOS = {
  "price-dark": "dark-theme",
  "price-cyber": "cyberpunk-theme",
  "price-cursor": "custom-cursor",
  "price-trail": "neon-route",
};
const ACTIVOS = {
  "active-dark": "dark-theme",
  "active-cyber": "cyberpunk-theme",
  "active-cursor": "custom-cursor",
  "active-trail": "neon-route",
};

let adminInicializado = false;

function mostrarPanelAdmin(usuario) {
  const panel = document.getElementById("admin-panel");
  panel.classList.remove("vista-oculta");

  if (!adminInicializado) {
    inicializarAdmin();
    adminInicializado = true;
  }
  renderizarAdmin();
  notificar(`Panel de administración · ${usuario.nombre}`);
}

function inicializarAdmin() {
  document.querySelectorAll("#admin-navigation .admin-nav-btn").forEach(boton => {
    boton.addEventListener("click", () => {
      const vista = boton.dataset.adminView;
      document.querySelectorAll("#admin-content .admin-view").forEach(seccion => {
        seccion.hidden = seccion.id !== vista;
      });
      document.querySelectorAll("#admin-navigation .admin-nav-btn").forEach(b => {
        b.classList.remove("activo", "admin-nav-active");
      });
      boton.classList.add("activo");
    });
  });

  document.getElementById("admin-user-search").addEventListener("input", renderizarUsuariosAdmin);

  Object.entries(PRECIOS).forEach(([id, codigo]) => {
    const boton = document.getElementById(id).closest(".admin-reward-card").querySelector(".save-price");
    boton.dataset.codigo = codigo;
    boton.addEventListener("click", async () => {
      const precio = Math.max(0, parseInt(document.getElementById(id).value, 10) || 0);
      const resultado = await enviarAccion({ accion: "admin_cambiar_precio", codigo, precio });
      notificar(resultado.ok ? `Precio de ${codigo} actualizado` : resultado.mensaje, resultado.ok ? "info" : "error");
      if (resultado.ok) renderizarCatalogoAdmin();
    });
  });

  Object.entries(ACTIVOS).forEach(([id, codigo]) => {
    const check = document.getElementById(id);
    check.dataset.codigo = codigo;
    check.addEventListener("change", async () => {
      await enviarAccion({ accion: "admin_activar_item", codigo, activo: check.checked ? 1 : 0 });
      notificar(`${codigo}: ${check.checked ? "activo" : "inactivo"}`);
    });
  });

  document.getElementById("admin-mission-form").addEventListener("submit", async evento => {
    evento.preventDefault();
    const resultado = await enviarAccion({
      accion: "admin_crear_mision",
      nombre: document.getElementById("mission-title").value.trim(),
      meta: parseInt(document.getElementById("mission-goal").value, 10),
      recompensa: parseInt(document.getElementById("mission-reward").value, 10),
    });
    if (!resultado.ok) return notificar(resultado.mensaje, "error");
    evento.target.reset();
    notificar("Misión creada");
    renderizarCatalogoAdmin();
  });

  document.getElementById("admin-place-form").addEventListener("submit", async evento => {
    evento.preventDefault();
    const resultado = await enviarAccion({
      accion: "admin_crear_lugar",
      nombre: document.getElementById("place-name").value.trim(),
      latitud: parseFloat(document.getElementById("place-latitude").value),
      longitud: parseFloat(document.getElementById("place-longitude").value),
      recompensa: parseInt(document.getElementById("place-reward").value, 10),
    });
    if (!resultado.ok) return notificar(resultado.mensaje, "error");
    evento.target.reset();
    notificar("Santuario publicado en el mapa");
    renderizarAdmin();
  });

  document.getElementById("select-place-map").addEventListener("click", () => {
    document.getElementById("place-latitude").value = posUsuario[0].toFixed(4);
    document.getElementById("place-longitude").value = posUsuario[1].toFixed(4);
    notificar("Coordenadas tomadas del mapa");
  });
}

function renderizarAdmin() {
  renderizarResumenAdmin();
  renderizarUsuariosAdmin();
  renderizarCatalogoAdmin();
  renderizarLugaresAdmin();
}

function renderizarResumenAdmin() {
  const viajeros = estado.usuarios.filter(u => u.rol === "usuario");
  const km = estado.estadisticas
    .filter(s => viajeros.some(u => u.id === s.usuario_id))
    .reduce((total, s) => total + s.total_km, 0);
  const puntos = viajeros.reduce((total, u) => total + u.puntos, 0);

  document.getElementById("admin-total-users").textContent = viajeros.length;
  document.getElementById("admin-total-km").textContent = `${km.toFixed(1)} km`;
  document.getElementById("admin-total-points").textContent = puntos;
  document.getElementById("admin-total-places").textContent = estado.lugares.length;

  document.getElementById("admin-recent-activity").innerHTML = estado.actividad.length
    ? estado.actividad.slice(0, 5).map(a => `
        <tr>
          <td>${a.evento}</td>
          <td>${a.detalle || "—"}</td>
          <td>${a.hora}</td>
        </tr>`).join("")
    : '<tr><td colspan="3">Sin actividad reciente.</td></tr>';
}

function renderizarUsuariosAdmin() {
  const filtro = (document.getElementById("admin-user-search")?.value || "").toLowerCase();
  const usuarios = estado.usuarios.filter(u => u.nombre.toLowerCase().includes(filtro));
  document.getElementById("admin-users-list").innerHTML = usuarios.length
    ? usuarios.map(u => {
        const stats = statsDe(u);
        const activo = u.estado === "activo";
        return `
          <tr>
            <td><strong>${u.nombre}</strong></td>
            <td>${u.nivel}</td>
            <td>${u.puntos}</td>
            <td>${stats.rutas_completadas}</td>
            <td><span class="user-status ${activo ? "active" : "suspended"}">${activo ? "Activo" : "Suspendido"}</span></td>
            <td>
              <div class="user-actions">
                <button type="button" class="action-add" data-id="${u.id}" data-accion="sumar">+50 Pts</button>
                <button type="button" class="action-remove" data-id="${u.id}" data-accion="restar">-50 Pts</button>
                <button type="button" class="action-suspend" data-id="${u.id}" data-accion="estado">
                  ${activo ? "Suspender" : "Activar"}
                </button>
                <button type="button" class="action-reset" data-id="${u.id}" data-accion="reiniciar">Reiniciar</button>
              </div>
            </td>
          </tr>`;
      }).join("")
    : '<tr><td colspan="6">No hay usuarios que coincidan.</td></tr>';

  document.querySelectorAll("#admin-users-list button[data-accion]").forEach(boton => {
    boton.addEventListener("click", () => ejecutarAccionUsuario(Number(boton.dataset.id), boton.dataset.accion));
  });
}

async function ejecutarAccionUsuario(id, accion) {
  const usuario = estado.usuarios.find(u => u.id === id);
  if (!usuario) return;
  let datos;

  if (accion === "sumar") datos = { accion: "admin_ajustar_puntos", usuario_id: id, delta: 50 };
  else if (accion === "restar") datos = { accion: "admin_ajustar_puntos", usuario_id: id, delta: -50 };
  else if (accion === "reiniciar") datos = { accion: "admin_ajustar_puntos", usuario_id: id, delta: -usuario.puntos };
  else datos = {
    accion: "admin_cambiar_estado",
    usuario_id: id,
    estado: usuario.estado === "activo" ? "suspendido" : "activo",
  };

  await enviarAccion(datos);
  notificar("Cuenta actualizada");
  renderizarAdmin();
}

function renderizarCatalogoAdmin() {
  Object.entries(PRECIOS).forEach(([id, codigo]) => {
    const item = estado.tienda.find(i => i.codigo === codigo);
    if (item) document.getElementById(id).value = item.precio;
  });
  Object.entries(ACTIVOS).forEach(([id, codigo]) => {
    const item = estado.tienda.find(i => i.codigo === codigo);
    if (item) document.getElementById(id).checked = Boolean(item.activo);
  });

  const misiones = estado.catalogo.filter(c => c.seccion === "mision");
  document.getElementById("admin-missions-list").innerHTML = misiones.length
    ? misiones.map(m => `
        <tr>
          <td>${m.nombre}</td>
          <td>${m.meta} km</td>
          <td>${m.recompensa} puntos</td>
          <td><span class="user-status ${m.activo ? "active" : "suspended"}">${m.activo ? "Activa" : "Inactiva"}</span></td>
          <td><button type="button" class="action-delete" data-id="${m.id}">Eliminar</button></td>
        </tr>`).join("")
    : '<tr><td colspan="5">No hay misiones activas.</td></tr>';

  document.querySelectorAll("#admin-missions-list button[data-id]").forEach(boton => {
    boton.addEventListener("click", async () => {
      await enviarAccion({ accion: "admin_eliminar_mision", id: Number(boton.dataset.id) });
      notificar("Misión eliminada");
      renderizarCatalogoAdmin();
    });
  });
}

function renderizarLugaresAdmin() {
  document.getElementById("admin-places-list").innerHTML = estado.lugares.length
    ? estado.lugares.map(lugar => `
        <tr>
          <td>${lugar.nombre}</td>
          <td>${Number(lugar.latitud).toFixed(4)}</td>
          <td>${Number(lugar.longitud).toFixed(4)}</td>
          <td>${lugar.recompensa} puntos</td>
          <td>
            <div class="user-actions">
              <button type="button" class="action-edit" data-ver="${lugar.id}">Ver en mapa</button>
              <button type="button" class="action-delete" data-id="${lugar.id}">Eliminar</button>
            </div>
          </td>
        </tr>`).join("")
    : '<tr><td colspan="5">No hay santuarios publicados.</td></tr>';

  document.querySelectorAll("#admin-places-list button[data-id]").forEach(boton => {
    boton.addEventListener("click", async () => {
      await enviarAccion({ accion: "admin_eliminar_lugar", id: Number(boton.dataset.id) });
      notificar("Santuario eliminado");
      renderizarAdmin();
    });
  });

  document.querySelectorAll("#admin-places-list button[data-ver]").forEach(boton => {
    boton.addEventListener("click", () => {
      const lugar = estado.lugares.find(l => l.id === Number(boton.dataset.ver));
      if (!lugar) return;
      volverAVistaUsuario();
      if (mapa) mapa.flyTo([lugar.latitud, lugar.longitud], 15);
      notificar(`Ubicando ${lugar.nombre}`);
    });
  });
}

window.mostrarPanelAdmin = mostrarPanelAdmin;
window.renderizarAdmin = renderizarAdmin;
