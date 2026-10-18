<%@ Language="VBScript" CodePage="65001" %>
<!--#include file="inc/config.asp"-->
<%
RequireLogin
InitPost

Dim PageTitle, PageId
PageTitle = "Tu biblioteca"
PageId = "playlists"

Dim action, errMsg
action = LCase(QS("action"))
errMsg = ""

' --------------------------------------------------------------------------
'  Crear playlist
' --------------------------------------------------------------------------
If IsPost() Then
    RequireCsrfToken PostVal("_csrf")
    If LCase(PostVal("action")) = "create" Then
        Dim nTitle, nType, nPhoto, upErr, newPl
        nTitle = PostVal("title")
        nType = N(PostVal("type"))
        nPhoto = "~/playlistImages/default.jpg"
        upErr = ""

        If Len(nTitle) = 0 Then
            errMsg = "El título de la playlist no puede estar vacío."
        ElseIf Len(nTitle) > 50 Then
            errMsg = "El título no puede superar los 50 caracteres."
        Else
            If gMultipart Then
                Dim sp
                sp = SaveUploaded(gUpl, "photo", "playlistImages", "jpg,jpeg,png,gif,webp", MAX_IMAGE_BYTES, upErr)
                If Len(upErr) > 0 Then
                    errMsg = upErr
                ElseIf Len(sp) > 0 Then
                    nPhoto = sp
                End If
            End If

            If Len(errMsg) = 0 Then
                newPl = DbInsert("INSERT INTO TBL_PLAYLIST (ID_USER, TITLE, CREATION_DATE, TYPE, PHOTO) " & _
                                 "VALUES (@p0, @p1, GETDATE(), @p2, @p3)", _
                                 Array(CurrentUserId(), nTitle, nType, nPhoto))
                If newPl > 0 Then
                    SetOk "Playlist «" & nTitle & "» creada. Ahora agrega tus canciones."
                    Go U("Playlist.asp") & "?id=" & newPl & "&action=add"
                Else
                    errMsg = "No se pudo crear la playlist."
                End If
            End If
        End If

        action = "new"
    End If
End If

If Len(errMsg) > 0 Then SetError errMsg
%>
<!--#include file="inc/header.asp"-->

<div class="section" style="margin-top:6px">
  <div class="section-head">
    <div>
      <h2>Tu biblioteca</h2>
      <p><%=Plural(N(DbScalar("SELECT COUNT(*) FROM TBL_PLAYLIST WHERE ID_USER = @p0", Array(CurrentUserId()))), "playlist propia", "playlists propias")%></p>
    </div>
    <a class="btn btn-primary btn-sm" href="<%=U("Playlists.asp")%>?action=new">
      <svg class="ico ico-sm"><use href="#i-plus"/></svg> Nueva playlist
    </a>
  </div>
</div>

<% If action = "new" Then %>
<section class="section" style="margin-top:0">
  <div class="panel">
    <div class="panel-head">
      <div>
        <h2>Nueva playlist</h2>
        <p>Dale un nombre y elige quién puede verla.</p>
      </div>
      <a class="btn btn-ghost btn-sm" href="<%=U("Playlists.asp")%>">Cancelar</a>
    </div>

    <form method="post" action="<%=U("Playlists.asp")%>" enctype="multipart/form-data">
      <%=CsrfField()%>
      <input type="hidden" name="action" value="create">

      <div class="form-grid">
        <div class="field">
          <label for="title">Título</label>
          <input class="input" type="text" id="title" name="title" maxlength="50" required
                 placeholder="Ej. Noche de estudio" autofocus>
        </div>

        <div class="field">
          <label for="type">Visibilidad</label>
          <select class="select" id="type" name="type">
            <option value="0">Pública — visible para todos</option>
            <option value="1">Privada — solo para mí</option>
          </select>
        </div>

        <div class="field span-2">
          <label for="photo">Portada <span class="hint">(opcional)</span></label>
          <label class="file-drop" for="photo">
            <svg class="ico"><use href="#i-upload"/></svg>
            <span class="file-name" data-empty="Ningún archivo seleccionado">Ningún archivo seleccionado</span>
            <input type="file" id="photo" name="photo" accept="image/*">
          </label>
        </div>
      </div>

      <div class="form-actions">
        <button class="btn btn-primary" type="submit">
          <svg class="ico ico-sm"><use href="#i-plus"/></svg> Crear playlist
        </button>
      </div>
    </form>
  </div>
</section>
<% End If %>

<%' ------------------------------------------------------- Mis playlists %>
<section class="section">
  <%=SectionHead("Mis playlists", "", "", "")%>
  <div class="grid">
    <%
    Dim rsM, mCount, mHref, mTracks
    mCount = 0
    Set rsM = DbSelect("SELECT ID_PLAYLIST, TITLE, PHOTO, TYPE, CREATION_DATE FROM TBL_PLAYLIST " & _
                       "WHERE ID_USER = @p0 ORDER BY CREATION_DATE DESC, ID_PLAYLIST DESC", Array(CurrentUserId()))
    Do While Not rsM.EOF
        mCount = mCount + 1
        mHref = U("Playlist.asp") & "?id=" & rsM("ID_PLAYLIST")
        mTracks = N(DbScalar("SELECT COUNT(*) FROM TBL_PLAYLIST_SONG WHERE ID_PLAYLIST = @p0", Array(CLng(rsM("ID_PLAYLIST")))))
        %>
        <div class="card">
          <div class="card-art">
            <a href="<%=mHref%>">
              <img src="<%=A(MediaUrl(rsM("PHOTO"), "playlistImages/default.jpg"))%>" alt="" loading="lazy">
            </a>
            <a class="card-play" href="<%=mHref%>&amp;autoplay=1" title="Reproducir">
              <svg class="ico"><use href="#i-play"/></svg>
            </a>
          </div>
          <a class="card-title" href="<%=mHref%>"><%=H(rsM("TITLE"))%></a>
          <p class="card-sub">
            <svg class="ico ico-sm" style="display:inline;vertical-align:-3px">
              <use href="#i-<%=IIfStr(N(rsM("TYPE")) = 1, "lock", "globe")%>"/>
            </svg>
            <%=Plural(mTracks, "canción", "canciones")%> · <%=IIfStr(N(rsM("TYPE")) = 1, "Privada", "Pública")%>
          </p>
        </div>
        <%
        rsM.MoveNext
    Loop
    rsM.Close
    Set rsM = Nothing

    If mCount = 0 Then
        Response.Write "<div class=""empty"" style=""grid-column:1/-1""><svg class=""ico""><use href=""#i-list""/></svg>" & _
                       "<h3>Aún no tienes playlists</h3><p>Crea tu primera playlist y empieza a coleccionar música.</p>" & _
                       "<a class=""btn btn-primary"" href=""" & U("Playlists.asp") & "?action=new"">Crear playlist</a></div>"
    End If
    %>
  </div>
</section>

<%' --------------------------------------------------- Playlists públicas %>
<section class="section">
  <%=SectionHead("Playlists de la comunidad", "Playlists públicas creadas por otros usuarios", "", "")%>
  <div class="grid">
    <%
    Dim rsC, cCount, cHref
    cCount = 0
    Set rsC = DbSelect("SELECT TOP 12 p.ID_PLAYLIST, p.TITLE, p.PHOTO, u.USERNAME, " & _
                       "(SELECT COUNT(*) FROM TBL_PLAYLIST_SONG ps WHERE ps.ID_PLAYLIST = p.ID_PLAYLIST) AS TRACKS " & _
                       "FROM TBL_PLAYLIST p INNER JOIN TBL_USER u ON u.ID_USER = p.ID_USER " & _
                       "WHERE p.TYPE = 0 AND p.ID_USER <> @p0 ORDER BY p.CREATION_DATE DESC", Array(CurrentUserId()))
    Do While Not rsC.EOF
        cCount = cCount + 1
        cHref = U("Playlist.asp") & "?id=" & rsC("ID_PLAYLIST")
        Response.Write CardItem(cHref, MediaUrl(rsC("PHOTO"), "playlistImages/default.jpg"), _
            rsC("TITLE") & "", H(NombreVisible(rsC("USERNAME"))) & " · " & Plural(N(rsC("TRACKS")), "canción", "canciones"), _
            cHref & "&autoplay=1", False)
        rsC.MoveNext
    Loop
    rsC.Close
    Set rsC = Nothing
    If cCount = 0 Then Response.Write "<div class=""empty"" style=""grid-column:1/-1""><h3>Sin playlists públicas</h3><p>Cuando otros usuarios compartan sus playlists aparecerán aquí.</p></div>"
    %>
  </div>
</section>

<!--#include file="inc/footer.asp"-->
