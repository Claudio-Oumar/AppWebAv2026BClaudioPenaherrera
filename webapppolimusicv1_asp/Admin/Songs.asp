<%@ Language="VBScript" CodePage="65001" %>
<!--#include file="../inc/config.asp"-->
<%
RequireAdmin
InitPost

Dim PageTitle, PageId
PageTitle = "Canciones"
PageId = "admin-songs"

Dim action, editId, errMsg
action = LCase(QS("action"))
If Len(action) = 0 Then action = LCase(PostVal("action"))
editId = N(QS("id"))
If editId = 0 Then editId = N(PostVal("song_id"))
errMsg = ""

' --------------------------------------------------------------------------
'  Acciones
' --------------------------------------------------------------------------
If IsPost() Then
    RequireCsrfToken PostVal("_csrf")

    Select Case action
        Case "delete"
            DbExec "DELETE FROM TBL_PLAYLIST_SONG WHERE ID_SONG = @p0", Array(editId)
            DbExec "DELETE FROM TBL_TRACKLIST WHERE ID_SONG = @p0", Array(editId)
            DbExec "DELETE FROM TBL_PLAYER WHERE ID_SONG = @p0", Array(editId)
            DbExec "DELETE FROM TBL_SONG WHERE ID_SONG = @p0", Array(editId)
            SetOk "Canción eliminada."
            Go U("Admin/Songs.asp")

        Case "create", "update"
            Dim nName, nPath, nPlays, upErr, savedPath, artCsv, albCsv, k, arr
            nName  = PostVal("song_name")
            nPath  = PostVal("song_path")
            nPlays = N(PostVal("plays"))
            upErr  = ""
            artCsv = Replace(PostVal("artist_ids"), " ", "")
            albCsv = Replace(PostVal("album_ids"), " ", "")

            If Len(nName) = 0 Then
                errMsg = "El nombre de la canción es obligatorio."
            ElseIf Len(nName) > 50 Then
                errMsg = "El nombre no puede superar los 50 caracteres."
            End If

            If Len(errMsg) = 0 And gMultipart Then
                savedPath = SaveUploaded(gUpl, "audio", "songFiles", "mp3,wav,ogg,m4a", MAX_AUDIO_BYTES, upErr)
                If Len(upErr) > 0 Then
                    errMsg = upErr
                ElseIf Len(savedPath) > 0 Then
                    nPath = savedPath
                End If
            End If

            If Len(errMsg) = 0 Then
                If Len(nPath) = 0 Then
                    errMsg = "Debes subir un archivo de audio o indicar una ruta."
                End If
            End If

            If Len(errMsg) = 0 Then
                Dim songId
                songId = editId

                If action = "create" Then
                    songId = DbInsert("INSERT INTO TBL_SONG (SONG_NAME, SONG_PATH, PLAYS) VALUES (@p0, @p1, @p2)", _
                                      Array(nName, nPath, nPlays))
                Else
                    DbExec "UPDATE TBL_SONG SET SONG_NAME = @p1, SONG_PATH = @p2, PLAYS = @p3 WHERE ID_SONG = @p0", _
                           Array(songId, nName, nPath, nPlays)
                End If

                If songId > 0 Then
                    ' Reasigna artistas
                    DbExec "DELETE FROM TBL_PLAYER WHERE ID_SONG = @p0", Array(songId)
                    If Len(artCsv) > 0 Then
                        arr = Split(artCsv, ",")
                        For k = 0 To UBound(arr)
                            If N(arr(k)) > 0 Then
                                DbExec "INSERT INTO TBL_PLAYER (ID_SONG, ID_ARTIST) VALUES (@p0, @p1)", Array(songId, N(arr(k)))
                            End If
                        Next
                    End If

                    ' Reasigna álbumes
                    DbExec "DELETE FROM TBL_TRACKLIST WHERE ID_SONG = @p0", Array(songId)
                    If Len(albCsv) > 0 Then
                        arr = Split(albCsv, ",")
                        For k = 0 To UBound(arr)
                            If N(arr(k)) > 0 Then
                                DbExec "INSERT INTO TBL_TRACKLIST (ID_ALBUM, ID_SONG) VALUES (@p0, @p1)", Array(N(arr(k)), songId)
                            End If
                        Next
                    End If

                    SetOk IIfStr(action = "create", "Canción creada.", "Canción actualizada.")
                    Go U("Admin/Songs.asp")
                Else
                    errMsg = "No se pudo guardar la canción."
                End If
            End If

            If action = "create" Then action = "new" Else action = "edit"
    End Select
End If

If Len(errMsg) > 0 Then SetError errMsg

' --------------------------------------------------------------------------
'  Datos del formulario
' --------------------------------------------------------------------------
Dim fName, fPath, fPlays, fArtCsv, fAlbCsv, fFound
fName = ""
fPath = ""
fPlays = 0
fArtCsv = ""
fAlbCsv = ""
fFound = True

If (action = "edit") And editId > 0 Then
    Dim rsE
    Set rsE = DbSelect("SELECT SONG_NAME, SONG_PATH, ISNULL(PLAYS,0) AS PLAYS FROM TBL_SONG WHERE ID_SONG = @p0", Array(editId))
    If Not rsE.EOF Then
        fName  = rsE("SONG_NAME") & ""
        fPath  = rsE("SONG_PATH") & ""
        fPlays = N(rsE("PLAYS"))
    Else
        fFound = False
        action = ""
        SetError "La canción no existe."
    End If
    rsE.Close
    Set rsE = Nothing

    If fFound Then
        Dim rsRel
        Set rsRel = DbSelect("SELECT ID_ARTIST FROM TBL_PLAYER WHERE ID_SONG = @p0", Array(editId))
        Do While Not rsRel.EOF
            fArtCsv = fArtCsv & IIfStr(Len(fArtCsv) > 0, ",", "") & rsRel("ID_ARTIST")
            rsRel.MoveNext
        Loop
        rsRel.Close
        Set rsRel = Nothing

        Set rsRel = DbSelect("SELECT ID_ALBUM FROM TBL_TRACKLIST WHERE ID_SONG = @p0", Array(editId))
        Do While Not rsRel.EOF
            fAlbCsv = fAlbCsv & IIfStr(Len(fAlbCsv) > 0, ",", "") & rsRel("ID_ALBUM")
            rsRel.MoveNext
        Loop
        rsRel.Close
        Set rsRel = Nothing
    End If
End If
%>
<!--#include file="../inc/header.asp"-->

<div class="section" style="margin-top:6px">
  <div class="section-head">
    <div>
      <h2>Canciones</h2>
      <p>Sube audio y asigna artistas y álbumes al catálogo.</p>
    </div>
    <a class="btn btn-primary btn-sm" href="<%=U("Admin/Songs.asp")%>?action=new">
      <svg class="ico ico-sm"><use href="#i-plus"/></svg> Nueva canción
    </a>
  </div>
</div>

<div class="stats">
  <div class="stat accent"><span>Canciones</span><strong><%=N(DbScalar("SELECT COUNT(*) FROM TBL_SONG", Array()))%></strong></div>
  <div class="stat"><span>Reproducciones</span><strong><%=N(DbScalar("SELECT ISNULL(SUM(PLAYS),0) FROM TBL_SONG", Array()))%></strong></div>
  <div class="stat"><span>Sin artista</span><strong><%=N(DbScalar("SELECT COUNT(*) FROM TBL_SONG s WHERE NOT EXISTS (SELECT 1 FROM TBL_PLAYER p WHERE p.ID_SONG = s.ID_SONG)", Array()))%></strong></div>
</div>

<% If action = "new" Or action = "edit" Then %>
<section class="section" style="margin-top:0">
  <div class="panel">
    <div class="panel-head">
      <div>
        <h2><%=IIfStr(action = "new", "Nueva canción", "Editar canción")%></h2>
        <p><%=IIfStr(action = "new", "Sube el archivo MP3 y completa los datos.", "Modifica los datos, el audio o las relaciones.")%></p>
      </div>
      <a class="btn btn-ghost btn-sm" href="<%=U("Admin/Songs.asp")%>">Cancelar</a>
    </div>

    <form method="post" action="<%=U("Admin/Songs.asp")%>" enctype="multipart/form-data">
      <%=CsrfField()%>
      <input type="hidden" name="action" value="<%=IIfStr(action = "new", "create", "update")%>">
      <input type="hidden" name="song_id" value="<%=editId%>">

      <div class="form-grid">
        <div class="field">
          <label for="song_name">Nombre</label>
          <input class="input" type="text" id="song_name" name="song_name" maxlength="50" required value="<%=A(fName)%>">
        </div>

        <div class="field">
          <label for="plays">Reproducciones</label>
          <input class="input" type="number" id="plays" name="plays" min="0" value="<%=fPlays%>">
        </div>

        <div class="field span-2">
          <label for="audio">Archivo de audio <%=IIfStr(action = "edit", "· opcional", "")%></label>
          <label class="file-drop" for="audio">
            <svg class="ico"><use href="#i-upload"/></svg>
            <span class="file-name" data-empty="Ningún archivo seleccionado">Ningún archivo seleccionado</span>
            <input type="file" id="audio" name="audio" accept="audio/*">
          </label>
          <span class="hint">MP3, WAV, OGG o M4A · máx. 20 MB.</span>
        </div>

        <div class="field span-2">
          <label for="song_path">Ruta del archivo</label>
          <input class="input" type="text" id="song_path" name="song_path" maxlength="255" value="<%=A(fPath)%>"
                 placeholder="~/songFiles/mi-cancion.mp3">
          <span class="hint">Se completa automáticamente al subir un archivo. También puedes escribir una ruta existente.</span>
        </div>

        <div class="field span-2">
          <label>Artistas</label>
          <div class="check-list">
            <%
            Dim rsArt
            Set rsArt = DbSelect("SELECT ID_ARTIST, ARTIST_NAME, ARTIST_LASTNAME FROM TBL_ARTIST ORDER BY ARTIST_NAME", Array())
            If rsArt.EOF Then Response.Write "<span class=""muted"">No hay artistas registrados.</span>"
            Do While Not rsArt.EOF
                %>
                <label class="check-item">
                  <input type="checkbox" name="artist_ids" value="<%=rsArt("ID_ARTIST")%>"
                         <%=IIfStr(InCsv(fArtCsv, rsArt("ID_ARTIST")), "checked", "")%>>
                  <span><%=H(Trim(rsArt("ARTIST_NAME") & " " & rsArt("ARTIST_LASTNAME") & ""))%></span>
                </label>
                <%
                rsArt.MoveNext
            Loop
            rsArt.Close
            Set rsArt = Nothing
            %>
          </div>
        </div>

        <div class="field span-2">
          <label>Álbumes</label>
          <div class="check-list">
            <%
            Dim rsAlb
            Set rsAlb = DbSelect("SELECT ID_ALBUM, TITLE_ALBUM FROM TBL_ALBUM ORDER BY TITLE_ALBUM", Array())
            If rsAlb.EOF Then Response.Write "<span class=""muted"">No hay álbumes registrados.</span>"
            Do While Not rsAlb.EOF
                %>
                <label class="check-item">
                  <input type="checkbox" name="album_ids" value="<%=rsAlb("ID_ALBUM")%>"
                         <%=IIfStr(InCsv(fAlbCsv, rsAlb("ID_ALBUM")), "checked", "")%>>
                  <span><%=H(rsAlb("TITLE_ALBUM"))%></span>
                </label>
                <%
                rsAlb.MoveNext
            Loop
            rsAlb.Close
            Set rsAlb = Nothing
            %>
          </div>
        </div>
      </div>

      <div class="form-actions">
        <button class="btn btn-primary" type="submit">
          <svg class="ico ico-sm"><use href="#i-save"/></svg> <%=IIfStr(action = "new", "Crear canción", "Guardar cambios")%>
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
          <th>Canción</th>
          <th>Artistas</th>
          <th>Álbumes</th>
          <th class="num">Reproducciones</th>
          <th style="text-align:right">Acciones</th>
        </tr>
      </thead>
      <tbody>
        <%
        Dim rsL
        Set rsL = DbSelect( _
            "SELECT s.ID_SONG, s.SONG_NAME, s.SONG_PATH, ISNULL(s.PLAYS,0) AS PLAYS, " & _
            "(SELECT TOP 1 a.ALBUM_IMAGE_PATH FROM TBL_TRACKLIST t INNER JOIN TBL_ALBUM a ON a.ID_ALBUM = t.ID_ALBUM WHERE t.ID_SONG = s.ID_SONG) AS COVER, " & _
            "STUFF((SELECT ', ' + ar.ARTIST_NAME + ISNULL(' ' + ar.ARTIST_LASTNAME,'') FROM TBL_PLAYER p INNER JOIN TBL_ARTIST ar ON ar.ID_ARTIST = p.ID_ARTIST WHERE p.ID_SONG = s.ID_SONG FOR XML PATH('')), 1, 2, '') AS ARTISTS, " & _
            "STUFF((SELECT ', ' + a.TITLE_ALBUM FROM TBL_TRACKLIST t INNER JOIN TBL_ALBUM a ON a.ID_ALBUM = t.ID_ALBUM WHERE t.ID_SONG = s.ID_SONG FOR XML PATH('')), 1, 2, '') AS ALBUMS " & _
            "FROM TBL_SONG s ORDER BY s.SONG_NAME", Array())
        Do While Not rsL.EOF
            %>
            <tr>
              <td>
                <div class="cell-main">
                  <img src="<%=A(MediaUrl(rsL("COVER"), "albumImages/default.png"))%>" alt="">
                  <div>
                    <strong><%=H(rsL("SONG_NAME"))%></strong>
                    <small>#<%=rsL("ID_SONG")%></small>
                  </div>
                </div>
              </td>
              <td><%=H(rsL("ARTISTS") & "")%></td>
              <td><%=H(rsL("ALBUMS") & "")%></td>
              <td class="num"><%=N(rsL("PLAYS"))%></td>
              <td>
                <div class="actions">
                  <a class="t-act" href="<%=U("Admin/Songs.asp")%>?action=edit&amp;id=<%=rsL("ID_SONG")%>" title="Editar">
                    <svg class="ico ico-sm"><use href="#i-edit"/></svg>
                  </a>
                  <form method="post" action="<%=U("Admin/Songs.asp")%>" class="inline"
                        data-confirm="¿Eliminar la canción «<%=A(rsL("SONG_NAME") & "")%>»? También se quitará de álbumes y playlists.">
                    <%=CsrfField()%>
                    <input type="hidden" name="action" value="delete">
                    <input type="hidden" name="song_id" value="<%=rsL("ID_SONG")%>">
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
