/*
 * GEOQUEST · Interfaz del Viajero
 * Autenticación, mapa GPS, estadísticas, tienda y reportes.
 */

const POS_INICIAL = [6.2442, -75.5812];
const ICONO_VIAJERO = `
  <svg width="42" height="42" viewBox="0 0 48 48" xmlns="http://www.w3.org/2000/svg">
    <circle cx="24" cy="24" r="21" fill="#0a0c10" stroke="#56c7f5" stroke-width="2"/>
    <path d="M13 11 L18 20 H30 L35 11 L33 28 Q31 37 24 37 Q17 37 15 28 Z" fill="#f0f4f8" stroke="#0a0c10" stroke-width="1.5"/>
    <ellipse cx="19" cy="25" rx="2.5" ry="4" fill="#0a0c10"/>
    <ellipse cx="29" cy="25" rx="2.5" ry="4" fill="#0a0c10"/>
  </svg>`;

function iconoViajero() {
  if (typeof L === "undefined") return null;
  return L.divIcon({
    className: "marcador-alma",
    html: ICONO_VIAJERO,
    iconSize: [42, 42],
    iconAnchor: [21, 21],
  });
}

function initUsuario() {
  // Autenticación
  document.getElementById("login-form").addEventListener("submit", manejarLogin);
  document.getElementById("register-form").addEventListener("submit", manejarRegistro);
  document.getElementById("show-register").addEventListener("click", () => cambiarFormulario("register"));
  document.getElementById("show-login").addEventListener("click", () => cambiarFormulario("login"));
  document.getElementById("guest-mode").addEventListener("click", accesoDemo);
  document.getElementById("logout-button").addEventListener("click", cerrarSesion);
  document.getElementById("admin-logout").addEventListener("click", cerrarSesion);
  document.getElementById("admin-back-user").addEventListener("click", volverAVistaUsuario);

  // Navegación del panel lateral
  document.querySelectorAll("#sidebar-navigation button").forEach(boton => {
    boton.addEventListener("click", () => mostrarTab(boton.dataset.tab, boton));
  });

  // Mapa y GPS
  document.getElementById("destination-search").addEventListener("submit", buscarDestino);
  document.getElementById("center-location").addEventListener("click", centrarEnUsuario);
  document.getElementById("start-route").addEventListener("click", () => iniciarRecorrido(false));
  document.getElementById("stop-route").addEventListener("click", detenerRecorrido);
  document.getElementById("simulate-route").addEventListener("click", () => iniciarRecorrido(true));

  // Reportes
  document.getElementById("report-current-location").addEventListener("click", usarUbicacionEnReporte);
  document.getElementById("report-form").addEventListener("submit", enviarReporte);
}

function cambiarFormulario(modo) {
  document.getElementById("login-form").hidden = modo !== "login";
  document.getElementById("register-form").hidden = modo !== "register";
}

async function manejarLogin(evento) {
  evento.preventDefault();
  const correo = document.getElementById("login-user").value.trim().toLowerCase();
  const contrasena = document.getElementById("login-password").value;
  const resultado = await enviarAccion({ accion: "login", correo, contrasena });
  if (!resultado.ok) {
    notificar(resultado.mensaje, "error");
    return;
  }
  entrarComo(resultado.usuario);
}

async function manejarRegistro(evento) {
  evento.preventDefault();
  const nombre = document.getElementById("register-user").value.trim();
  const correo = document.getElementById("register-email").value.trim().toLowerCase();
  const contrasena = document.getElementById("register-password").value;
  if (estado.usuarios.some(u => u.correo === correo)) {
    notificar("Ese correo ya está registrado", "error");
    return;
  }
  const resultado = await enviarAccion({ accion: "registro", nombre, correo, contrasena });
  if (!resultado.ok) {
    notificar(resultado.mensaje, "error");
    return;
  }
  notificar("Cuenta creada. ¡Bienvenido al abismo!");
  entrarComo(resultado.usuario);
}

function accesoDemo() {
  const usuario = estado.usuarios.find(u => u.rol === "usuario" && u.estado === "activo") || estado.usuarios[0];
  entrarComo(usuario);
}

function entrarComo(usuario) {
  usuarioActual = usuario;
  document.getElementById("auth-section").hidden = true;
  document.getElementById("admin-panel").classList.add("vista-oculta");

  if (usuario.rol === "admin") {
    document.getElementById("app-container").hidden = true;
    window.mostrarPanelAdmin(usuario);
  } else {
    document.getElementById("app-container").hidden = false;
    actualizarHUD();
    mostrarTab("statistics", document.querySelector('#sidebar-navigation [data-tab="statistics"]'));
    renderizarTienda();
    renderizarReportes();
    iniciarMapa();
  }
}

function cerrarSesion() {
  detenerRecorrido(true);
  usuarioActual = null;
  document.getElementById("app-container").hidden = true;
  document.getElementById("admin-panel").classList.add("vista-oculta");
  document.getElementById("auth-section").hidden = false;
}

function volverAVistaUsuario() {
  document.getElementById("admin-panel").classList.add("vista-oculta");
  document.getElementById("app-container").hidden = false;
  const usuario = estado.usuarios.find(u => u.rol === "usuario" && u.estado === "activo") || estado.usuarios[0];
  usuarioActual = usuario;
  actualizarHUD();
  renderizarTienda();
  renderizarReportes();
  iniciarMapa();
}

function actualizarHUD() {
  if (!usuarioActual) return;
  const stats = statsDe(usuarioActual);
  const usuario = estado.usuarios.find(u => u.id === usuarioActual.id) || usuarioActual;
  usuarioActual = usuario;
  document.getElementById("username").textContent = usuario.nombre;
  document.getElementById("user-level").textContent = `Nivel · ${usuario.nivel}`;
  document.getElementById("user-points").textContent = `${usuario.puntos} puntos`;
  document.getElementById("total-kilometers").textContent = `${stats.total_km.toFixed(1)} km`;
  document.getElementById("completed-routes").textContent = stats.rutas_completadas;
  document.getElementById("discovered-places").textContent = stats.lugares_descubiertos;
  renderizarHistorial();
}

function mostrarTab(id, boton) {
  document.querySelectorAll("#sidebar .tab-content").forEach(seccion => {
    seccion.hidden = seccion.id !== id;
  });
  document.querySelectorAll("#sidebar-navigation button").forEach(b => b.classList.remove("activo"));
  if (boton) boton.classList.add("activo");
  if (id === "mapa") return;
}

/* -------------------- Mapa -------------------- */

function iniciarMapa() {
  if (typeof L === "undefined") {
    notificar("El mapa no se pudo cargar (sin conexión)", "error");
    return;
  }
  if (!mapa) {
    mapa = L.map("map").setView(POS_INICIAL, 14);
    L.tileLayer("https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png", {
      attribution: "&copy; OpenStreetMap",
      maxZoom: 19,
    }).addTo(mapa);
    marcadorUsuario = L.marker(POS_INICIAL, { icon: iconoViajero() })
      .addTo(mapa)
      .bindPopup("<b>Tu posición</b><br>Viajero del abismo");
    estado.lugares.forEach(lugar => {
      L.marker([lugar.latitud, lugar.longitud])
        .addTo(mapa)
        .bindPopup(`<b>${lugar.nombre}</b><br>+${lugar.recompensa} puntos`);
    });
  }
  setTimeout(() => mapa.invalidateSize(), 180);
}

function buscarDestino(evento) {
  evento.preventDefault();
  const texto = document.getElementById("destination-input").value.trim().toLowerCase();
  const lugar = estado.lugares.find(l => l.nombre.toLowerCase().includes(texto));
  if (!lugar) {
    notificar("No encontré ese santuario en el mapa", "error");
    return;
  }
  if (!mapa) iniciarMapa();
  mapa.flyTo([lugar.latitud, lugar.longitud], 15, { duration: 1.1 });
  notificar(`Rumbo a ${lugar.nombre}`);
}

function centrarEnUsuario() {
  function centrar(coords) {
    posUsuario = [coords.latitude, coords.longitude];
    if (mapa) mapa.flyTo(posUsuario, 15);
    if (marcadorUsuario) marcadorUsuario.setLatLng(posUsuario);
    notificar("Ubicación actualizada");
  }
  if (navigator.geolocation) {
    navigator.geolocation.getCurrentPosition(
      centrar,
      () => { if (mapa) mapa.flyTo(POS_INICIAL, 14); notificar("Ubicación simulada en el mapa"); },
      { timeout: 6000 }
    );
  } else if (mapa) {
    mapa.flyTo(POS_INICIAL, 14);
  }
}

function iniciarRecorrido(simular) {
  if (intervaloRuta) detenerRecorrido(true);
  distanciaRuta = 0;
  document.getElementById("start-route").classList.add("activo");
  document.getElementById("simulate-route").classList.toggle("activo", simular);
  notificar(simular ? "Simulando recorrido..." : "Recorrido iniciado");

  let pasos = 0;
  intervaloRuta = setInterval(() => {
    posUsuario = [posUsuario[0] + 0.00035, posUsuario[1] + 0.00042];
    distanciaRuta += 0.05;
    if (marcadorUsuario) marcadorUsuario.setLatLng(posUsuario);
    if (mapa) mapa.panTo(posUsuario);

    if (lineaRuta && typeof L !== "undefined") mapa.removeLayer(lineaRuta);
    if (typeof L !== "undefined" && mapa) {
      lineaRuta = L.polyline([POS_INICIAL, posUsuario], {
        color: "#56c7f5", weight: 3, opacity: 0.85,
      }).addTo(mapa);
    }

    pasos += 1;
    if (simular && pasos >= 8) detenerRecorrido();
  }, 650);
}

function detenerRecorrido(sinGuardar = false) {
  if (!intervaloRuta) return;
  clearInterval(intervaloRuta);
  intervaloRuta = null;
  document.getElementById("start-route").classList.remove("activo");
  document.getElementById("simulate-route").classList.remove("activo");

  if (sinGuardar || distanciaRuta <= 0 || !usuarioActual) return;
  enviarAccion({
    accion: "guardar_ruta",
    usuario_id: usuarioActual.id,
    nombre: "Recorrido del abismo",
    latitud: posUsuario[0],
    longitud: posUsuario[1],
    distancia_km: Number(distanciaRuta.toFixed(2)),
  });
  notificar(`Ruta guardada: ${distanciaRuta.toFixed(2)} km`);
  actualizarHUD();
}

function renderizarHistorial() {
  const lista = document.getElementById("route-history");
  const rutas = estado.rutas.filter(r => r.usuario_id === usuarioActual.id).slice(0, 5);
  lista.innerHTML = rutas.length
    ? rutas.map(r => `<li><strong>${r.nombre}</strong>${Number(r.distancia_km).toFixed(1)} km · ${r.fecha}</li>`).join("")
    : "<li>No hay recorridos registrados.</li>";
}

/* -------------------- Tienda -------------------- */

function renderizarTienda() {
  const grid = document.querySelector(".store-grid");
  if (!grid || !usuarioActual) return;
  const puntos = estado.usuarios.find(u => u.id === usuarioActual.id).puntos;
  const inventario = estado.inventario.filter(i => i.usuario_id === usuarioActual.id);

  grid.innerHTML = estado.tienda.map(item => {
    const propio = inventario.some(i => i.item_codigo === item.codigo);
    const equipado = inventario.some(i => i.item_codigo === item.codigo && i.equipado);
    return `
      <article class="store-item ${equipado ? "equipado" : ""}">
        <h3><i class="fa-solid ${item.icono || "fa-gem"}"></i> ${item.nombre}</h3>
        <p>${item.descripcion}</p>
        <span>${item.precio} puntos</span>
        <button type="button" data-item="${item.codigo}" data-cost="${item.precio}" ${propio || puntos < item.precio ? "disabled" : ""}>
          ${propio ? "Adquirido" : "Canjear"}
        </button>
        <button type="button" data-equip="${item.codigo}" ${!propio ? "disabled" : ""}>
          ${equipado ? "Equipado" : "Equipar"}
        </button>
      </article>`;
  }).join("");

  grid.querySelectorAll("button[data-item]").forEach(b => {
    b.addEventListener("click", async () => {
      const resultado = await enviarAccion({ accion: "canjear", usuario_id: usuarioActual.id, codigo: b.dataset.item });
      notificar(resultado.ok ? "Objeto canjeado" : resultado.mensaje, resultado.ok ? "info" : "error");
      actualizarHUD();
      renderizarTienda();
    });
  });

  grid.querySelectorAll("button[data-equip]").forEach(b => {
    b.addEventListener("click", async () => {
      const codigo = b.dataset.equip;
      const resultado = await enviarAccion({ accion: "equipar", usuario_id: usuarioActual.id, codigo });
      if (!resultado.ok) return notificar(resultado.mensaje, "error");
      aplicarEquipamiento(codigo);
      notificar("Equipamiento actualizado");
      actualizarHUD();
      renderizarTienda();
    });
  });
}

function aplicarEquipamiento(codigo) {
  const mapaEl = document.getElementById("map");
  if (codigo === "cyberpunk-theme") mapaEl.classList.add("tema-cyberpunk");
  else mapaEl.classList.remove("tema-cyberpunk");
  document.body.style.cursor = codigo === "custom-cursor" ? "crosshair" : "";
  if (lineaRuta) lineaRuta.setStyle({ color: codigo === "neon-route" ? "#f0f4f8" : "#56c7f5" });
}

/* -------------------- Reportes -------------------- */

function usarUbicacionEnReporte() {
  document.getElementById("report-description").dataset.lat = posUsuario[0];
  document.getElementById("report-description").dataset.lng = posUsuario[1];
  notificar("Ubicación adjuntada al reporte");
}

async function enviarReporte(evento) {
  evento.preventDefault();
  const descripcion = document.getElementById("report-description").value.trim();
  const campo = document.getElementById("report-description");
  const resultado = await enviarAccion({
    accion: "crear_reporte",
    usuario_id: usuarioActual.id,
    tipo: document.getElementById("report-type").value,
    descripcion,
    latitud: Number(campo.dataset.lat || posUsuario[0]),
    longitud: Number(campo.dataset.lng || posUsuario[1]),
  });
  if (!resultado.ok) return notificar(resultado.mensaje, "error");
  evento.target.reset();
  delete campo.dataset.lat;
  delete campo.dataset.lng;
  notificar("Reporte enviado a la comunidad");
  renderizarReportes();
}

function renderizarReportes() {
  const lista = document.getElementById("reports-list");
  const reportes = estado.reportes.slice(0, 6);
  const nombres = { traffic: "Tráfico", construction: "Obras", place: "Punto de interés" };
  lista.innerHTML = reportes.length
    ? reportes.map(r => `<li><strong>${nombres[r.tipo] || r.tipo}</strong> ${r.descripcion}</li>`).join("")
    : "<li>No hay reportes disponibles.</li>";
}

window.iniciarInterfazUsuario = initUsuario;
