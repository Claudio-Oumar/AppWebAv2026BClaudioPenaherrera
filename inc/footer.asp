    </div><% ' /#main-view %>
  </main>
</div><% ' /#app %>

<div class="player" id="player">
  <div class="player-left">
    <div class="pl-cover-wrap">
      <img id="plCover" class="pl-cover" src="<%=U("albumImages/default.png")%>" alt="">
    </div>
    <div class="pl-meta">
      <span class="pl-title" id="plTitle">Sin reproducci&oacute;n</span>
      <span class="pl-artist" id="plArtist">Elige una canci&oacute;n</span>
    </div>
  </div>

  <div class="player-center">
    <div class="pl-controls">
      <button class="pl-btn" id="btnShuffle" type="button" title="Aleatorio" aria-label="Aleatorio">
        <svg class="ico"><use href="#i-shuffle"/></svg>
      </button>
      <button class="pl-btn" id="btnPrev" type="button" title="Anterior" aria-label="Anterior">
        <svg class="ico"><use href="#i-prev"/></svg>
      </button>
      <button class="pl-play" id="btnPlay" type="button" title="Reproducir" aria-label="Reproducir">
        <svg class="ico" id="playIcon"><use href="#i-play"/></svg>
      </button>
      <button class="pl-btn" id="btnNext" type="button" title="Siguiente" aria-label="Siguiente">
        <svg class="ico"><use href="#i-next"/></svg>
      </button>
      <button class="pl-btn" id="btnRepeat" type="button" title="Repetir" aria-label="Repetir">
        <svg class="ico" id="repeatIcon"><use href="#i-repeat"/></svg>
      </button>
    </div>
    <div class="pl-progress">
      <span class="pl-time" id="plCur">0:00</span>
      <input type="range" id="plSeek" class="range" min="0" max="100" step="0.1" value="0" aria-label="Progreso">
      <span class="pl-time" id="plDur">0:00</span>
    </div>
  </div>

  <div class="player-right">
    <button class="pl-btn" id="btnMute" type="button" title="Silenciar" aria-label="Silenciar">
      <svg class="ico" id="volIcon"><use href="#i-volume"/></svg>
    </button>
    <input type="range" id="plVol" class="range range-vol" min="0" max="1" step="0.01" value="0.8" aria-label="Volumen">
  </div>
</div>

<audio id="pmAudio" preload="metadata"></audio>
<div class="toasts" id="toasts" aria-live="polite"></div>

<script>window.PM_BASE = "<%=AppPath()%>";</script>
<script src="<%=U("Assets/Js/player.js")%>"></script>
<script src="<%=U("Assets/Js/app.js")%>"></script>
</body>
</html>
<%
DbClose
%>
