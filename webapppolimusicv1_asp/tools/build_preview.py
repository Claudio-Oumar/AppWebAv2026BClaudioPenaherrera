"""Genera una vista previa navegable (HTML estatico) de las pantallas de PoliMusic.

Usa exactamente el mismo CSS, JS y recursos que la aplicacion ASP, para poder
revisar el diseno sin necesidad de IIS.
"""
import io, os, json

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT = os.path.join(ROOT, 'preview')
os.makedirs(OUT, exist_ok=True)

with io.open(os.path.join(ROOT, 'inc', 'icons.asp'), encoding='utf-8') as f:
    SPRITE = f.read()

USER_ADMIN = dict(name='userAdmin', role='Administrador', photo='../userImages/root.png')
USER_NORMAL = dict(name='Claudio Peñaherrera', role='Usuario', photo='../userImages/default.jpg')

ALBUMS = [
    ('album1.png', 'Rock Album', 'Juan Gabriel · 1976'),
    ('album2.png', 'Relax Music', 'Ana Gabriel · 2000'),
    ('album3.png', 'Retro Album Music', 'Mariah Carey · 1980'),
    ('album4.png', 'Classic Album', 'Elvis Presley · 1950'),
    ('album5.png', 'Country Album', 'Edward Sheeran · 1990'),
]
ARTISTS = ['Juan Gabriel', 'Ana Gabriel', 'Mariah Carey', 'Elvis Presley', 'Edward Sheeran']
PLAYLISTS = [
    ('playlist1.png', 'Nocturno 01', '3 canciones · Pública'),
    ('playlist2.png', 'Estudio profundo', '3 canciones · Privada'),
    ('playlist3.png', 'Ruta al amanecer', '3 canciones · Pública'),
    ('default.jpg', 'Playlist 1', '5 canciones · Privada'),
]
# (id, nombre, plays)
SONGS = [
    (5, 'Tomorrow', 4), (4, 'Scifi', 3), (3, 'Energy', 2), (2, 'Dreams', 1), (1, 'Adventure', 0),
]
COVER = '../albumImages/album1.png'
ARTIST = 'Juan Gabriel'
ALBUM = 'Rock Album'


def song_url(name):
    return '../songFiles/bensound-%s.mp3' % name.lower()


def queue_script(rows):
    tracks = [dict(id=i, name=n, url=song_url(n), cover=COVER, artist=ARTIST, album=ALBUM)
              for i, n, _ in rows]
    return ('<script type="application/json" id="pm-queue" data-autoplay="0">'
            + json.dumps({'tracks': tracks}, ensure_ascii=False) + '</script>')


def card(href, img, title, sub, round_=False):
    cls = 'card-art round' if round_ else 'card-art'
    return f'''<div class="card">
      <div class="{cls}">
        <a href="{href}"><img src="../{img}" alt="" loading="lazy"></a>
        <a class="card-play" href="{href}" title="Reproducir"><svg class="ico"><use href="#i-play"/></svg></a>
      </div>
      <a class="card-title" href="{href}">{title}</a>
      <p class="card-sub">{sub}</p>
    </div>'''


def track_row(idx, sid, name, plays, remove=False, show_album=True):
    album_cell = f'<a href="album.html">{ALBUM}</a>' if show_album else ALBUM
    remove_btn = ''
    if remove:
        remove_btn = ('<button class="t-act danger" type="button" title="Quitar de la playlist">'
                      '<svg class="ico ico-sm"><use href="#i-trash"/></svg></button>')
    return f'''<div class="track" data-song-id="{sid}" data-index="{idx}" data-name="{name}"
         data-artist="{ARTIST}" data-cover="{COVER}" data-url="{song_url(name)}">
      <div class="t-idx"><span class="idx-num">{idx}</span>
        <button class="idx-play" type="button" data-play aria-label="Reproducir">
          <svg class="ico"><use href="#i-play"/></svg></button></div>
      <div class="t-main"><img class="t-cover" src="{COVER}" alt="">
        <div class="t-txt"><span class="t-name">{name}</span>
          <span class="t-artist"><a href="album.html">{ARTIST}</a></span></div></div>
      <div class="t-album">{album_cell}</div>
      <div class="t-plays">{plays} reps.</div>
      <div class="t-actions">{remove_btn}</div>
    </div>'''


def track_head(show_album=True):
    alb = '<span class="th-album">Álbum</span>' if show_album else ''
    return f'''<div class="track-head"><span style="text-align:right">#</span><span>Título</span>{alb}
      <span style="text-align:right" class="th-plays">Reproducciones</span><span></span></div>'''


def sidebar(active, user, is_admin):
    def nav(key, href, icon, label):
        cls = 'nav-item is-active' if active == key else 'nav-item'
        return (f'<a class="{cls}" href="{href}"><svg class="ico"><use href="#i-{icon}"/></svg>'
                f'<span>{label}</span></a>')

    def side(key, href, icon, label):
        cls = 'side-link is-active' if active == key else 'side-link'
        return (f'<a class="{cls}" href="{href}"><svg class="ico"><use href="#i-{icon}"/></svg>'
                f'<span>{label}</span></a>')

    pls = ''.join(
        f'<a class="side-pl{" is-active" if active == "pl-" + t else ""}" href="playlist.html">'
        f'<img src="../playlistImages/{img}" alt=""><span>{t}</span></a>'
        for img, t, _ in PLAYLISTS)

    admin_block = ''
    if is_admin:
        admin_block = f'''<div class="side-block side-admin">
      <div class="side-head"><span><svg class="ico ico-sm"><use href="#i-shield"/></svg> Administración</span></div>
      <div class="side-list">
        {side('admin-users', 'admin-users.html', 'users', 'Usuarios')}
        {side('admin-songs', 'admin-users.html', 'music', 'Canciones')}
        {side('admin-artists', 'admin-users.html', 'mic', 'Artistas')}
        {side('admin-albums', 'admin-users.html', 'disc', 'Álbumes')}
        {side('admin-playlists', 'admin-users.html', 'list', 'Playlists')}
      </div>
    </div>'''

    return f'''<aside class="sidebar" id="sidebar">
    <a class="brand" href="home.html">
      <span class="brand-mark"><svg width="20" height="20"><use href="#i-music"/></svg></span>
      <span class="brand-name">PoliMusic</span>
    </a>
    <nav class="nav">
      {nav('home', 'home.html', 'home', 'Inicio')}
      {nav('search', 'home.html', 'search', 'Buscar')}
      {nav('songs', 'canciones.html', 'music', 'Canciones')}
      {nav('playlists', 'playlist.html', 'library', 'Tu biblioteca')}
    </nav>
    <div class="side-block">
      <div class="side-head"><span>Playlists</span>
        <a class="side-add" href="playlist.html" title="Crear playlist">
          <svg class="ico"><use href="#i-plus"/></svg></a></div>
      <div class="side-list">{pls}</div>
    </div>
    {admin_block}
    <div class="side-foot">
      <a class="user-chip" href="home.html">
        <img class="avatar" src="{user['photo']}" alt="">
        <span class="user-chip-txt"><strong>{user['name']}</strong><em>{user['role']}</em></span>
      </a>
      <a class="logout-btn" href="index.html" title="Cerrar sesión">
        <svg class="ico"><use href="#i-logout"/></svg></a>
    </div>
  </aside>'''


def topbar(user):
    return f'''<header class="topbar">
      <button class="icon-btn only-mobile" id="menuBtn" type="button" aria-label="Menú">
        <svg class="ico"><use href="#i-menu"/></svg></button>
      <div class="history only-desktop">
        <button class="icon-btn" type="button"><svg class="ico"><use href="#i-chevron-left"/></svg></button>
        <button class="icon-btn" type="button"><svg class="ico"><use href="#i-chevron-right"/></svg></button>
      </div>
      <form class="searchbar" onsubmit="return false">
        <svg class="ico"><use href="#i-search"/></svg>
        <input type="search" placeholder="¿Qué quieres escuchar?" aria-label="Buscar">
        <button type="submit" class="searchbar-go">Enter</button>
      </form>
      <div class="topbar-right">
        <a class="pill-btn only-desktop" href="playlist.html">
          <svg class="ico ico-sm"><use href="#i-plus"/></svg> Nueva playlist</a>
        <details class="usermenu">
          <summary>
            <img class="avatar" src="{user['photo']}" alt="">
            <span class="usermenu-name only-desktop">{user['name']}</span>
            <svg class="ico ico-sm"><use href="#i-chevron-down"/></svg>
          </summary>
          <div class="usermenu-pop">
            <a href="home.html"><svg class="ico ico-sm"><use href="#i-user"/></svg> Mi perfil</a>
            <a href="playlist.html"><svg class="ico ico-sm"><use href="#i-library"/></svg> Mis playlists</a>
            <a href="admin-users.html"><svg class="ico ico-sm"><use href="#i-shield"/></svg> Panel de administración</a>
            <hr>
            <a class="danger" href="index.html"><svg class="ico ico-sm"><use href="#i-logout"/></svg> Cerrar sesión</a>
          </div>
        </details>
      </div>
    </header>'''


PLAYER = '''<div class="player" id="player">
  <div class="player-left">
    <div class="pl-cover-wrap"><img id="plCover" class="pl-cover" src="../albumImages/album1.png" alt=""></div>
    <div class="pl-meta">
      <span class="pl-title" id="plTitle">Sin reproducción</span>
      <span class="pl-artist" id="plArtist">Elige una canción</span>
    </div>
  </div>
  <div class="player-center">
    <div class="pl-controls">
      <button class="pl-btn" id="btnShuffle" type="button" title="Aleatorio"><svg class="ico"><use href="#i-shuffle"/></svg></button>
      <button class="pl-btn" id="btnPrev" type="button" title="Anterior"><svg class="ico"><use href="#i-prev"/></svg></button>
      <button class="pl-play" id="btnPlay" type="button" title="Reproducir">
        <svg class="ico" id="playIcon"><use href="#i-play"/></svg></button>
      <button class="pl-btn" id="btnNext" type="button" title="Siguiente"><svg class="ico"><use href="#i-next"/></svg></button>
      <button class="pl-btn" id="btnRepeat" type="button" title="Repetir">
        <svg class="ico" id="repeatIcon"><use href="#i-repeat"/></svg></button>
    </div>
    <div class="pl-progress">
      <span class="pl-time" id="plCur">0:00</span>
      <input type="range" id="plSeek" class="range" min="0" max="100" step="0.1" value="0">
      <span class="pl-time" id="plDur">0:00</span>
    </div>
  </div>
  <div class="player-right">
    <button class="pl-btn" id="btnMute" type="button" title="Silenciar">
      <svg class="ico" id="volIcon"><use href="#i-volume"/></svg></button>
    <input type="range" id="plVol" class="range range-vol" min="0" max="1" step="0.01" value="0.8">
  </div>
</div>
<audio id="pmAudio" preload="metadata"></audio>
<div class="toasts" id="toasts"></div>'''


def shell(title, page, content, extra='', user=None, is_admin=False):
    if user is None:
        user = USER_NORMAL
    return f'''<!DOCTYPE html>
<html lang="es">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<meta name="theme-color" content="#0b0710">
<title>{title} · PoliMusic</title>
<link rel="stylesheet" href="../Assets/Css/app.css">
</head>
<body data-page="{page}">
{SPRITE}
<div class="app" id="app">
  {sidebar(page, user, is_admin)}
  <div class="scrim" id="scrim"></div>
  <main class="main">
    {topbar(user)}
    <div class="view" id="main-view">
      {content}
      {extra}
    </div>
  </main>
</div>
{PLAYER}
<script>window.PM_BASE = "";</script>
<script src="../Assets/Js/player.js"></script>
<script src="preview.js"></script>
</body>
</html>'''


# --------------------------------------------------------------------------- home
def home():
    pl_cards = ''.join(card('playlist.html', 'playlistImages/' + p[0], p[1], p[2]) for p in PLAYLISTS)
    song_cards = ''.join(
        f'''<div class="card" data-song-id="{i}" data-index="{k+1}" data-name="{n}"
             data-artist="{ARTIST}" data-cover="{COVER}" data-url="{song_url(n)}">
          <div class="card-art"><img src="{COVER}" alt="" loading="lazy">
            <button class="card-play" type="button" data-play title="Reproducir">
              <svg class="ico"><use href="#i-play"/></svg></button></div>
          <span class="card-title">{n}</span>
          <p class="card-sub">{ARTIST}</p></div>'''
        for k, (i, n, _) in enumerate(SONGS))

    album_cards = ''.join(card('album.html', 'albumImages/' + a[0], a[1], a[2]) for a in ALBUMS)
    artist_cards = ''.join(
        card('album.html', 'ArtistImages/artist%d.jpg' % (i + 1), n, '5 canciones', True)
        for i, n in enumerate(ARTISTS))

    content = f'''
      <p class="hero-kicker" style="margin:0 0 10px 6px">Bienvenido, {USER_NORMAL['name']}</p>

      <section class="hero">
        <div class="hero-txt">
          <div class="hero-kicker">Álbum destacado</div>
          <h1>Rock Album</h1>
          <p>Rock Album · 1976 · 5 canciones. Dale play y deja que el morado suene.</p>
          <div class="hero-actions">
            <a class="btn btn-primary" href="album.html">
              <svg class="ico ico-sm"><use href="#i-play"/></svg> Reproducir</a>
            <a class="btn btn-ghost" href="album.html">Ver álbum</a>
          </div>
        </div>
        <img class="hero-art" src="../albumImages/album1.png" alt="Rock Album">
      </section>

      <section class="section">
        <div class="section-head"><div><h2>Tus playlists</h2>
          <p>Crea, edita y organiza tu música</p></div>
          <a class="section-link" href="playlist.html">Ver todas</a></div>
        <div class="grid">
          <a class="card" href="playlist.html"
             style="justify-content:center;align-items:center;text-align:center;min-height:150px;border-style:dashed">
            <span style="width:46px;height:46px;border-radius:50%;display:grid;place-items:center;
                  background:var(--accent-soft);color:var(--accent-3);margin-bottom:10px">
              <svg class="ico"><use href="#i-plus"/></svg></span>
            <span class="card-title" style="margin:0">Nueva playlist</span>
            <span class="card-sub">Empieza desde cero</span>
          </a>
          {pl_cards}
        </div>
      </section>

      <section class="section">
        <div class="section-head"><div><h2>Lo más escuchado</h2>
          <p>Las canciones con más reproducciones del catálogo</p></div>
          <a class="section-link" href="home.html">Explorar</a></div>
        <div class="grid grid-tight">{song_cards}</div>
      </section>

      <section class="section">
        <div class="section-head"><div><h2>Álbumes</h2>
          <p>Colecciones completas para escuchar de principio a fin</p></div></div>
        <div class="grid">{album_cards}</div>
      </section>

      <section class="section">
        <div class="section-head"><div><h2>Artistas populares</h2>
          <p>Las voces detrás de las canciones</p></div></div>
        <div class="grid grid-tight">{artist_cards}</div>
      </section>
'''
    return shell('Inicio', 'home', content, queue_script(SONGS))


# ----------------------------------------------------------------------- canciones
def canciones(is_admin=False):
    user = USER_ADMIN if is_admin else USER_NORMAL
    rows = sorted(SONGS, key=lambda s: s[1])
    body = ''
    for i, (sid, n, p) in enumerate(rows):
        actions = ''
        if is_admin:
            actions = f'''<td><div class="actions">
              <button class="t-act" type="button" title="Editar"><svg class="ico ico-sm"><use href="#i-edit"/></svg></button>
              <button class="t-act danger" type="button" title="Eliminar"><svg class="ico ico-sm"><use href="#i-trash"/></svg></button>
            </div></td>'''
        body += f'''<tr class="song-row" data-song-id="{sid}" data-name="{n}" data-artist="{ARTIST}"
             data-cover="{COVER}" data-url="{song_url(n)}">
          <td class="num" style="color:var(--txt-3)">{i + 1}</td>
          <td><div class="cell-main"><img src="{COVER}" alt="">
            <div><strong>{n}</strong><small>ID #{sid}</small></div></div></td>
          <td><a href="album.html" style="color:var(--txt-2)">{ARTIST}</a></td>
          <td><a href="album.html" style="color:var(--txt-2)">{ALBUM}</a></td>
          <td class="num">{p}</td>
          <td style="text-align:center"><button class="play-mini" type="button" data-play title="Reproducir {n}">
            <svg class="ico"><use href="#i-play"/></svg></button></td>
          {actions}
        </tr>'''

    actions_head = '<th style="width:120px;text-align:right">Acciones</th>' if is_admin else ''
    new_btn = ('<a class="btn btn-ghost btn-sm" href="admin-users.html">'
               '<svg class="ico ico-sm"><use href="#i-plus"/></svg> Nueva canción</a>') if is_admin else ''

    content = f'''
      <section class="hero" style="padding:28px 30px;margin:4px 0 10px">
        <div class="hero-txt">
          <div class="hero-kicker">Bienvenido</div>
          <h1 style="font-size:clamp(26px,3.2vw,38px);margin-bottom:10px">{user['name']}</h1>
          <p style="margin-bottom:16px">Has iniciado sesión como <strong>{user['name']}</strong> con el rol de
            <strong>{user['role']}</strong>.
            {'Puedes crear, editar y eliminar canciones.' if is_admin else 'Puedes escuchar las canciones del catálogo.'}</p>
          <div class="hero-actions">
            <a class="btn btn-ghost btn-sm" href="index.html">
              <svg class="ico ico-sm"><use href="#i-logout"/></svg> Cerrar sesión</a>
            <a class="btn btn-ghost btn-sm" href="home.html">Ir al inicio</a>
          </div>
        </div>
      </section>

      <section class="section" style="margin-top:6px">
        <div class="section-head">
          <div><h2>Song List</h2>
            <p>A continuación se presenta el listado de canciones disponibles en el catálogo de PoliMusic.</p></div>
          <div class="row">
            <button class="btn btn-primary btn-sm" type="button" data-play-all>
              <svg class="ico ico-sm"><use href="#i-play"/></svg> Reproducir todo</button>
            {new_btn}
          </div>
        </div>

        <div class="table-wrap">
          <table class="data table-songs">
            <thead><tr>
              <th style="width:56px">#</th><th>Song Name</th><th>Artista</th><th>Álbum</th>
              <th class="num" style="width:130px">Reproducciones</th>
              <th style="width:90px;text-align:center">Play</th>{actions_head}
            </tr></thead>
            <tbody>{body}</tbody>
          </table>
        </div>

        <p class="muted" style="margin-top:12px;font-size:12.5px">
          Pulsa el botón <strong>Play</strong> de cualquier fila para escucharla. La reproducción continúa
          mientras navegas por el sitio.
        </p>
      </section>
    '''
    return shell('Canciones', 'songs', content, queue_script(sorted(SONGS, key=lambda s: s[1])),
                 user=user, is_admin=is_admin)


# -------------------------------------------------------------------------- album
def album():
    rows = sorted(SONGS, key=lambda s: s[1])
    body = ''.join(track_row(i + 1, sid, n, p, False, False) for i, (sid, n, p) in enumerate(rows))
    content = f'''
      <div class="detail-head">
        <img class="detail-art" src="../albumImages/album1.png" alt="Rock Album">
        <div class="detail-info">
          <div class="detail-kind">Álbum</div>
          <h1>Rock Album</h1>
          <div class="detail-meta">
            <strong><a href="album.html" style="color:var(--txt)">Juan Gabriel</a></strong>
            <span class="dot">·</span><span>1976</span>
            <span class="dot">·</span><span>5 canciones</span>
            <span class="dot">·</span><span>10 reproducciones</span>
          </div>
        </div>
      </div>
      <div class="detail-actions">
        <a class="btn btn-primary" href="album.html"><svg class="ico ico-sm"><use href="#i-play"/></svg> Reproducir</a>
        <a class="btn btn-ghost btn-sm" href="admin-users.html"><svg class="ico ico-sm"><use href="#i-edit"/></svg> Editar álbum</a>
      </div>
      <section class="section" style="margin-top:10px">
        {track_head(False)}
        <div class="tracklist">{body}</div>
      </section>
    '''
    return shell('Rock Album', 'album', content, queue_script(rows))


# ----------------------------------------------------------------------- playlist
def playlist():
    rows = [(2, 'Dreams', 1), (4, 'Scifi', 3), (5, 'Tomorrow', 4)]
    body = ''.join(track_row(i + 1, sid, n, p, True, True) for i, (sid, n, p) in enumerate(rows))
    content = f'''
      <div class="detail-head">
        <img class="detail-art" src="../playlistImages/playlist1.png" alt="Nocturno 01">
        <div class="detail-info">
          <div class="detail-kind">Playlist pública</div>
          <h1>Nocturno 01</h1>
          <div class="detail-meta">
            <strong>Claudio Penaherrera</strong>
            <span class="dot">·</span><span>3 canciones</span>
            <span class="dot">·</span><span>12 dic 2026</span>
            <span class="badge badge-public"><svg class="ico ico-sm"><use href="#i-globe"/></svg> Pública</span>
          </div>
        </div>
      </div>
      <div class="detail-actions">
        <a class="btn btn-primary" href="playlist.html"><svg class="ico ico-sm"><use href="#i-play"/></svg> Reproducir</a>
        <a class="btn btn-ghost btn-sm" href="playlist.html"><svg class="ico ico-sm"><use href="#i-plus"/></svg> Añadir canciones</a>
        <a class="btn btn-ghost btn-sm" href="playlist.html"><svg class="ico ico-sm"><use href="#i-edit"/></svg> Editar</a>
        <button class="btn btn-danger btn-sm" type="button" style="margin-left:auto">
          <svg class="ico ico-sm"><use href="#i-trash"/></svg> Eliminar</button>
      </div>
      <section class="section">
        {track_head(True)}
        <div class="tracklist">{body}</div>
      </section>
    '''
    return shell('Nocturno 01', 'playlist', content, queue_script(rows))


# -------------------------------------------------------------------------- admin
def admin():
    users = [
        ('Claudio Penaherrera', 1, 'claudio.penaherrera@epn.edu.ec', 0, '15 dic 2000', 4, '../userImages/default.jpg'),
        ('userAdmin', 2, 'admin@polimusic.ec', 1, '16 dic 2001', 0, '../userImages/root.png'),
        ('username1', 3, 'username1@epn.edu.ec', 0, '2 feb 2002', 0, '../userImages/username1.png'),
    ]
    rows = ''
    for name, uid, mail, utype, birth, pls, photo in users:
        badge = 'badge-admin' if utype == 1 else 'badge-user'
        label = 'Admin' if utype == 1 else 'Usuario'
        rows += f'''<tr>
          <td><div class="cell-main"><img src="{photo}" alt="">
            <div><strong>{name}</strong><small>#{uid}</small></div></div></td>
          <td>{mail}</td>
          <td><span class="badge {badge}">{label}</span></td>
          <td>{birth}</td>
          <td class="num">{pls}</td>
          <td><div class="actions">
            <button class="t-act" type="button" title="Editar"><svg class="ico ico-sm"><use href="#i-edit"/></svg></button>
            <button class="t-act danger" type="button" title="Eliminar"><svg class="ico ico-sm"><use href="#i-trash"/></svg></button>
          </div></td></tr>'''

    content = f'''
      <div class="section" style="margin-top:6px">
        <div class="section-head">
          <div><h2>Usuarios</h2><p>Administra las cuentas y los roles del sistema.</p></div>
          <a class="btn btn-primary btn-sm" href="admin-users.html">
            <svg class="ico ico-sm"><use href="#i-plus"/></svg> Nuevo usuario</a>
        </div>
      </div>
      <div class="stats">
        <div class="stat accent"><span>Total usuarios</span><strong>3</strong></div>
        <div class="stat"><span>Administradores</span><strong>1</strong></div>
        <div class="stat"><span>Usuarios normales</span><strong>2</strong></div>
      </div>
      <section class="section">
        <div class="table-wrap">
          <table class="data">
            <thead><tr><th>Usuario</th><th>Correo</th><th>Rol</th><th>Nacimiento</th>
              <th class="num">Playlists</th><th style="text-align:right">Acciones</th></tr></thead>
            <tbody>{rows}</tbody>
          </table>
        </div>
      </section>
    '''
    return shell('Usuarios', 'admin-users', content, user=USER_ADMIN, is_admin=True)


# -------------------------------------------------------------------------- login
def login():
    accounts = [
        ('Claudio Penaherrera', 'Usuario', 'contraseña SHA1'),
        ('userAdmin', 'Administrador', 'contraseña SHA1'),
        ('username1', 'Usuario', 'contraseña SHA1'),
    ]
    demo = ''.join(f'{n} &middot; {r} &middot; <code>{p}</code><br>' for n, r, p in accounts)

    return f'''<!DOCTYPE html>
<html lang="es">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>Iniciar sesión · PoliMusic</title>
<link rel="stylesheet" href="../Assets/Css/app.css">
</head>
<body class="auth-body">
{SPRITE}
<div class="auth">
  <section class="auth-art">
    <div class="auth-logo">
      <span class="brand-mark"><svg width="20" height="20"><use href="#i-music"/></svg></span>
      PoliMusic
    </div>
    <div>
      <h2>Tu música suena mejor en morado.</h2>
      <p>Miles de canciones, álbumes y artistas en un solo lugar. Crea tus playlists y escúchalas donde quieras.</p>
      <ul>
        <li><svg class="ico ico-sm"><use href="#i-play"/></svg> Reproducción continua mientras navegas</li>
        <li><svg class="ico ico-sm"><use href="#i-heart"/></svg> Playlists públicas y privadas</li>
        <li><svg class="ico ico-sm"><use href="#i-disc"/></svg> Álbumes, artistas y catálogo completo</li>
      </ul>
    </div>
    <footer>&copy; 2026 PoliMusic · Escuela Politécnica Nacional</footer>
  </section>

  <section class="auth-panel">
    <div class="auth-card">
      <h1>Bienvenido de nuevo</h1>
      <p class="sub">Inicia sesión para continuar escuchando.</p>
      <form onsubmit="window.location.href='home.html'; return false;">
        <div class="field"><label for="u">Usuario</label>
          <input class="input" id="u" type="text" placeholder="Tu nombre de usuario" value="userAdmin"></div>
        <div class="field"><label for="p">Contraseña</label>
          <input class="input" id="p" type="password" placeholder="••••••••" value="12345678"></div>
        <button class="btn btn-primary btn-block" type="submit">
          <svg class="ico ico-sm"><use href="#i-arrow-right"/></svg> Entrar</button>
      </form>
      <p class="auth-alt">¿No tienes cuenta? <a href="index.html">Regístrate gratis</a></p>
      <div class="demo-box">
        <strong>Cuentas en tu base de datos</strong><br>{demo}
      </div>
    </div>
  </section>
</div>
</body>
</html>'''


PAGES = {
    'index.html': login(),
    'home.html': home(),
    'canciones.html': canciones(False),
    'canciones-admin.html': canciones(True),
    'album.html': album(),
    'playlist.html': playlist(),
    'admin-users.html': admin(),
}

for name, html in PAGES.items():
    with io.open(os.path.join(OUT, name), 'w', encoding='utf-8') as f:
        f.write(html)
    print('->', name)

PREVIEW_JS = '''/* Vista previa: conecta los botones de reproduccion con player.js */
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
'''

with io.open(os.path.join(OUT, 'preview.js'), 'w', encoding='utf-8') as f:
    f.write(PREVIEW_JS)
print('-> preview.js')
