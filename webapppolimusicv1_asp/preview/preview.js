/* Vista previa: conecta los botones de reproduccion con player.js */
(function () {
  "use strict";

  function getQueue() {
    var el = document.getElementById("pm-queue");
    if (!el) return [];
    try { return JSON.parse(el.textContent).tracks || []; } catch (e) { return []; }
  }

  function playRow(row) {
    var q = getQueue();
    var id = row.getAttribute("data-song-id");
    for (var i = 0; i < q.length; i++) {
      if (String(q[i].id) === String(id)) {
        if (window.PoliPlayer.currentId() === String(id) && window.PoliPlayer.isPlaying()) {
          window.PoliPlayer.toggle();
        } else {
          window.PoliPlayer.playQueue(q, i);
        }
        return;
      }
    }
    var t = {
      id: id,
      name: row.getAttribute("data-name") || "",
      artist: row.getAttribute("data-artist") || "",
      cover: row.getAttribute("data-cover") || "",
      url: row.getAttribute("data-url") || ""
    };
    if (t.url) window.PoliPlayer.playTrack(t);
  }

  document.addEventListener("click", function (e) {
    var btn = e.target.closest("[data-play]");
    if (btn) {
      e.preventDefault();
      var row = btn.closest("[data-song-id]");
      if (row) playRow(row);
      else window.PoliPlayer.playQueue(getQueue(), 0);
      return;
    }
    var track = e.target.closest(".track[data-song-id]");
    if (track && !e.target.closest("a") && !e.target.closest("button")) playRow(track);
  });

  var menuBtn = document.getElementById("menuBtn");
  if (menuBtn) menuBtn.addEventListener("click", function () {
    document.body.classList.toggle("nav-open");
  });
  var scrim = document.getElementById("scrim");
  if (scrim) scrim.addEventListener("click", function () {
    document.body.classList.remove("nav-open");
  });
})();
