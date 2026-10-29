<%@ Language="VBScript" CodePage="65001" %>
<!--#include file="inc/config.asp"-->
<%
RequireLogin

Dim PageTitle, PageId
PageId = "album"

Dim albumId, rsA
albumId = N(QS("id"))

Dim aTitle, aYear, aImg, aFound
Dim tCount, tPlays, aArtist, aArtistId
aFound = False
aTitle = ""
aYear = ""
aImg = "albumImages/default.png"
tCount = 0
tPlays = 0
aArtist = ""
aArtistId = 0

If albumId > 0 Then
    Set rsA = DbSelect("SELECT ID_ALBUM, TITLE_ALBUM, RELEASE_YEAR, ALBUM_IMAGE_PATH FROM TBL_ALBUM WHERE ID_ALBUM = @p0", Array(albumId))
    If Not rsA.EOF Then
        aFound = True
        aTitle = rsA("TITLE_ALBUM") & ""
        aYear = rsA("RELEASE_YEAR") & ""
        aImg = MediaUrl(rsA("ALBUM_IMAGE_PATH"), "albumImages/default.png")
    End If
    rsA.Close
    Set rsA = Nothing
End If

If aFound Then
    Dim rsStat
    Set rsStat = DbSelect("SELECT COUNT(*) AS N, ISNULL(SUM(s.PLAYS),0) AS P FROM TBL_TRACKLIST t " & _
                          "INNER JOIN TBL_SONG s ON s.ID_SONG = t.ID_SONG WHERE t.ID_ALBUM = @p0", Array(albumId))
    tCount = N(rsStat("N"))
    tPlays = N(rsStat("P"))
    rsStat.Close
    Set rsStat = Nothing

    Dim rsArt
    Set rsArt = DbSelect("SELECT TOP 1 ar.ID_ARTIST, ar.ARTIST_NAME, ar.ARTIST_LASTNAME FROM TBL_TRACKLIST t " & _
                         "INNER JOIN TBL_PLAYER p ON p.ID_SONG = t.ID_SONG " & _
                         "INNER JOIN TBL_ARTIST ar ON ar.ID_ARTIST = p.ID_ARTIST " & _
                         "WHERE t.ID_ALBUM = @p0", Array(albumId))
    If Not rsArt.EOF Then
        aArtistId = CLng(rsArt("ID_ARTIST"))
        aArtist = Trim(rsArt("ARTIST_NAME") & " " & rsArt("ARTIST_LASTNAME") & "")
    End If
    rsArt.Close
    Set rsArt = Nothing

    PageTitle = aTitle
Else
    PageTitle = "Álbum no encontrado"
End If

Dim doAutoplay
doAutoplay = (QS("autoplay") = "1")
%>
<!--#include file="inc/header.asp"-->

<% If Not aFound Then %>
<div class="empty" style="margin-top:40px">
  <svg class="ico"><use href="#i-disc"/></svg>
  <h3>Álbum no encontrado</h3>
  <p>El álbum que buscas no existe o fue eliminado.</p>
  <a class="btn btn-ghost" href="<%=U("Home.asp")%>">Volver al inicio</a>
</div>
<% Else %>

<div class="detail-head">
  <img class="detail-art" src="<%=A(aImg)%>" alt="<%=A(aTitle)%>">
  <div class="detail-info">
    <div class="detail-kind">Álbum</div>
    <h1><%=H(aTitle)%></h1>
    <div class="detail-meta">
      <% If aArtistId > 0 Then %>
        <strong><a href="<%=U("Artist.asp")%>?id=<%=aArtistId%>" style="color:var(--txt)"><%=H(aArtist)%></a></strong>
      <% End If %>
      <% If Len(aYear) > 0 And aYear <> "0" Then %><span class="dot">·</span><span><%=H(aYear)%></span><% End If %>
      <span class="dot">·</span><span><%=Plural(tCount, "canción", "canciones")%></span>
      <span class="dot">·</span><span><%=Plural(tPlays, "reproducción", "reproducciones")%></span>
    </div>
  </div>
</div>

<div class="detail-actions">
  <a class="btn btn-primary" href="<%=U("Album.asp")%>?id=<%=albumId%>&amp;autoplay=1">
    <svg class="ico ico-sm"><use href="#i-play"/></svg> Reproducir
  </a>
  <% If IsAdmin() Then %>
  <a class="btn btn-ghost btn-sm" href="<%=U("Admin/Albums.asp")%>?action=edit&amp;id=<%=albumId%>">
    <svg class="ico ico-sm"><use href="#i-edit"/></svg> Editar álbum
  </a>
  <% End If %>
</div>

<section class="section" style="margin-top:10px">
  <%
  Dim rsS, idx
  idx = 0
  Set rsS = DbSelect(SongSql() & "INNER JOIN TBL_TRACKLIST tl ON tl.ID_SONG = s.ID_SONG " & _
                     "WHERE tl.ID_ALBUM = @p0 ORDER BY s.SONG_NAME", Array(albumId))
  If rsS.EOF Then
      Response.Write "<div class=""empty""><h3>Álbum sin canciones</h3><p>Este álbum todavía no tiene pistas asignadas.</p></div>"
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
          Response.Write TrackRow(rsS, idx, False, 0)
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
