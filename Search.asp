<%@ Language="VBScript" CodePage="65001" %>
<!--#include file="inc/config.asp"-->
<%
RequireLogin

Dim PageTitle, PageId
PageTitle = "Buscar"
PageId = "search"

Dim q, tipo, patron
q = QS("q")
tipo = LCase(QS("tipo"))
If Len(tipo) = 0 Then tipo = "todo"
patron = "%" & q & "%"
%>
<!--#include file="inc/header.asp"-->

<div class="section" style="margin-top:6px">
  <div class="section-head">
    <div>
      <h2><% If Len(q) > 0 Then %>Resultados para «<%=H(q)%>»<% Else %>Explorar catálogo<% End If %></h2>
      <p><% If Len(q) > 0 Then %>Encuentra canciones, álbumes, artistas y playlists<% Else %>Todo lo que hay en PoliMusic, en un solo lugar<% End If %></p>
    </div>
  </div>
</div>

<% If Len(q) > 0 Then %>
<div class="chips">
  <a class="chip <%=IIfStr(tipo = "todo", "is-active", "")%>" href="<%=U("Search.asp")%>?q=<%=Server.URLEncode(q)%>&amp;tipo=todo">Todo</a>
  <a class="chip <%=IIfStr(tipo = "canciones", "is-active", "")%>" href="<%=U("Search.asp")%>?q=<%=Server.URLEncode(q)%>&amp;tipo=canciones">Canciones</a>
  <a class="chip <%=IIfStr(tipo = "albumes", "is-active", "")%>" href="<%=U("Search.asp")%>?q=<%=Server.URLEncode(q)%>&amp;tipo=albumes">Álbumes</a>
  <a class="chip <%=IIfStr(tipo = "artistas", "is-active", "")%>" href="<%=U("Search.asp")%>?q=<%=Server.URLEncode(q)%>&amp;tipo=artistas">Artistas</a>
  <a class="chip <%=IIfStr(tipo = "playlists", "is-active", "")%>" href="<%=U("Search.asp")%>?q=<%=Server.URLEncode(q)%>&amp;tipo=playlists">Playlists</a>
</div>
<% End If %>

<%
Dim showSongs, showAlbums, showArtists, showPlaylists
showSongs     = (tipo = "todo" Or tipo = "canciones")
showAlbums    = (tipo = "todo" Or tipo = "albumes")
showArtists   = (tipo = "todo" Or tipo = "artistas")
showPlaylists = (tipo = "todo" Or tipo = "playlists")

Dim totalHits
totalHits = 0
%>

<%' ------------------------------------------------------------- Canciones %>
<% If showSongs Then %>
<section class="section">
  <%=SectionHead("Canciones", "", "", "")%>
  <%
  Dim rsS, sIdx
  sIdx = 0
  If Len(q) > 0 Then
      Set rsS = DbSelect(SongSql() & "WHERE s.SONG_NAME LIKE @p0 ORDER BY s.SONG_NAME", Array(patron))
  Else
      Set rsS = DbSelect(SongSql() & "ORDER BY ISNULL(s.PLAYS,0) DESC, s.SONG_NAME", Array())
  End If
  Do While Not rsS.EOF
      sIdx = sIdx + 1
      rsS.MoveNext
  Loop
  totalHits = totalHits + sIdx
  If sIdx > 0 Then
      rsS.MoveFirst
      %>
      <div class="track-head">
        <span style="text-align:right">#</span><span>Título</span><span class="th-album">Álbum</span>
        <span style="text-align:right" class="th-plays">Reproducciones</span><span></span>
      </div>
      <div class="tracklist">
      <%
      Dim i
      i = 0
      Do While Not rsS.EOF
          i = i + 1
          Response.Write TrackRow(rsS, i, True, 0)
          rsS.MoveNext
      Loop
      %>
      </div>
      <%
  Else
      Response.Write "<div class=""empty""><svg class=""ico""><use href=""#i-music""/></svg><h3>Sin canciones</h3><p>No encontramos canciones que coincidan.</p></div>"
  End If
  rsS.Close
  Set rsS = Nothing
  %>
</section>
<% End If %>

<%' --------------------------------------------------------------- Álbumes %>
<% If showAlbums Then %>
<section class="section">
  <%=SectionHead("Álbumes", "", "", "")%>
  <div class="grid">
    <%
    Dim rsA, aCount, aHref
    aCount = 0
    If Len(q) > 0 Then
        Set rsA = DbSelect( _
            "SELECT a.ID_ALBUM, a.TITLE_ALBUM, a.RELEASE_YEAR, a.ALBUM_IMAGE_PATH, " & _
            "(SELECT TOP 1 LTRIM(RTRIM(ar.ARTIST_NAME + ISNULL(' ' + ar.ARTIST_LASTNAME,''))) " & _
            " FROM TBL_TRACKLIST t INNER JOIN TBL_PLAYER p ON p.ID_SONG = t.ID_SONG " & _
            " INNER JOIN TBL_ARTIST ar ON ar.ID_ARTIST = p.ID_ARTIST WHERE t.ID_ALBUM = a.ID_ALBUM) AS ARTIST " & _
            "FROM TBL_ALBUM a WHERE a.TITLE_ALBUM LIKE @p0 ORDER BY a.TITLE_ALBUM", Array(patron))
    Else
        Set rsA = DbSelect( _
            "SELECT a.ID_ALBUM, a.TITLE_ALBUM, a.RELEASE_YEAR, a.ALBUM_IMAGE_PATH, " & _
            "(SELECT TOP 1 LTRIM(RTRIM(ar.ARTIST_NAME + ISNULL(' ' + ar.ARTIST_LASTNAME,''))) " & _
            " FROM TBL_TRACKLIST t INNER JOIN TBL_PLAYER p ON p.ID_SONG = t.ID_SONG " & _
            " INNER JOIN TBL_ARTIST ar ON ar.ID_ARTIST = p.ID_ARTIST WHERE t.ID_ALBUM = a.ID_ALBUM) AS ARTIST " & _
            "FROM TBL_ALBUM a ORDER BY a.TITLE_ALBUM", Array())
    End If
    Do While Not rsA.EOF
        aCount = aCount + 1
        aHref = U("Album.asp") & "?id=" & rsA("ID_ALBUM")
        Response.Write CardItem(aHref, MediaUrl(rsA("ALBUM_IMAGE_PATH"), "albumImages/default.png"), _
            rsA("TITLE_ALBUM") & "", H(rsA("ARTIST") & "") & " · " & H(rsA("RELEASE_YEAR") & ""), aHref & "&autoplay=1", False)
        rsA.MoveNext
    Loop
    rsA.Close
    Set rsA = Nothing
    totalHits = totalHits + aCount
    If aCount = 0 Then Response.Write "<div class=""empty""><h3>Sin álbumes</h3><p>No encontramos álbumes que coincidan.</p></div>"
    %>
  </div>
</section>
<% End If %>

<%' -------------------------------------------------------------- Artistas %>
<% If showArtists Then %>
<section class="section">
  <%=SectionHead("Artistas", "", "", "")%>
  <div class="grid grid-tight">
    <%
    Dim rsAr, arCount, arHref, arName
    arCount = 0
    If Len(q) > 0 Then
        Set rsAr = DbSelect("SELECT ID_ARTIST, ARTIST_NAME, ARTIST_LASTNAME, ARTIST_IMAGE, " & _
            "(SELECT COUNT(*) FROM TBL_PLAYER p WHERE p.ID_ARTIST = TBL_ARTIST.ID_ARTIST) AS SONGS " & _
            "FROM TBL_ARTIST WHERE (ARTIST_NAME + ' ' + ISNULL(ARTIST_LASTNAME,'')) LIKE @p0 ORDER BY ARTIST_NAME", Array(patron))
    Else
        Set rsAr = DbSelect("SELECT ID_ARTIST, ARTIST_NAME, ARTIST_LASTNAME, ARTIST_IMAGE, " & _
            "(SELECT COUNT(*) FROM TBL_PLAYER p WHERE p.ID_ARTIST = TBL_ARTIST.ID_ARTIST) AS SONGS " & _
            "FROM TBL_ARTIST ORDER BY ARTIST_NAME", Array())
    End If
    Do While Not rsAr.EOF
        arCount = arCount + 1
        arHref = U("Artist.asp") & "?id=" & rsAr("ID_ARTIST")
        arName = Trim(rsAr("ARTIST_NAME") & " " & rsAr("ARTIST_LASTNAME") & "")
        Response.Write CardItem(arHref, MediaUrl(rsAr("ARTIST_IMAGE"), "ArtistImages/default.jpg"), _
            arName, IIfStr(N(rsAr("SONGS")) > 0, Plural(N(rsAr("SONGS")), "canción", "canciones"), "Artista"), _
            arHref & "&autoplay=1", True)
        rsAr.MoveNext
    Loop
    rsAr.Close
    Set rsAr = Nothing
    totalHits = totalHits + arCount
    If arCount = 0 Then Response.Write "<div class=""empty""><h3>Sin artistas</h3><p>No encontramos artistas que coincidan.</p></div>"
    %>
  </div>
</section>
<% End If %>

<%' -------------------------------------------------------------- Playlists %>
<% If showPlaylists Then %>
<section class="section">
  <%=SectionHead("Playlists", "", "", "")%>
  <div class="grid">
    <%
    Dim rsP, pCount, pHref
    pCount = 0
    Set rsP = DbSelect( _
        "SELECT p.ID_PLAYLIST, p.TITLE, p.PHOTO, p.TYPE, u.USERNAME, " & _
        "(SELECT COUNT(*) FROM TBL_PLAYLIST_SONG ps WHERE ps.ID_PLAYLIST = p.ID_PLAYLIST) AS TRACKS " & _
        "FROM TBL_PLAYLIST p INNER JOIN TBL_USER u ON u.ID_USER = p.ID_USER " & _
        "WHERE (p.TYPE = 0 OR p.ID_USER = @p1) AND p.TITLE LIKE @p0 " & _
        "ORDER BY p.CREATION_DATE DESC", Array(patron, CurrentUserId()))
    Do While Not rsP.EOF
        pCount = pCount + 1
        pHref = U("Playlist.asp") & "?id=" & rsP("ID_PLAYLIST")
        Response.Write CardItem(pHref, MediaUrl(rsP("PHOTO"), "playlistImages/default.jpg"), _
            rsP("TITLE") & "", H(NombreVisible(rsP("USERNAME"))) & " · " & Plural(N(rsP("TRACKS")), "canción", "canciones"), _
            pHref & "&autoplay=1", False)
        rsP.MoveNext
    Loop
    rsP.Close
    Set rsP = Nothing
    totalHits = totalHits + pCount
    If pCount = 0 Then Response.Write "<div class=""empty""><h3>Sin playlists</h3><p>No encontramos playlists que coincidan.</p></div>"
    %>
  </div>
</section>
<% End If %>

<% If Len(q) > 0 And totalHits = 0 Then %>
<div class="empty" style="margin-top:24px">
  <svg class="ico"><use href="#i-search"/></svg>
  <h3>Nada por aquí</h3>
  <p>Prueba con otro término: «<%=H(q)%>» no tiene coincidencias.</p>
</div>
<% End If %>

<%=QueueScript(False)%>

<!--#include file="inc/footer.asp"-->
