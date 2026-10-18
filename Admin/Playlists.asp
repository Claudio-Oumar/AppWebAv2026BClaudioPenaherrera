<%@ Language="VBScript" CodePage="65001" %>
<!--#include file="../inc/config.asp"-->
<%
RequireAdmin
InitPost

Dim PageTitle, PageId
PageTitle = "Playlists"
PageId = "admin-playlists"

Dim action, editId, errMsg
action = LCase(QS("action"))
If Len(action) = 0 Then action = LCase(PostVal("action"))
editId = N(QS("id"))
If editId = 0 Then editId = N(PostVal("playlist_id"))
errMsg = ""

If IsPost() Then
    RequireCsrfToken PostVal("_csrf")

    Select Case action
        Case "delete"
            DbExec "DELETE FROM TBL_PLAYLIST_SONG WHERE ID_PLAYLIST = @p0", Array(editId)
            DbExec "DELETE FROM TBL_PLAYLIST WHERE ID_PLAYLIST = @p0", Array(editId)
            SetOk "Playlist eliminada."
            Go U("Admin/Playlists.asp")

        Case "create", "update"
            Dim nTitle, nType, nOwner, nPhoto, upErr, savedImg
            nTitle = PostVal("title")
            nType  = N(PostVal("type"))
            nOwner = N(PostVal("id_user"))
            nPhoto = PostVal("current_photo")
            upErr  = ""

            If Len(nTitle) = 0 Then
                errMsg = "El título es obligatorio."
            ElseIf Len(nTitle) > 50 Then
                errMsg = "El título no puede superar los 50 caracteres."
            ElseIf nOwner <= 0 Then
                errMsg = "Selecciona un propietario."
            End If

            If Len(errMsg) = 0 And gMultipart Then
                savedImg = SaveUploaded(gUpl, "photo", "playlistImages", "jpg,jpeg,png,gif,webp", MAX_IMAGE_BYTES, upErr)
                If Len(upErr) > 0 Then
                    errMsg = upErr
                ElseIf Len(savedImg) > 0 Then
                    nPhoto = savedImg
                End If
            End If
            If Len(nPhoto) = 0 Then nPhoto = "~/playlistImages/default.jpg"

            If Len(errMsg) = 0 Then
                If action = "create" Then
                    DbExec "INSERT INTO TBL_PLAYLIST (ID_USER, TITLE, CREATION_DATE, TYPE, PHOTO) VALUES (@p0, @p1, GETDATE(), @p2, @p3)", _
                           Array(nOwner, nTitle, nType, nPhoto)
                    SetOk "Playlist creada."
                Else
                    DbExec "UPDATE TBL_PLAYLIST SET ID_USER = @p1, TITLE = @p2, TYPE = @p3, PHOTO = @p4 WHERE ID_PLAYLIST = @p0", _
                           Array(editId, nOwner, nTitle, nType, nPhoto)
                    SetOk "Playlist actualizada."
                End If
                Go U("Admin/Playlists.asp")
            End If

            If action = "create" Then action = "new" Else action = "edit"
    End Select
End If

If Len(errMsg) > 0 Then SetError errMsg

Dim fTitle, fType, fOwner, fPhoto
fTitle = ""
fType = 0
fOwner = CurrentUserId()
fPhoto = "~/playlistImages/default.jpg"

If (action = "edit") And editId > 0 Then
    Dim rsE
    Set rsE = DbSelect("SELECT ID_USER, TITLE, TYPE, PHOTO FROM TBL_PLAYLIST WHERE ID_PLAYLIST = @p0", Array(editId))
    If Not rsE.EOF Then
        fTitle = rsE("TITLE") & ""
        fType  = N(rsE("TYPE"))
        fOwner = N(rsE("ID_USER"))
        fPhoto = rsE("PHOTO") & ""
    Else
        action = ""
        SetError "La playlist no existe."
    End If
    rsE.Close
    Set rsE = Nothing
End If
If Len(fPhoto) = 0 Then fPhoto = "~/playlistImages/default.jpg"
%>
<!--#include file="../inc/header.asp"-->

<div class="section" style="margin-top:6px">
  <div class="section-head">
    <div>
      <h2>Playlists</h2>
      <p>Todas las playlists del sistema, de cualquier usuario.</p>
    </div>
    <a class="btn btn-primary btn-sm" href="<%=U("Admin/Playlists.asp")%>?action=new">
      <svg class="ico ico-sm"><use href="#i-plus"/></svg> Nueva playlist
    </a>
  </div>
</div>

<div class="stats">
  <div class="stat accent"><span>Playlists</span><strong><%=N(DbScalar("SELECT COUNT(*) FROM TBL_PLAYLIST", Array()))%></strong></div>
  <div class="stat"><span>Públicas</span><strong><%=N(DbScalar("SELECT COUNT(*) FROM TBL_PLAYLIST WHERE TYPE = 0", Array()))%></strong></div>
  <div class="stat"><span>Privadas</span><strong><%=N(DbScalar("SELECT COUNT(*) FROM TBL_PLAYLIST WHERE TYPE = 1", Array()))%></strong></div>
</div>

<% If action = "new" Or action = "edit" Then %>
<section class="section" style="margin-top:0">
  <div class="panel">
    <div class="panel-head">
      <div>
        <h2><%=IIfStr(action = "new", "Nueva playlist", "Editar playlist")%></h2>
        <p>Para gestionar las canciones abre la playlist en la vista de detalle.</p>
      </div>
      <a class="btn btn-ghost btn-sm" href="<%=U("Admin/Playlists.asp")%>">Cancelar</a>
    </div>

    <form method="post" action="<%=U("Admin/Playlists.asp")%>" enctype="multipart/form-data">
      <%=CsrfField()%>
      <input type="hidden" name="action" value="<%=IIfStr(action = "new", "create", "update")%>">
      <input type="hidden" name="playlist_id" value="<%=editId%>">
      <input type="hidden" name="current_photo" value="<%=A(fPhoto)%>">

      <div class="form-grid">
        <div class="field">
          <label for="title">Título</label>
          <input class="input" type="text" id="title" name="title" maxlength="50" required value="<%=A(fTitle)%>">
        </div>

        <div class="field">
          <label for="id_user">Propietario</label>
          <select class="select" id="id_user" name="id_user" required>
            <%
            Dim rsU
            Set rsU = DbSelect("SELECT ID_USER, USERNAME FROM TBL_USER ORDER BY USERNAME", Array())
            Do While Not rsU.EOF
                %>
                <option value="<%=rsU("ID_USER")%>" <%=IIfStr(N(rsU("ID_USER")) = fOwner, "selected", "")%>><%=H(rsU("USERNAME"))%></option>
                <%
                rsU.MoveNext
            Loop
            rsU.Close
            Set rsU = Nothing
            %>
          </select>
        </div>

        <div class="field">
          <label for="type">Visibilidad</label>
          <select class="select" id="type" name="type">
            <option value="0" <%=IIfStr(fType = 0, "selected", "")%>>Pública</option>
            <option value="1" <%=IIfStr(fType = 1, "selected", "")%>>Privada</option>
          </select>
        </div>

        <div class="field">
          <label for="photo">Portada</label>
          <label class="file-drop" for="photo">
            <svg class="ico"><use href="#i-upload"/></svg>
            <span class="file-name" data-empty="Ningún archivo seleccionado">Ningún archivo seleccionado</span>
            <input type="file" id="photo" name="photo" accept="image/*">
          </label>
        </div>
      </div>

      <div class="form-actions">
        <button class="btn btn-primary" type="submit">
          <svg class="ico ico-sm"><use href="#i-save"/></svg> <%=IIfStr(action = "new", "Crear playlist", "Guardar cambios")%>
        </button>
        <% If action = "edit" Then %>
        <a class="btn btn-ghost" href="<%=U("Playlist.asp")%>?id=<%=editId%>">
          <svg class="ico ico-sm"><use href="#i-list"/></svg> Gestionar canciones
        </a>
        <% End If %>
      </div>
    </form>
  </div>
</section>
<% End If %>

<section class="section">
  <div class="table-wrap">
    <table class="data">
      <thead>
        <tr>
          <th>Playlist</th>
          <th>Propietario</th>
          <th>Visibilidad</th>
          <th class="num">Canciones</th>
          <th>Creada</th>
          <th style="text-align:right">Acciones</th>
        </tr>
      </thead>
      <tbody>
        <%
        Dim rsL
        Set rsL = DbSelect("SELECT p.ID_PLAYLIST, p.TITLE, p.TYPE, p.PHOTO, p.CREATION_DATE, u.USERNAME, " & _
            "(SELECT COUNT(*) FROM TBL_PLAYLIST_SONG ps WHERE ps.ID_PLAYLIST = p.ID_PLAYLIST) AS TRACKS " & _
            "FROM TBL_PLAYLIST p INNER JOIN TBL_USER u ON u.ID_USER = p.ID_USER " & _
            "ORDER BY p.CREATION_DATE DESC, p.ID_PLAYLIST DESC", Array())
        Do While Not rsL.EOF
            %>
            <tr>
              <td>
                <div class="cell-main">
                  <img src="<%=A(MediaUrl(rsL("PHOTO"), "playlistImages/default.jpg"))%>" alt="">
                  <div>
                    <strong><%=H(rsL("TITLE"))%></strong>
                    <small>#<%=rsL("ID_PLAYLIST")%></small>
                  </div>
                </div>
              </td>
              <td><%=H(NombreVisible(rsL("USERNAME")))%></td>
              <td>
                <span class="badge <%=IIfStr(N(rsL("TYPE")) = 1, "badge-private", "badge-public")%>">
                  <%=IIfStr(N(rsL("TYPE")) = 1, "Privada", "Pública")%>
                </span>
              </td>
              <td class="num"><%=N(rsL("TRACKS"))%></td>
              <td><%=FechaCorta(rsL("CREATION_DATE"))%></td>
              <td>
                <div class="actions">
                  <a class="t-act" href="<%=U("Playlist.asp")%>?id=<%=rsL("ID_PLAYLIST")%>" title="Ver">
                    <svg class="ico ico-sm"><use href="#i-arrow-right"/></svg>
                  </a>
                  <a class="t-act" href="<%=U("Admin/Playlists.asp")%>?action=edit&amp;id=<%=rsL("ID_PLAYLIST")%>" title="Editar">
                    <svg class="ico ico-sm"><use href="#i-edit"/></svg>
                  </a>
                  <form method="post" action="<%=U("Admin/Playlists.asp")%>" class="inline"
                        data-confirm="¿Eliminar la playlist «<%=A(rsL("TITLE") & "")%>»?">
                    <%=CsrfField()%>
                    <input type="hidden" name="action" value="delete">
                    <input type="hidden" name="playlist_id" value="<%=rsL("ID_PLAYLIST")%>">
                    <button class="t-act danger" type="submit" title="Eliminar">
                      <svg class="ico ico-sm"><use href="#i-trash"/></svg>
                    </button>
                  </form>
                </div>
              </td>
            </tr>
            <%
            rsL.MoveNext
        Loop
        rsL.Close
        Set rsL = Nothing
        %>
      </tbody>
    </table>
  </div>
</section>

<!--#include file="../inc/footer.asp"-->
