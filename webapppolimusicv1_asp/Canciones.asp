<%@ Language="VBScript" CodePage="65001" %>
<!--#include file="inc/config.asp"-->
<%
' ============================================================================
'  Canciones.asp - Listado de canciones (Song List)
'  Cumple la consigna: 2 roles, CRUD solo admin, mensaje de bienvenida con el
'  usuario de la variable de sesion, logout, texto de Song List, tabla HTML
'  con estilos y reproduccion de las canciones.
' ============================================================================
RequireLogin

Dim PageTitle, PageId
PageTitle = "Canciones"
PageId = "songs"
%>
<!--#include file="inc/header.asp"-->

<%' ------------------------------------------------- Mensaje de bienvenida %>
<section class="hero" style="padding:28px 30px;margin:4px 0 10px">
  <div class="hero-txt">
    <div class="hero-kicker">Bienvenido</div>
    <h1 style="font-size:clamp(26px,3.2vw,38px);margin-bottom:10px"><%=H(NombreVisible(Session("pm_uname") & ""))%></h1>
    <p style="margin-bottom:16px">
      Has iniciado sesión como <strong><%=H(Session("pm_uname") & "")%></strong> con el rol de
      <strong><%=IIfStr(IsAdmin(), "Administrador", "Usuario normal")%></strong>.
      <% If IsAdmin() Then %>
        Puedes crear, editar y eliminar canciones.
      <% Else %>
        Puedes escuchar las canciones del catálogo.
      <% End If %>
    </p>
    <div class="hero-actions">
      <a class="btn btn-ghost btn-sm" href="<%=U("Logout.asp")%>">
        <svg class="ico ico-sm"><use href="#i-logout"/></svg> Cerrar sesión
      </a>
      <a class="btn btn-ghost btn-sm" href="<%=U("Home.asp")%>">Ir al inicio</a>
    </div>
  </div>
</section>

<%' ------------------------------------------------------- Texto + acciones %>
<section class="section" style="margin-top:6px">
  <div class="section-head">
    <div>
      <h2>Song List</h2>
      <p>A continuación se presenta el listado de canciones disponibles en el catálogo de PoliMusic.</p>
    </div>
    <div class="row">
      <button class="btn btn-primary btn-sm" type="button" data-play-all>
        <svg class="ico ico-sm"><use href="#i-play"/></svg> Reproducir todo
      </button>
      <% If IsAdmin() Then %>
      <a class="btn btn-ghost btn-sm" href="<%=U("Admin/Songs.asp")%>?action=new">
        <svg class="ico ico-sm"><use href="#i-plus"/></svg> Nueva canción
      </a>
      <% End If %>
    </div>
  </div>

  <%' ----------------------------------------------------------- Tabla %>
  <div class="table-wrap">
    <table class="data table-songs">
      <thead>
        <tr>
          <th style="width:56px">#</th>
          <th>Song Name</th>
          <th>Artista</th>
          <th>Álbum</th>
          <th class="num" style="width:130px">Reproducciones</th>
          <th style="width:90px;text-align:center">Play</th>
          <% If IsAdmin() Then %>
          <th style="width:120px;text-align:right">Acciones</th>
          <% End If %>
        </tr>
      </thead>
      <tbody>
        <%
        Dim rsS, idx, sid, nm, cover, artist, albumName, albumId, artistId, url, plays
        idx = 0
        Set rsS = DbSelect(SongSql() & "ORDER BY s.SONG_NAME", Array())

        If rsS.EOF Then
            %>
            <tr><td colspan="<%=IIfStr(IsAdmin(), "7", "6")%>" style="text-align:center;padding:36px;color:var(--txt-3)">
              No hay canciones registradas en el catálogo.
            </td></tr>
            <%
        End If

        Do While Not rsS.EOF
            idx   = idx + 1
            sid   = CLng(rsS("ID_SONG"))
            nm    = rsS("SONG_NAME") & ""
            cover = MediaUrl(rsS("COVER"), "albumImages/default.png")
            artist = rsS("ARTIST") & ""
            albumName = rsS("ALBUM_NAME") & ""
            albumId = N(rsS("ALBUM_ID"))
            artistId = N(rsS("ARTIST_ID"))
            plays = N(rsS("PLAYS"))
            url   = MediaUrl(rsS("SONG_PATH"), "songFiles/bensound-adventure.mp3")

            QueueAdd sid, nm, url, cover, artist, albumName
            %>
            <tr class="song-row" data-song-id="<%=sid%>"
                data-name="<%=A(nm)%>" data-artist="<%=A(artist)%>"
                data-cover="<%=A(cover)%>" data-url="<%=A(url)%>">

              <td class="num" style="color:var(--txt-3)"><%=idx%></td>

              <td>
                <div class="cell-main">
                  <img src="<%=A(cover)%>" alt="">
                  <div>
                    <strong><%=H(nm)%></strong>
                    <small>ID #<%=sid%></small>
                  </div>
                </div>
              </td>

              <td>
                <% If artistId > 0 Then %>
                  <a href="<%=U("Artist.asp")%>?id=<%=artistId%>" style="color:var(--txt-2)"><%=H(artist)%></a>
                <% Else %>
                  <span class="muted">—</span>
                <% End If %>
              </td>

              <td>
                <% If albumId > 0 Then %>
                  <a href="<%=U("Album.asp")%>?id=<%=albumId%>" style="color:var(--txt-2)"><%=H(albumName)%></a>
                <% Else %>
                  <span class="muted">—</span>
                <% End If %>
              </td>

              <td class="num"><%=plays%></td>

              <td style="text-align:center">
                <button class="play-mini" type="button" data-play title="Reproducir <%=A(nm)%>"
                        aria-label="Reproducir <%=A(nm)%>">
                  <svg class="ico"><use href="#i-play"/></svg>
                </button>
              </td>

              <% If IsAdmin() Then %>
              <td>
                <div class="actions">
                  <a class="t-act" href="<%=U("Admin/Songs.asp")%>?action=edit&amp;id=<%=sid%>" title="Editar">
                    <svg class="ico ico-sm"><use href="#i-edit"/></svg>
                  </a>
                  <form method="post" action="<%=U("Admin/Songs.asp")%>" class="inline"
                        data-confirm="¿Eliminar la canción «<%=A(nm)%>»?">
                    <%=CsrfField()%>
                    <input type="hidden" name="action" value="delete">
                    <input type="hidden" name="song_id" value="<%=sid%>">
                    <button class="t-act danger" type="submit" title="Eliminar">
                      <svg class="ico ico-sm"><use href="#i-trash"/></svg>
                    </button>
                  </form>
                </div>
              </td>
              <% End If %>
            </tr>
            <%
            rsS.MoveNext
        Loop
        rsS.Close
        Set rsS = Nothing
        %>
      </tbody>
    </table>
  </div>

  <p class="muted" style="margin-top:12px;font-size:12.5px">
    Pulsa el botón <strong>Play</strong> de cualquier fila para escucharla. La reproducción continúa
    mientras navegas por el sitio.
  </p>
</section>

<%=QueueScript(False)%>

<!--#include file="inc/footer.asp"-->
