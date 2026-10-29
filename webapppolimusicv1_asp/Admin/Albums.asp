<%@ Language="VBScript" CodePage="65001" %>
<!--#include file="../inc/config.asp"-->
<%
RequireAdmin
InitPost

Dim PageTitle, PageId
PageTitle = "Álbumes"
PageId = "admin-albums"

Dim action, editId, errMsg
action = LCase(QS("action"))
If Len(action) = 0 Then action = LCase(PostVal("action"))
editId = N(QS("id"))
If editId = 0 Then editId = N(PostVal("album_id"))
errMsg = ""

If IsPost() Then
    RequireCsrfToken PostVal("_csrf")

    Select Case action
        Case "delete"
            DbExec "DELETE FROM TBL_TRACKLIST WHERE ID_ALBUM = @p0", Array(editId)
            DbExec "DELETE FROM TBL_ALBUM WHERE ID_ALBUM = @p0", Array(editId)
            SetOk "Álbum eliminado."
            Go U("Admin/Albums.asp")

        Case "create", "update"
            Dim nTitle, nYear, nImg, upErr, savedImg, songCsv, k, arr, albId
            nTitle = PostVal("title_album")
            nYear  = N(PostVal("release_year"))
            nImg   = PostVal("current_image")
            upErr  = ""
            songCsv = Replace(PostVal("song_ids"), " ", "")

            If Len(nTitle) = 0 Then
                errMsg = "El título del álbum es obligatorio."
            ElseIf Len(nTitle) > 50 Then
                errMsg = "El título no puede superar los 50 caracteres."
            ElseIf Len(PostVal("release_year")) > 0 And (nYear < 1900 Or nYear > 2100) Then
                errMsg = "El año de lanzamiento debe estar entre 1900 y 2100."
            End If

            If Len(errMsg) = 0 And gMultipart Then
                savedImg = SaveUploaded(gUpl, "image", "albumImages", "jpg,jpeg,png,gif,webp", MAX_IMAGE_BYTES, upErr)
                If Len(upErr) > 0 Then
                    errMsg = upErr
                ElseIf Len(savedImg) > 0 Then
                    nImg = savedImg
                End If
            End If
            If Len(nImg) = 0 Then nImg = "~/albumImages/default.png"

            If Len(errMsg) = 0 Then
                Dim yearVal
                If Len(PostVal("release_year")) = 0 Then
                    yearVal = Null
                Else
                    yearVal = nYear
                End If

                If action = "create" Then
                    albId = DbInsert("INSERT INTO TBL_ALBUM (TITLE_ALBUM, RELEASE_YEAR, ALBUM_IMAGE_PATH) VALUES (@p0, @p1, @p2)", _
                                     Array(nTitle, yearVal, nImg))
                Else
                    albId = editId
                    DbExec "UPDATE TBL_ALBUM SET TITLE_ALBUM = @p1, RELEASE_YEAR = @p2, ALBUM_IMAGE_PATH = @p3 WHERE ID_ALBUM = @p0", _
                           Array(albId, nTitle, yearVal, nImg)
                End If

                If albId > 0 Then
                    DbExec "DELETE FROM TBL_TRACKLIST WHERE ID_ALBUM = @p0", Array(albId)
                    If Len(songCsv) > 0 Then
                        arr = Split(songCsv, ",")
                        For k = 0 To UBound(arr)
                            If N(arr(k)) > 0 Then
                                DbExec "INSERT INTO TBL_TRACKLIST (ID_ALBUM, ID_SONG) VALUES (@p0, @p1)", Array(albId, N(arr(k)))
                            End If
                        Next
                    End If
                    SetOk IIfStr(action = "create", "Álbum creado.", "Álbum actualizado.")
                    Go U("Admin/Albums.asp")
                Else
                    errMsg = "No se pudo guardar el álbum."
                End If
            End If

            If action = "create" Then action = "new" Else action = "edit"
    End Select
End If

If Len(errMsg) > 0 Then SetError errMsg

Dim fTitle, fYear, fImg, fSongCsv, fFound
fTitle = ""
fYear = ""
fImg = "~/albumImages/default.png"
fSongCsv = ""
fFound = True

If (action = "edit") And editId > 0 Then
    Dim rsE
    Set rsE = DbSelect("SELECT TITLE_ALBUM, RELEASE_YEAR, ALBUM_IMAGE_PATH FROM TBL_ALBUM WHERE ID_ALBUM = @p0", Array(editId))
    If Not rsE.EOF Then
        fTitle = rsE("TITLE_ALBUM") & ""
        fYear  = rsE("RELEASE_YEAR") & ""
        fImg   = rsE("ALBUM_IMAGE_PATH") & ""
    Else
        fFound = False
        action = ""
        SetError "El álbum no existe."
    End If
    rsE.Close
    Set rsE = Nothing

    If fFound Then
        Dim rsT
        Set rsT = DbSelect("SELECT ID_SONG FROM TBL_TRACKLIST WHERE ID_ALBUM = @p0", Array(editId))
        Do While Not rsT.EOF
            fSongCsv = fSongCsv & IIfStr(Len(fSongCsv) > 0, ",", "") & rsT("ID_SONG")
            rsT.MoveNext
        Loop
        rsT.Close
        Set rsT = Nothing
    End If
End If
If Len(fImg) = 0 Then fImg = "~/albumImages/default.png"
%>
<!--#include file="../inc/header.asp"-->

<div class="section" style="margin-top:6px">
  <div class="section-head">
    <div>
      <h2>Álbumes</h2>
      <p>Crea colecciones y arma su lista de canciones.</p>
    </div>
    <a class="btn btn-primary btn-sm" href="<%=U("Admin/Albums.asp")%>?action=new">
      <svg class="ico ico-sm"><use href="#i-plus"/></svg> Nuevo álbum
    </a>
  </div>
</div>

<div class="stats">
  <div class="stat accent"><span>Álbumes</span><strong><%=N(DbScalar("SELECT COUNT(*) FROM TBL_ALBUM", Array()))%></strong></div>
  <div class="stat"><span>Pistas asignadas</span><strong><%=N(DbScalar("SELECT COUNT(*) FROM TBL_TRACKLIST", Array()))%></strong></div>
</div>

<% If action = "new" Or action = "edit" Then %>
<section class="section" style="margin-top:0">
  <div class="panel">
    <div class="panel-head">
      <div>
        <h2><%=IIfStr(action = "new", "Nuevo álbum", "Editar álbum")%></h2>
        <p>Define portada, año y las canciones que lo componen.</p>
      </div>
      <a class="btn btn-ghost btn-sm" href="<%=U("Admin/Albums.asp")%>">Cancelar</a>
    </div>

    <form method="post" action="<%=U("Admin/Albums.asp")%>" enctype="multipart/form-data">
      <%=CsrfField()%>
      <input type="hidden" name="action" value="<%=IIfStr(action = "new", "create", "update")%>">
      <input type="hidden" name="album_id" value="<%=editId%>">
      <input type="hidden" name="current_image" value="<%=A(fImg)%>">

      <div class="form-grid">
        <div class="field">
          <label for="title_album">Título</label>
          <input class="input" type="text" id="title_album" name="title_album" maxlength="50" required value="<%=A(fTitle)%>">
        </div>

        <div class="field">
          <label for="release_year">Año de lanzamiento</label>
          <input class="input" type="number" id="release_year" name="release_year" min="1900" max="2100" value="<%=A(fYear)%>">
        </div>

        <div class="field span-2">
          <label for="image">Portada</label>
          <label class="file-drop" for="image">
            <svg class="ico"><use href="#i-upload"/></svg>
            <span class="file-name" data-empty="Ningún archivo seleccionado">Ningún archivo seleccionado</span>
            <input type="file" id="image" name="image" accept="image/*">
          </label>
          <span class="hint">JPG, PNG, GIF o WEBP · máx. 4 MB.</span>
        </div>

        <div class="field span-2">
          <label>Canciones del álbum</label>
          <div class="check-list">
            <%
            Dim rsS
            Set rsS = DbSelect("SELECT ID_SONG, SONG_NAME FROM TBL_SONG ORDER BY SONG_NAME", Array())
            If rsS.EOF Then Response.Write "<span class=""muted"">No hay canciones registradas.</span>"
            Do While Not rsS.EOF
                %>
                <label class="check-item">
                  <input type="checkbox" name="song_ids" value="<%=rsS("ID_SONG")%>"
                         <%=IIfStr(InCsv(fSongCsv, rsS("ID_SONG")), "checked", "")%>>
                  <span><%=H(rsS("SONG_NAME"))%></span>
                </label>
                <%
                rsS.MoveNext
            Loop
            rsS.Close
            Set rsS = Nothing
            %>
          </div>
        </div>
      </div>

      <div class="form-actions">
        <button class="btn btn-primary" type="submit">
          <svg class="ico ico-sm"><use href="#i-save"/></svg> <%=IIfStr(action = "new", "Crear álbum", "Guardar cambios")%>
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
          <th>Álbum</th>
          <th>Año</th>
          <th class="num">Canciones</th>
          <th class="num">Reproducciones</th>
          <th style="text-align:right">Acciones</th>
        </tr>
      </thead>
      <tbody>
        <%
        Dim rsL
        Set rsL = DbSelect("SELECT a.ID_ALBUM, a.TITLE_ALBUM, a.RELEASE_YEAR, a.ALBUM_IMAGE_PATH, " & _
            "(SELECT COUNT(*) FROM TBL_TRACKLIST t WHERE t.ID_ALBUM = a.ID_ALBUM) AS TRACKS, " & _
            "(SELECT ISNULL(SUM(s.PLAYS),0) FROM TBL_TRACKLIST t INNER JOIN TBL_SONG s ON s.ID_SONG = t.ID_SONG WHERE t.ID_ALBUM = a.ID_ALBUM) AS PLAYS " & _
            "FROM TBL_ALBUM a ORDER BY a.TITLE_ALBUM", Array())
        Do While Not rsL.EOF
            %>
            <tr>
              <td>
                <div class="cell-main">
                  <img src="<%=A(MediaUrl(rsL("ALBUM_IMAGE_PATH"), "albumImages/default.png"))%>" alt="">
                  <div>
                    <strong><%=H(rsL("TITLE_ALBUM"))%></strong>
                    <small>#<%=rsL("ID_ALBUM")%></small>
                  </div>
                </div>
              </td>
              <td><%=H(rsL("RELEASE_YEAR") & "")%></td>
              <td class="num"><%=N(rsL("TRACKS"))%></td>
              <td class="num"><%=N(rsL("PLAYS"))%></td>
              <td>
                <div class="actions">
                  <a class="t-act" href="<%=U("Album.asp")%>?id=<%=rsL("ID_ALBUM")%>" title="Ver">
                    <svg class="ico ico-sm"><use href="#i-arrow-right"/></svg>
                  </a>
                  <a class="t-act" href="<%=U("Admin/Albums.asp")%>?action=edit&amp;id=<%=rsL("ID_ALBUM")%>" title="Editar">
                    <svg class="ico ico-sm"><use href="#i-edit"/></svg>
                  </a>
                  <form method="post" action="<%=U("Admin/Albums.asp")%>" class="inline"
                        data-confirm="¿Eliminar el álbum «<%=A(rsL("TITLE_ALBUM") & "")%>»? Las canciones no se eliminan, solo la relación.">
                    <%=CsrfField()%>
                    <input type="hidden" name="action" value="delete">
                    <input type="hidden" name="album_id" value="<%=rsL("ID_ALBUM")%>">
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
