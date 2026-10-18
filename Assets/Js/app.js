/* ==========================================================================
   PoliMusic — Navegacion tipo SPA (PJAX) e interacciones
   Las paginas siguen siendo ASP clasico renderizado en servidor; el JS solo
   intercambia #main-view para que el reproductor no se reinicie.
   ========================================================================== */
(function () {
  "use strict";

  var BASE = window.PM_BASE || "";
  var view = document.getElementById("main-view");
  var sidebar = document.getElementById("sidebar");
  var body = document.body;

  /* ------------------------------------------------------------ utilidades */
  function toast(msg, isErr) {
    if (window.PoliPlayer && window.PoliPlayer.toast) return window.PoliPlayer.toast(msg, isErr);
    var box = document.getElementById("toasts");
    if (!box) return;
    var t = document.createElement("div");
    t.className = "toast" + (isErr ? " err" : "");
    t.textContent = msg;
    box.appendChild(t);
    setTimeout(function () { t.remove(); }, 2600);
  }

  function internal(url) {
    if (!url) return false;
    if (url.charAt(0) === "#") return false;
    if (url.indexOf("mailto:") === 0 || url.indexOf("tel:") === 0 || url.indexOf("javascript:") === 0) return false;
    var a = document.createElement("a");
    a.href = url;
    if (a.host !== location.host) return false;
    return true;
  }

  /* ------------------------------------------------------------------ cola */
  function getQueue() {
    var el = document.getElementById("pm-queue");
    if (!el) return { tracks: [], autoplay: false };
    try {
      var data = JSON.parse(el.textContent || "{}");
      return { tracks: data.tracks || [], autoplay: el.getAttribute("data-autoplay") === "1" };
    } catch (e) {
      return { tracks: [], autoplay: false };
    }
  }

  function playAll() {
    var q = getQueue();
    if (!q.tracks.length) { toast("No hay canciones para reproducir.", true); return; }
    window.PoliPlayer.playQueue(q.tracks, 0);
  }

  function playRow(row) {
    var q = getQueue();
    var id = row.getAttribute("data-song-id");
    var idx = -1;
    for (var i = 0; i < q.tracks.length; i++) {
      if (String(q.tracks[i].id) === String(id)) { idx = i; break; }
    }

    if (idx === -1) {
      var track = {
        id: id,
        name: row.getAttribute("data-name") || "",
        artist: row.getAttribute("data-artist") || "",
        cover: row.getAttribute("data-cover") || "",
        url: row.getAttribute("data-url") || ""
      };
      if (!track.url) return;
      window.PoliPlayer.playTrack(track);
      return;
    }

    if (window.PoliPlayer.currentId() === String(id) && window.PoliPlayer.isPlaying()) {
      window.PoliPlayer.toggle();
    } else {
      window.PoliPlayer.playQueue(q.tracks, idx);
    }
  }

  /* ------------------------------------------------------------------ PJAX */
  var loading = false;

  function afterSwap() {
    closeNav();
    initFileInputs();
    var q = getQueue();
    if (window.PoliPlayer) window.PoliPlayer.refreshRows();
    if (q.autoplay && q.tracks.length) {
      setTimeout(playAll, 60);
      var el = document.getElementById("pm-queue");
      if (el) el.setAttribute("data-autoplay", "0");
    }
    var flash = view.querySelector(".flash");
    if (flash) setTimeout(function () {
      flash.style.transition = "opacity .4s";
      flash.style.opacity = "0";
      setTimeout(function () { flash.remove(); }, 420);
    }, 4800);
  }

  function syncTopbar(url) {
    var input = document.getElementById("searchInput");
    if (!input) return;
    try {
      var u = new URL(url, location.origin);
      input.value = u.searchParams.get("q") || "";
    } catch (e) { /* nada */ }
  }

  function navigate(url, push) {
    if (loading) return;
    loading = true;
    body.classList.add("is-loading");

    fetch(url, { headers: { "X-PJAX": "1" }, credentials: "same-origin" })
      .then(function (res) {
        if (!res.ok) throw new Error("http " + res.status);
        return res.text();
      })
      .then(function (html) {
        var doc = new DOMParser().parseFromString(html, "text/html");
        var newView = doc.getElementById("main-view");
        if (!newView) { location.href = url; return; }

        view.innerHTML = newView.innerHTML;
        var newSide = doc.querySelector(".sidebar");
        if (newSide && sidebar) sidebar.innerHTML = newSide.innerHTML;
        if (doc.body) body.setAttribute("data-page", doc.body.getAttribute("data-page") || "");
        document.title = doc.title || document.title;

        if (push) history.pushState({ pjax: 1 }, "", url);
        view.scrollTop = 0;
        syncTopbar(url);
        afterSwap();
      })
      .catch(function () { location.href = url; })
      .then(function () {
        loading = false;
        body.classList.remove("is-loading");
      });
  }

  window.addEventListener("popstate", function () {
    navigate(location.href, false);
  });

  document.addEventListener("click", function (e) {
    /* 1. Botones de reproduccion */
    var playBtn = e.target.closest("[data-play]");
    if (playBtn) {
      e.preventDefault();
      var row = playBtn.closest("[data-song-id]");
      if (row) { playRow(row); }
      else if (playBtn.hasAttribute("data-play-all")) { playAll(); }
      return;
    }

    /* 2. Reproducir todo */
    var allBtn = e.target.closest("[data-play-all]");
    if (allBtn) { e.preventDefault(); playAll(); return; }

    /* 3. Fila de cancion */
    var trackRow = e.target.closest(".track[data-song-id]");
    if (trackRow && !e.target.closest("a") && !e.target.closest("button")) {
      playRow(trackRow);
      return;
    }

    /* 4. Enlaces internos -> PJAX */
    var link = e.target.closest("a[href]");
    if (!link) return;
    if (link.target && link.target !== "_self") return;
    if (link.hasAttribute("download") || link.hasAttribute("data-no-pjax")) return;
    if (e.metaKey || e.ctrlKey || e.shiftKey || e.altKey) return;
    if (link.getAttribute("href").indexOf("#") === 0) return;

    if (link.closest(".usermenu")) {
      /* deja navegar, pero cierra el menu */
      document.querySelectorAll("details.usermenu[open]").forEach(function (d) { d.open = false; });
    }

    if (!internal(link.href)) return;
    if (link.href.split("#")[0] === location.href.split("#")[0]) return;

    e.preventDefault();
    navigate(link.href, true);
  });

  /* Buscador */
  var form = document.getElementById("searchForm");
  if (form) {
    form.addEventListener("submit", function (e) {
      e.preventDefault();
      var q = document.getElementById("searchInput").value.trim();
      var url = BASE + "/Search.asp" + (q ? "?q=" + encodeURIComponent(q) : "");
      if (q) navigate(url, true);
    });
  }

  /* ------------------------------------------------------------- interfaz */
  function closeNav() { body.classList.remove("nav-open"); }

  var menuBtn = document.getElementById("menuBtn");
  if (menuBtn) {
    menuBtn.addEventListener("click", function (e) {
      e.stopPropagation();
      body.classList.toggle("nav-open");
    });
  }

  document.addEventListener("click", function (e) {
    if (body.classList.contains("nav-open") && !e.target.closest("#sidebar") && !e.target.closest("#menuBtn")) {
      closeNav();
    }
    var open = document.querySelector("details.usermenu[open]");
    if (open && !e.target.closest("details.usermenu")) open.open = false;
  });

  document.addEventListener("click", function (e) {
    var h = e.target.closest("[data-history]");
    if (!h) return;
    if (h.getAttribute("data-history") === "back") history.back();
    else history.forward();
  });

  /* Confirmaciones de borrado */
  document.addEventListener("submit", function (e) {
    var f = e.target;
    if (f.hasAttribute && f.hasAttribute("data-confirm")) {
      if (!window.confirm(f.getAttribute("data-confirm"))) {
        e.preventDefault();
        return;
      }
    }
  });

  /* Inputs de archivo */
  function initFileInputs() {
    document.querySelectorAll(".file-drop input[type=file]").forEach(function (inp) {
      if (inp.dataset.ready) return;
      inp.dataset.ready = "1";
      inp.addEventListener("change", function () {
        var label = inp.closest(".file-drop").querySelector(".file-name");
        if (!label) return;
        if (inp.files && inp.files.length) {
          label.textContent = inp.files[0].name + " · " + Math.round(inp.files[0].size / 1024) + " KB";
          label.style.color = "#c084fc";
        } else {
          label.textContent = label.getAttribute("data-empty") || "Ningún archivo seleccionado";
          label.style.color = "";
        }
      });
    });
  }

  /* Arranque */
  initFileInputs();
  afterSwap();
})();
