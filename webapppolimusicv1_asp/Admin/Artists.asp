<%@ Language="VBScript" CodePage="65001" %>
<!--#include file="../inc/config.asp"-->
<%
RequireAdmin
InitPost

Dim PageTitle, PageId
PageTitle = "Artistas"
PageId = "admin-artists"

Dim action, editId, errMsg
action = LCase(QS("action"))
If Len(action) = 0 Then action = LCase(PostVal("action"))
editId = N(QS("id"))
If editId = 0 Then editId = N(PostVal("artist_id"))
errMsg = ""

If IsPost() Then
    RequireCsrfToken PostVal("_csrf")

    Select Case action
        Case "delete"
            DbExec "DELETE FROM TBL_PLAYER WHERE ID_ARTIST = @p0", Array(editId)
            DbExec "DELETE FROM TBL_ARTIST WHERE ID_ARTIST = @p0", Array(editId)
            SetOk "Artista eliminado."
            Go U("Admin/Artists.asp")

        Case "create", "update"
            Dim nName, nLast, nImg, upErr, savedImg
            nName = PostVal("artist_name")
            nLast = PostVal("artist_lastname")
            nImg  = PostVal("current_image")
            upErr = ""

            If Len(nName) = 0 Then
                errMsg = "El nombre del artista es obligatorio."
            ElseIf Len(nName) > 100 Then
                errMsg = "El nombre no puede superar los 100 caracteres."
            End If

            If Len(errMsg) = 0 And gMultipart Then
                savedImg = SaveUploaded(gUpl, "image", "ArtistImages", "jpg,jpeg,png,gif,webp", MAX_IMAGE_BYTES, upErr)
                If Len(upErr) > 0 Then
                    errMsg = upErr
                ElseIf Len(savedImg) > 0 Then
                    nImg = savedImg
                End If
            End If
            If Len(nImg) = 0 Then nImg = "~/ArtistImages/default.jpg"

            If Len(errMsg) = 0 Then
                If action = "create" Then
                    DbExec "INSERT INTO TBL_ARTIST (ARTIST_NAME, ARTIST_LASTNAME, ARTIST_IMAGE) VALUES (@p0, @p1, @p2)", _
                           Array(nName, IIfStr(Len(nLast) > 0, nLast, Null), nImg)
                    SetOk "Artista «" & nName & "» creado."
                Else
                    DbExec "UPDATE TBL_ARTIST SET ARTIST_NAME = @p1, ARTIST_LASTNAME = @p2, ARTIST_IMAGE = @p3 WHERE ID_ARTIST = @p0", _
                           Array(editId, nName, IIfStr(Len(nLast) > 0, nLast, Null), nImg)
                    SetOk "Artista actualizado."
                End If
                Go U("Admin/Artists.asp")
            End If

            If action = "create" Then action = "new" Else action = "edit"
    End Select
End If

If Len(errMsg) > 0 Then SetError errMsg

Dim fName, fLast, fImg, fFound
fName = ""
fLast = ""
fImg = "~/ArtistImages/default.jpg"
fFound = True

If (action = "edit") And editId > 0 Then
    Dim rsE
    Set rsE = DbSelect("SELECT ARTIST_NAME, ARTIST_LASTNAME, ARTIST_IMAGE FROM TBL_ARTIST WHERE ID_ARTIST = @p0", Array(editId))
    If Not rsE.EOF Then
        fName = rsE("ARTIST_NAME") & ""
        fLast = rsE("ARTIST_LASTNAME") & ""
        fImg  = rsE("ARTIST_IMAGE") & ""
    Else
        fFound = False
        action = ""
        SetError "El artista no existe."
    End If
    rsE.Close
    Set rsE = Nothing
End If
If Len(fImg) = 0 Then fImg = "~/ArtistImages/default.jpg"
%>
<!--#include file="../inc/header.asp"-->

<div class="section" style="margin-top:6px">
  <div class="section-head">
    <div>
      <h2>Artistas</h2>
      <p>Gestiona las voces del catálogo.</p>
    </div>
    <a class="btn btn-primary btn-sm" href="<%=U("Admin/Artists.asp")%>?action=new">
      <svg class="ico ico-sm"><use href="#i-plus"/></svg> Nuevo artista
    </a>
  </div>
</div>

<div class="stats">
  <div class="stat accent"><span>Artistas</span><strong><%=N(DbScalar("SELECT COUNT(*) FROM TBL_ARTIST", Array()))%></strong></div>
  <div class="stat"><span>Con canciones</span><strong><%=N(DbScalar("SELECT COUNT(DISTINCT ID_ARTIST) FROM TBL_PLAYER", Array()))%></strong></div>
</div>

<% If action = "new" Or action = "edit" Then %>
<section class="section" style="margin-top:0">
  <div class="panel">
    <div class="panel-head">
      <div>
        <h2><%=IIfStr(action = "new", "Nuevo artista", "Editar artista")%></h2>
        <p>Completa los datos y sube una fotografía.</p>
      </div>
      <a class="btn btn-ghost btn-sm" href="<%=U("Admin/Artists.asp")%>">Cancelar</a>
    </div>

    <form method="post" action="<%=U("Admin/Artists.asp")%>" enctype="multipart/form-data">
      <%=CsrfField()%>
      <input type="hidden" name="action" value="<%=IIfStr(action = "new", "create", "update")%>">
      <input type="hidden" name="artist_id" value="<%=editId%>">
      <input type="hidden" name="current_image" value="<%=A(fImg)%>">

      <div class="form-grid">
        <div class="field">
          <label for="artist_name">Nombre</label>
          <input class="input" type="text" id="artist_name" name="artist_name" maxlength="100" required value="<%=A(fName)%>">
        </div>

        <div class="field">
          <label for="artist_lastname">Apellido</label>
          <input class="input" type="text" id="artist_lastname" name="artist_lastname" maxlength="100" value="<%=A(fLast)%>">
        </div>

        <div class="field span-2">
          <label for="image">Fotografía</label>
          <label class="file-drop" for="image">
            <svg class="ico"><use href="#i-upload"/></svg>
            <span class="file-name" data-empty="Ningún archivo seleccionado">Ningún archivo seleccionado</span>
            <input type="file" id="image" name="image" accept="image/*">
          </label>
          <span class="hint">JPG, PNG, GIF o WEBP · máx. 4 MB.</span>
        </div>
      </div>

      <div class="form-actions">
        <button class="btn btn-primary" type="submit">
          <svg class="ico ico-sm"><use href="#i-save"/></svg> <%=IIfStr(action = "new", "Crear artista", "Guardar cambios")%>
        </button>
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
          <th>Artista</th>
          <th class="num">Canciones</th>
          <th class="num">Álbumes</th>
          <th style="text-align:right">Acciones</th>
        </tr>
      </thead>
      <tbody>
        <%
        Dim rsL
        Set rsL = DbSelect("SELECT ar.ID_ARTIST, ar.ARTIST_NAME, ar.ARTIST_LASTNAME, ar.ARTIST_IMAGE, " & _
            "(SELECT COUNT(*) FROM TBL_PLAYER p WHERE p.ID_ARTIST = ar.ID_ARTIST) AS SONGS, " & _
            "(SELECT COUNT(DISTINCT t.ID_ALBUM) FROM TBL_PLAYER p INNER JOIN TBL_TRACKLIST t ON t.ID_SONG = p.ID_SONG WHERE p.ID_ARTIST = ar.ID_ARTIST) AS ALBUMS " & _
            "FROM TBL_ARTIST ar ORDER BY ar.ARTIST_NAME", Array())
        Do While Not rsL.EOF
            %>
            <tr>
              <td>
                <div class="cell-main">
                  <img src="<%=A(MediaUrl(rsL("ARTIST_IMAGE"), "ArtistImages/default.jpg"))%>" alt="" style="border-radius:50%">
                  <div>
                    <strong><%=H(Trim(rsL("ARTIST_NAME") & " " & rsL("ARTIST_LASTNAME") & ""))%></strong>
                    <small>#<%=rsL("ID_ARTIST")%></small>
                  </div>
                </div>
              </td>
              <td class="num"><%=N(rsL("SONGS"))%></td>
              <td class="num"><%=N(rsL("ALBUMS"))%></td>
              <td>
                <div class="actions">
                  <a class="t-act" href="<%=U("Artist.asp")%>?id=<%=rsL("ID_ARTIST")%>" title="Ver">
                    <svg class="ico ico-sm"><use href="#i-arrow-right"/></svg>
                  </a>
                  <a class="t-act" href="<%=U("Admin/Artists.asp")%>?action=edit&amp;id=<%=rsL("ID_ARTIST")%>" title="Editar">
                    <svg class="ico ico-sm"><use href="#i-edit"/></svg>
                  </a>
                  <form method="post" action="<%=U("Admin/Artists.asp")%>" class="inline"
                        data-confirm="¿Eliminar al artista «<%=A(Trim(rsL("ARTIST_NAME") & " " & rsL("ARTIST_LASTNAME") & ""))%>»? Se quitará de todas sus canciones.">
                    <%=CsrfField()%>
                    <input type="hidden" name="action" value="delete">
                    <input type="hidden" name="artist_id" value="<%=rsL("ID_ARTIST")%>">
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
