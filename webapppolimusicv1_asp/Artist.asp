<%@ Language="VBScript" CodePage="65001" %>
<!--#include file="inc/config.asp"-->
<%
RequireLogin

Dim PageTitle, PageId
PageId = "artist"

Dim artistId, rsAr
artistId = N(QS("id"))

Dim arName, arImg, arFound, arSongs, arPlays
arFound = False
arName = ""
arImg = "ArtistImages/default.jpg"
arSongs = 0
arPlays = 0

If artistId > 0 Then
    Set rsAr = DbSelect("SELECT ID_ARTIST, ARTIST_NAME, ARTIST_LASTNAME, ARTIST_IMAGE FROM TBL_ARTIST WHERE ID_ARTIST = @p0", Array(artistId))
    If Not rsAr.EOF Then
        arFound = True
        arName = Trim(rsAr("ARTIST_NAME") & " " & rsAr("ARTIST_LASTNAME") & "")
        arImg = MediaUrl(rsAr("ARTIST_IMAGE"), "ArtistImages/default.jpg")
    End If
    rsAr.Close
    Set rsAr = Nothing
End If

If arFound Then
    Dim rsSt
    Set rsSt = DbSelect("SELECT COUNT(*) AS N, ISNULL(SUM(s.PLAYS),0) AS P FROM TBL_PLAYER p " & _
                        "INNER JOIN TBL_SONG s ON s.ID_SONG = p.ID_SONG WHERE p.ID_ARTIST = @p0", Array(artistId))
    arSongs = N(rsSt("N"))
    arPlays = N(rsSt("P"))
    rsSt.Close
    Set rsSt = Nothing
    PageTitle = arName
Else
    PageTitle = "Artista no encontrado"
End If

Dim doAutoplay
doAutoplay = (QS("autoplay") = "1")
%>
<!--#include file="inc/header.asp"-->

<% If Not arFound Then %>
<div class="empty" style="margin-top:40px">
  <svg class="ico"><use href="#i-mic"/></svg>
  <h3>Artista no encontrado</h3>
  <p>El artista que buscas no existe o fue eliminado.</p>
  <a class="btn btn-ghost" href="<%=U("Home.asp")%>">Volver al inicio</a>
</div>
<% Else %>

<div class="detail-head">
  <img class="detail-art round" src="<%=A(arImg)%>" alt="<%=A(arName)%>">
  <div class="detail-info">
    <div class="detail-kind">Artista</div>
    <h1><%=H(arName)%></h1>
    <div class="detail-meta">
      <span><%=Plural(arSongs, "canción", "canciones")%></span>
      <span class="dot">·</span><span><%=Plural(arPlays, "reproducción", "reproducciones")%></span>
    </div>
  </div>
</div>

<div class="detail-actions">
  <a class="btn btn-primary" href="<%=U("Artist.asp")%>?id=<%=artistId%>&amp;autoplay=1">
    <svg class="ico ico-sm"><use href="#i-play"/></svg> Reproducir
  </a>
  <% If IsAdmin() Then %>
  <a class="btn btn-ghost btn-sm" href="<%=U("Admin/Artists.asp")%>?action=edit&amp;id=<%=artistId%>">
    <svg class="ico ico-sm"><use href="#i-edit"/></svg> Editar artista
  </a>
  <% End If %>
</div>

<section class="section" style="margin-top:10px">
  <%=SectionHead("Canciones", "", "", "")%>
  <%
  Dim rsS, idx
  idx = 0
  Set rsS = DbSelect(SongSql() & "INNER JOIN TBL_PLAYER pl ON pl.ID_SONG = s.ID_SONG " & _
                     "WHERE pl.ID_ARTIST = @p0 ORDER BY ISNULL(s.PLAYS,0) DESC, s.SONG_NAME", Array(artistId))
  If rsS.EOF Then
      Response.Write "<div class=""empty""><h3>Sin canciones</h3><p>Este artista todavía no tiene canciones asignadas.</p></div>"
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
          Response.Write TrackRow(rsS, idx, True, 0)
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

<%' ------------------------------------------------------------- Álbumes %>
<%
Dim rsAlb, albCount
albCount = 0
Set rsAlb = DbSelect( _
    "SELECT a.ID_ALBUM, a.TITLE_ALBUM, a.RELEASE_YEAR, a.ALBUM_IMAGE_PATH " & _
    "FROM TBL_ALBUM a WHERE a.ID_ALBUM IN (SELECT t.ID_ALBUM FROM TBL_TRACKLIST t " & _
    "INNER JOIN TBL_PLAYER p ON p.ID_SONG = t.ID_SONG WHERE p.ID_ARTIST = @p0) " & _
    "ORDER BY a.RELEASE_YEAR DESC, a.TITLE_ALBUM", Array(artistId))
If Not rsAlb.EOF Then
%>
<section class="section">
  <%=SectionHead("Álbumes con " & arName, "", "", "")%>
  <div class="grid">
    <%
    Do While Not rsAlb.EOF
        albCount = albCount + 1
        Dim aHref
        aHref = U("Album.asp") & "?id=" & rsAlb("ID_ALBUM")
        Response.Write CardItem(aHref, MediaUrl(rsAlb("ALBUM_IMAGE_PATH"), "albumImages/default.png"), _
            rsAlb("TITLE_ALBUM") & "", H(arName) & " · " & H(rsAlb("RELEASE_YEAR") & ""), aHref & "&autoplay=1", False)
        rsAlb.MoveNext
    Loop
    %>
  </div>
</section>
<%
End If
rsAlb.Close
Set rsAlb = Nothing
%>

<%=QueueScript(doAutoplay)%>
<% End If %>

<!--#include file="inc/footer.asp"-->
