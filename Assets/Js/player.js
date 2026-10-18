/* ==========================================================================
   PoliMusic — Reproductor persistente
   Sobrevive a la navegacion (PJAX): la barra vive fuera de #main-view.
   ========================================================================== */
(function () {
  "use strict";

  var STORAGE = "pm_player_v1";
  var BASE = window.PM_BASE || "";

  var audio   = document.getElementById("pmAudio");
  if (!audio) return;

  var elCover = document.getElementById("plCover");
  var elTitle = document.getElementById("plTitle");
  var elArt   = document.getElementById("plArtist");
  var elPlay  = document.getElementById("btnPlay");
  var elIcon  = document.getElementById("playIcon");
  var elSeek  = document.getElementById("plSeek");
  var elCur   = document.getElementById("plCur");
  var elDur   = document.getElementById("plDur");
  var elVol   = document.getElementById("plVol");
  var elMute  = document.getElementById("btnMute");
  var elVolIc = document.getElementById("volIcon");
  var btnShuf = document.getElementById("btnShuffle");
  var btnRep  = document.getElementById("btnRepeat");
  var repIcon = document.getElementById("repeatIcon");

  var state = {
    queue: [],
    index: -1,
    shuffle: false,
    repeat: 0,          /* 0 off | 1 all | 2 one */
    volume: 0.8,
    muted: false,
    time: 0,
    playing: false
  };
  var counted = {};

  /* ---------------------------------------------------------------- utils */
  function fmt(s) {
    if (!isFinite(s) || s < 0) s = 0;
    var m = Math.floor(s / 60);
    var r = Math.floor(s % 60);
    return m + ":" + (r < 10 ? "0" : "") + r;
  }

  function icon(name) {
    return '<svg class="ico"><use href="#i-' + name + '"/></svg>';
  }

  function toast(msg, isErr) {
    var box = document.getElementById("toasts");
    if (!box) return;
    var t = document.createElement("div");
    t.className = "toast" + (isErr ? " err" : "");
    t.textContent = msg;
    box.appendChild(t);
    setTimeout(function () {
      t.style.opacity = "0";
      t.style.transition = "opacity .3s";
      setTimeout(function () { t.remove(); }, 320);
    }, 2600);
  }

  function current() {
    if (state.index < 0 || state.index >= state.queue.length) return null;
    return state.queue[state.index];
  }

  /* ------------------------------------------------------------ persistencia */
  function save() {
    try {
      localStorage.setItem(STORAGE, JSON.stringify({
        queue: state.queue,
        index: state.index,
        shuffle: state.shuffle,
        repeat: state.repeat,
        volume: state.volume,
        muted: state.muted,
        time: state.time
      }));
    } catch (e) { /* almacenamiento lleno o bloqueado */ }
  }

  function restore() {
    var raw;
    try { raw = localStorage.getItem(STORAGE); } catch (e) { return; }
    if (!raw) return;
    var d;
    try { d = JSON.parse(raw); } catch (e) { return; }
    if (!d || !d.queue || !d.queue.length) return;

    state.queue   = d.queue;
    state.index   = typeof d.index === "number" ? d.index : 0;
    state.shuffle = !!d.shuffle;
    state.repeat  = d.repeat || 0;
    state.volume  = typeof d.volume === "number" ? d.volume : 0.8;
    state.muted   = !!d.muted;

    var t = current();
    if (!t) return;
    audio.src = t.url;
    audio.volume = state.volume;
    audio.muted = state.muted;

    audio.addEventListener("loadedmetadata", function once() {
      audio.removeEventListener("loadedmetadata", once);
      if (d.time && d.time < audio.duration - 1) {
        audio.currentTime = d.time;
      }
    });
    paintTrack(t);
    paintModes();
  }

  /* ------------------------------------------------------------------- UI */
  function paintTrack(t) {
    if (!t) return;
    elCover.src = t.cover || (BASE + "/albumImages/default.png");
    elTitle.textContent = t.name || "Sin título";
    elArt.textContent = t.artist || "Artista desconocido";
    elTitle.title = t.name || "";
  }

  function paintModes() {
    btnShuf.classList.toggle("is-on", state.shuffle);
    btnRep.classList.toggle("is-on", state.repeat > 0);
    repIcon.innerHTML = '<use href="#i-' + (state.repeat === 2 ? "repeat-one" : "repeat") + '"/>';
    elVolIc.innerHTML = '<use href="#i-' + (state.muted || state.volume === 0 ? "volume-off" : "volume") + '"/>';
  }

  function paintPlay() {
    elIcon.innerHTML = '<use href="#i-' + (state.playing ? "pause" : "play") + '"/>';
    elPlay.setAttribute("aria-label", state.playing ? "Pausar" : "Reproducir");
    elPlay.title = state.playing ? "Pausar" : "Reproducir";
    document.body.classList.toggle("is-playing", state.playing);
    paintTrack(current());
  }

  function paintSeek() {
    var d = audio.duration || 0;
    var p = d > 0 ? (audio.currentTime / d) * 100 : 0;
    elSeek.value = p;
    elSeek.style.setProperty("--p", p + "%");
    elCur.textContent = fmt(audio.currentTime);
    elDur.textContent = fmt(d);
  }

  /* Resalta las filas de la cancion activa en cualquier lista visible */
  function refreshRows() {
    var id = current() ? String(current().id) : "";
    var rows = document.querySelectorAll("[data-song-id]");
    for (var i = 0; i < rows.length; i++) {
      var r = rows[i];
      var match = id && r.getAttribute("data-song-id") === id;
      r.classList.toggle("is-playing", !!match && state.playing);
      var btn = r.querySelector("[data-play]");
      if (btn) {
        var on = !!match && state.playing;
        btn.innerHTML = on ? icon("pause") : icon("play");
        btn.title = on ? "Pausar" : "Reproducir";
      }
      var idx = r.querySelector(".idx-num");
      if (idx) idx.innerHTML = (match && state.playing)
        ? '<span class="eq"><i></i><i></i><i></i><i></i></span>'
        : (r.getAttribute("data-index") || "");
    }
  }

  /* -------------------------------------------------------------- acciones */
  function load(i, autoplay) {
    if (i < 0 || i >= state.queue.length) return;
    state.index = i;
    var t = state.queue[i];
    audio.src = t.url;
    audio.load();
    paintTrack(t);
    paintSeek();
    refreshRows();
    save();

    if (autoplay !== false) {
      var p = audio.play();
      if (p && p.catch) {
        p.catch(function () {
          state.playing = false;
          paintPlay();
          refreshRows();
        });
      }
    }
    countPlay(t);
  }

  function countPlay(t) {
    if (!t || !t.id) return;
    if (counted[t.id]) return;
    counted[t.id] = true;
    try {
      fetch(BASE + "/Api/Play.asp?id=" + encodeURIComponent(t.id), {
        method: "POST", credentials: "same-origin", keepalive: true
      });
    } catch (e) { /* silencioso */ }
  }

  function next(auto) {
    if (!state.queue.length) return;
    if (state.repeat === 2 && auto) {
      audio.currentTime = 0;
      audio.play();
      return;
    }
    var i;
    if (state.shuffle && state.queue.length > 1) {
      do { i = Math.floor(Math.random() * state.queue.length); }
      while (i === state.index);
    } else {
      i = state.index + 1;
      if (i >= state.queue.length) {
        if (state.repeat === 1) { i = 0; }
        else {
          state.playing = false;
          audio.pause();
          paintPlay(); refreshRows();
          return;
        }
      }
    }
    load(i, true);
  }

  function prev() {
    if (audio.currentTime > 3) { audio.currentTime = 0; return; }
    if (!state.queue.length) return;
    var i = state.index - 1;
    if (i < 0) i = state.repeat === 1 ? state.queue.length - 1 : 0;
    load(i, true);
  }

  function toggle() {
    if (!current()) {
      if (state.queue.length) load(0, true);
      return;
    }
    if (audio.paused) {
      audio.play().catch(function () { toast("No se pudo reproducir el audio.", true); });
    } else {
      audio.pause();
    }
  }

  /* ---------------------------------------------------------------- eventos */
  audio.addEventListener("play",  function () { state.playing = true;  paintPlay(); refreshRows(); save(); });
  audio.addEventListener("pause", function () { state.playing = false; paintPlay(); refreshRows(); save(); });
  audio.addEventListener("timeupdate", function () {
    paintSeek();
    state.time = audio.currentTime;
  });
  audio.addEventListener("ended", function () { next(true); });
  audio.addEventListener("error", function () {
    if (current()) toast("No se pudo cargar «" + current().name + "».", true);
  });
  audio.addEventListener("loadedmetadata", paintSeek);

  elPlay.addEventListener("click", toggle);
  document.getElementById("btnNext").addEventListener("click", function () { next(false); });
  document.getElementById("btnPrev").addEventListener("click", prev);

  btnShuf.addEventListener("click", function () {
    state.shuffle = !state.shuffle;
    paintModes(); save();
    toast(state.shuffle ? "Aleatorio activado" : "Aleatorio desactivado");
  });

  btnRep.addEventListener("click", function () {
    state.repeat = (state.repeat + 1) % 3;
    paintModes(); save();
    toast(["Repetición desactivada", "Repetir todo", "Repetir una canción"][state.repeat]);
  });

  elSeek.addEventListener("input", function () {
    if (!audio.duration) return;
    audio.currentTime = (elSeek.value / 100) * audio.duration;
    paintSeek();
  });

  elVol.addEventListener("input", function () {
    state.volume = parseFloat(elVol.value);
    state.muted = state.volume === 0;
    audio.volume = state.volume;
    audio.muted = state.muted;
    elVol.style.setProperty("--p", (state.volume * 100) + "%");
    paintModes(); save();
  });

  elMute.addEventListener("click", function () {
    state.muted = !state.muted;
    audio.muted = state.muted;
    paintModes(); save();
  });

  document.addEventListener("keydown", function (e) {
    var tag = (e.target.tagName || "").toLowerCase();
    if (tag === "input" || tag === "textarea" || tag === "select") return;
    if (e.code === "Space") { e.preventDefault(); toggle(); }
    else if (e.code === "ArrowRight" && e.shiftKey) { next(false); }
    else if (e.code === "ArrowLeft" && e.shiftKey) { prev(); }
  });

  window.addEventListener("pagehide", save);

  /* ---------------------------------------------------------------- API */
  window.PoliPlayer = {
    playQueue: function (tracks, index) {
      if (!tracks || !tracks.length) return;
      state.queue = tracks;
      counted = {};
      load(index || 0, true);
      toast("Reproduciendo " + tracks.length + " canción" + (tracks.length === 1 ? "" : "es"));
    },
    playTrack: function (track) {
      state.queue = [track];
      counted = {};
      load(0, true);
    },
    toggle: toggle,
    next: function () { next(false); },
    prev: prev,
    currentId: function () { return current() ? String(current().id) : ""; },
    isPlaying: function () { return state.playing; },
    refreshRows: refreshRows,
    toast: toast
  };

  /* -------------------------------------------------------------- arranque */
  restore();
  elVol.value = state.volume;
  elVol.style.setProperty("--p", (state.volume * 100) + "%");
  paintModes();
  paintPlay();
  paintSeek();

  if ("mediaSession" in navigator) {
    try {
      navigator.mediaSession.setActionHandler("play", function () { audio.play(); });
      navigator.mediaSession.setActionHandler("pause", function () { audio.pause(); });
      navigator.mediaSession.setActionHandler("nexttrack", function () { next(false); });
      navigator.mediaSession.setActionHandler("previoustrack", prev);
    } catch (e) { /* no soportado */ }
  }

  audio.addEventListener("play", function () {
    if (!("mediaSession" in navigator) || !current()) return;
    try {
      navigator.mediaSession.metadata = new MediaMetadata({
        title: current().name || "",
        artist: current().artist || "PoliMusic",
        album: current().album || "",
        artwork: [{ src: current().cover, sizes: "512x512", type: "image/png" }]
      });
    } catch (e) { /* no soportado */ }
  });
})();
