<%@ Language="VBScript" CodePage="65001" %>
<!--#include file="inc/config.asp"-->
<%
RequireLogin
InitPost

Dim PageTitle, PageId
PageId = "playlist"

Dim plId, action, doAutoplay
plId = N(QS("id"))
If plId = 0 Then plId = N(PostVal("playlist_id"))
action = LCase(QS("action"))
If Len(action) = 0 Then action = LCase(PostVal("action"))
doAutoplay = (QS("autoplay") = "1")

Dim plTitle, plPhoto, plType, plDate, plOwnerId, plOwner, plFound, canEdit, isOwner
plFound = False
canEdit = False
isOwner = False
plTitle = ""
plPhoto = "playlistImages/default.jpg"
plType = 0
plOwner = ""
plOwnerId = 0

If plId > 0 Then
    Dim rsP
    Set rsP = DbSelect("SELECT p.ID_PLAYLIST, p.ID_USER, p.TITLE, p.CREATION_DATE, p.TYPE, p.PHOTO, u.USERNAME " & _
                       "FROM TBL_PLAYLIST p INNER JOIN TBL_USER u ON u.ID_USER = p.ID_USER " & _
                       "WHERE p.ID_PLAYLIST = @p0", Array(plId))
    If Not rsP.EOF Then
        plFound = True
        plTitle = rsP("TITLE") & ""
        plPhoto = MediaUrl(rsP("PHOTO"), "playlistImages/default.jpg")
        plType = N(rsP("TYPE"))
        plDate = rsP("CREATION_DATE")
        plOwnerId = CLng(rsP("ID_USER"))
        plOwner = rsP("USERNAME") & ""
    End If
    rsP.Close
    Set rsP = Nothing
End If

If plFound Then
    isOwner = (plOwnerId = CurrentUserId())
    canEdit = (isOwner Or IsAdmin())
    PageTitle = plTitle
Else
    PageTitle = "Playlist no encontrada"
End If

' Playlist privada de otro usuario: no visible
If plFound And plType = 1 And Not canEdit Then
    plFound = False
    PageTitle = "Playlist privada"
End If

' --------------------------------------------------------------------------
'  Acciones POST
' --------------------------------------------------------------------------
Dim formErr, formOk
formErr = ""
formOk = ""

If IsPost() And plFound Then
    RequireCsrfToken PostVal("_csrf")

    If Not canEdit Then
        SetError "No tienes permisos sobre esta playlist."
        Go U("Playlist.asp") & "?id=" & plId
    End If

    Select Case action
        Case "remove_song"
            Dim rSong
            rSong = N(PostVal("song_id"))
            If rSong > 0 Then
                DbExec "DELETE FROM TBL_PLAYLIST_SONG WHERE ID_PLAYLIST = @p0 AND ID_SONG = @p1", Array(plId, rSong)
                SetOk "Canción quitada de la playlist."
            End If
            Go U("Playlist.asp") & "?id=" & plId

        Case "add_songs"
            Dim rawIds, arrIds, k, added
            rawIds = Replace(PostVal("song_ids"), " ", "")
            added = 0
            If Len(rawIds) > 0 Then
                arrIds = Split(rawIds, ",")
                For k = 0 To UBound(arrIds)
                    If N(arrIds(k)) > 0 Then
                        DbExec "INSERT INTO TBL_PLAYLIST_SONG (ID_PLAYLIST, ID_SONG) " & _
                               "SELECT @p0, @p1 WHERE NOT EXISTS (SELECT 1 FROM TBL_PLAYLIST_SONG WHERE ID_PLAYLIST = @p0 AND ID_SONG = @p1)", _
                               Array(plId, N(arrIds(k)))
                        added = added + 1
                    End If
                Next
            End If
            If added > 0 Then
                SetOk Plural(added, "canción agregada", "canciones agregadas") & " a la playlist."
            Else
                SetError "No seleccionaste ninguna canción."
            End If
            Go U("Playlist.asp") & "?id=" & plId

        Case "update"
            Dim nTitle, nType, nPhoto, upErr
            nTitle = PostVal("title")
            nType = N(PostVal("type"))
            nPhoto = plPhoto

            If Len(nTitle) = 0 Then
                formErr = "El título de la playlist no puede estar vacío."
            ElseIf Len(nTitle) > 50 Then
                formErr = "El título no puede superar los 50 caracteres."
            Else
                If gMultipart Then
                    Dim savedPath
                    savedPath = SaveUploaded(gUpl, "photo", "playlistImages", "jpg,jpeg,png,gif,webp", MAX_IMAGE_BYTES, upErr)
                    If Len(upErr) > 0 Then
                        formErr = upErr
                    ElseIf Len(savedPath) > 0 Then
                        nPhoto = savedPath
                    End If
                End If

                If Len(formErr) = 0 Then
                    DbExec "UPDATE TBL_PLAYLIST SET TITLE = @p1, TYPE = @p2, PHOTO = @p3 WHERE ID_PLAYLIST = @p0", _
                           Array(plId, nTitle, nType, nPhoto)
                    SetOk "Playlist actualizada correctamente."
                    Go U("Playlist.asp") & "?id=" & plId
                Else
                    action = "edit"
                End If
            End If

        Case "delete"
            DbExec "DELETE FROM TBL_PLAYLIST_SONG WHERE ID_PLAYLIST = @p0", Array(plId)
            DbExec "DELETE FROM TBL_PLAYLIST WHERE ID_PLAYLIST = @p0", Array(plId)
            SetOk "Playlist eliminada."
            Go U("Playlists.asp")
    End Select
End If

If Len(formErr) > 0 Then SetError formErr

ActivePlaylistId = plId
%>
<!--#include file="inc/header.asp"-->

<% If Not plFound Then %>
<div class="empty" style="margin-top:40px">
  <svg class="ico"><use href="#i-list"/></svg>
  <h3><%=H(PageTitle)%></h3>
  <p>La playlist no existe, fue eliminada o es privada.</p>
  <a class="btn btn-ghost" href="<%=U("Playlists.asp")%>">Ir a mis playlists</a>
</div>
<% Else %>

<%
Dim rsCnt, nTracks, nPlays
Set rsCnt = DbSelect("SELECT COUNT(*) AS N, ISNULL(SUM(s.PLAYS),0) AS P FROM TBL_PLAYLIST_SONG ps " & _
                     "INNER JOIN TBL_SONG s ON s.ID_SONG = ps.ID_SONG WHERE ps.ID_PLAYLIST = @p0", Array(plId))
nTracks = N(rsCnt("N"))
nPlays = N(rsCnt("P"))
rsCnt.Close
Set rsCnt = Nothing
%>

<div class="detail-head">
  <img class="detail-art" src="<%=A(plPhoto)%>" alt="<%=A(plTitle)%>">
  <div class="detail-info">
    <div class="detail-kind">Playlist <%=IIfStr(plType = 1, "privada", "pública")%></div>
    <h1><%=H(plTitle)%></h1>
    <div class="detail-meta">
      <strong><%=H(NombreVisible(plOwner))%></strong>
      <span class="dot">·</span><span><%=Plural(nTracks, "canción", "canciones")%></span>
      <span class="dot">·</span><span><%=FechaCorta(plDate)%></span>
      <span class="badge <%=IIfStr(plType = 1, "badge-private", "badge-public")%>">
        <% If plType = 1 Then %><svg class="ico ico-sm"><use href="#i-lock"/></svg> Privada<% Else %><svg class="ico ico-sm"><use href="#i-globe"/></svg> Pública<% End If %>
      </span>
    </div>
  </div>
</div>

<div class="detail-actions">
  <a class="btn btn-primary" href="<%=U("Playlist.asp")%>?id=<%=plId%>&amp;autoplay=1">
    <svg class="ico ico-sm"><use href="#i-play"/></svg> Reproducir
  </a>
  <% If canEdit Then %>
  <a class="btn btn-ghost btn-sm" href="<%=U("Playlist.asp")%>?id=<%=plId%>&amp;action=add">
    <svg class="ico ico-sm"><use href="#i-plus"/></svg> Añadir canciones
  </a>
  <a class="btn btn-ghost btn-sm" href="<%=U("Playlist.asp")%>?id=<%=plId%>&amp;action=edit">
    <svg class="ico ico-sm"><use href="#i-edit"/></svg> Editar
  </a>
  <form method="post" action="<%=U("Playlist.asp")%>" class="inline" style="margin-left:auto"
        data-confirm="¿Eliminar la playlist «<%=A(plTitle)%>»? Esta acción no se puede deshacer.">
    <%=CsrfField()%>
    <input type="hidden" name="action" value="delete">
    <input type="hidden" name="playlist_id" value="<%=plId%>">
    <button class="btn btn-danger btn-sm" type="submit">
      <svg class="ico ico-sm"><use href="#i-trash"/></svg> Eliminar
    </button>
  </form>
  <% End If %>
</div>

<%' ------------------------------------------------------------- Editar %>
<% If action = "edit" And canEdit Then %>
<section class="section">
  <div class="panel">
    <div class="panel-head">
      <div>
        <h2>Editar playlist</h2>
        <p>Cambia el nombre, la visibilidad o la portada.</p>
      </div>
      <a class="btn btn-ghost btn-sm" href="<%=U("Playlist.asp")%>?id=<%=plId%>">Cancelar</a>
    </div>

    <form method="post" action="<%=U("Playlist.asp")%>?id=<%=plId%>" enctype="multipart/form-data">
      <%=CsrfField()%>
      <input type="hidden" name="action" value="update">
      <input type="hidden" name="playlist_id" value="<%=plId%>">

      <div class="form-grid">
        <div class="field">
          <label for="title">Título</label>
          <input class="input" type="text" id="title" name="title" maxlength="50" required value="<%=A(plTitle)%>">
        </div>

        <div class="field">
          <label for="type">Visibilidad</label>
          <select class="select" id="type" name="type">
            <option value="0" <%=IIfStr(plType = 0, "selected", "")%>>Pública — visible para todos</option>
            <option value="1" <%=IIfStr(plType = 1, "selected", "")%>>Privada — solo para mí</option>
          </select>
        </div>

        <div class="field span-2">
          <label for="photo">Portada</label>
          <label class="file-drop" for="photo">
            <svg class="ico"><use href="#i-upload"/></svg>
            <span class="file-name" data-empty="Ningún archivo seleccionado">Ningún archivo seleccionado</span>
            <input type="file" id="photo" name="photo" accept="image/*">
          </label>
          <span class="hint">JPG, PNG, GIF o WEBP · máx. 4 MB. Si no eliges archivo se conserva la actual.</span>
        </div>
      </div>

      <div class="form-actions">
        <button class="btn btn-primary" type="submit">
          <svg class="ico ico-sm"><use href="#i-save"/></svg> Guardar cambios
        </button>
      </div>
    </form>
  </div>
</section>
<% End If %>

<%' --------------------------------------------------------- Añadir canciones %>
<% If action = "add" And canEdit Then %>
<section class="section">
  <div class="panel">
    <div class="panel-head">
      <div>
        <h2>Añadir canciones</h2>
        <p>Selecciona las canciones que quieres agregar a «<%=H(plTitle)%>».</p>
      </div>
      <a class="btn btn-ghost btn-sm" href="<%=U("Playlist.asp")%>?id=<%=plId%>">Cancelar</a>
    </div>

    <%
    Dim rsAvail, availCount
    availCount = 0
    Set rsAvail = DbSelect("SELECT ID_SONG, SONG_NAME FROM TBL_SONG WHERE ID_SONG NOT IN " & _
                           "(SELECT ID_SONG FROM TBL_PLAYLIST_SONG WHERE ID_PLAYLIST = @p0) ORDER BY SONG_NAME", Array(plId))
    If rsAvail.EOF Then
        Response.Write "<div class=""empty""><h3>No hay canciones disponibles</h3><p>Todas las canciones del catálogo ya están en esta playlist.</p></div>"
    Else
        %>
        <form method="post" action="<%=U("Playlist.asp")%>?id=<%=plId%>">
          <%=CsrfField()%>
          <input type="hidden" name="action" value="add_songs">
          <input type="hidden" name="playlist_id" value="<%=plId%>">

          <div class="check-list">
          <%
          Do While Not rsAvail.EOF
              availCount = availCount + 1
              %>
              <label class="check-item">
                <input type="checkbox" name="song_ids" value="<%=rsAvail("ID_SONG")%>">
                <span><%=H(rsAvail("SONG_NAME"))%></span>
              </label>
              <%
              rsAvail.MoveNext
          Loop
          %>
          </div>

          <div class="form-actions">
            <button class="btn btn-primary" type="submit">
              <svg class="ico ico-sm"><use href="#i-plus"/></svg> Agregar seleccionadas
            </button>
          </div>
        </form>
        <%
    End If
    rsAvail.Close
    Set rsAvail = Nothing
    %>
  </div>
</section>
<% End If %>

<%' ------------------------------------------------------------- Canciones %>
<section class="section">
  <%
  Dim rsS, idx
  idx = 0
  Set rsS = DbSelect(SongSql() & "INNER JOIN TBL_PLAYLIST_SONG ps ON ps.ID_SONG = s.ID_SONG " & _
                     "WHERE ps.ID_PLAYLIST = @p0 ORDER BY s.SONG_NAME", Array(plId))
  If rsS.EOF Then
      Response.Write "<div class=""empty""><svg class=""ico""><use href=""#i-music""/></svg>" & _
                     "<h3>Playlist vacía</h3><p>Agrega canciones para empezar a escuchar.</p>"
      If canEdit Then
          Response.Write "<a class=""btn btn-primary"" href=""" & U("Playlist.asp") & "?id=" & plId & "&action=add"">" & _
                         "<svg class=""ico ico-sm""><use href=""#i-plus""/></svg> Añadir canciones</a>"
      End If
      Response.Write "</div>"
  Else
      %>
      <div class="track-head">
        <span style="text-align:right">#</span><span>Título</span><span class="th-album">Álbum</span>
        <span style="text-align:right" class="th-plays">Reproducciones</span><span></span>
      </div>
      <div class="tracklist">
      <%
      Do While Not rsS.EOF
          idx = idx + 1
          Response.Write TrackRow(rsS, idx, True, IIfStr(canEdit, plId, 0))
          rsS.MoveNext
      Loop
      %>
      </div>
      <%
  End If
  rsS.Close
  Set rsS = Nothing
  %>
</section>

<%=QueueScript(doAutoplay)%>
<% End If %>

<!--#include file="inc/footer.asp"-->
