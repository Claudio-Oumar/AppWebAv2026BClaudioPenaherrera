<%@ Language="VBScript" CodePage="65001" %>
<!--#include file="inc/config.asp"-->
<%
RequireLogin

Dim PageTitle, PageId
PageTitle = "Inicio"
PageId = "home"

' --- Album destacado -------------------------------------------------------
Dim rsFeat, featId, featTitle, featYear, featImg, featTracks
Set rsFeat = DbSelect( _
    "SELECT TOP 1 a.ID_ALBUM, a.TITLE_ALBUM, a.RELEASE_YEAR, a.ALBUM_IMAGE_PATH, " & _
    "(SELECT COUNT(*) FROM TBL_TRACKLIST t WHERE t.ID_ALBUM = a.ID_ALBUM) AS TRACKS, " & _
    "(SELECT TOP 1 LTRIM(RTRIM(ar.ARTIST_NAME + ISNULL(' ' + ar.ARTIST_LASTNAME,''))) " & _
    " FROM TBL_TRACKLIST t INNER JOIN TBL_PLAYER p ON p.ID_SONG = t.ID_SONG " & _
    " INNER JOIN TBL_ARTIST ar ON ar.ID_ARTIST = p.ID_ARTIST WHERE t.ID_ALBUM = a.ID_ALBUM) AS ARTIST " & _
    "FROM TBL_ALBUM a " & _
    "ORDER BY (SELECT COUNT(*) FROM TBL_TRACKLIST t WHERE t.ID_ALBUM = a.ID_ALBUM) DESC, a.RELEASE_YEAR DESC", Array())

featId = 0
If Not rsFeat.EOF Then
    featId    = CLng(rsFeat("ID_ALBUM"))
    featTitle = rsFeat("TITLE_ALBUM") & ""
    featYear  = rsFeat("RELEASE_YEAR")
    featImg   = MediaUrl(rsFeat("ALBUM_IMAGE_PATH"), "albumImages/default.png")
    featTracks = N(rsFeat("TRACKS"))
End If
rsFeat.Close
Set rsFeat = Nothing
%>
<!--#include file="inc/header.asp"-->

<p class="hero-kicker" style="margin:0 0 10px 6px">Bienvenido, <%=H(NombreVisible(CurrentUserName()))%></p>

<% If featId > 0 Then %>
<section class="hero">
  <div class="hero-txt">
    <div class="hero-kicker">Álbum destacado</div>
    <h1><%=H(featTitle)%></h1>
    <p><%=H(featTitle)%> · <%=H(featYear & "")%> · <%=Plural(featTracks, "canción", "canciones")%>. Dale play y deja que el morado suene.</p>
    <div class="hero-actions">
      <a class="btn btn-primary" href="<%=U("Album.asp")%>?id=<%=featId%>&amp;autoplay=1">
        <svg class="ico ico-sm"><use href="#i-play"/></svg> Reproducir
      </a>
      <a class="btn btn-ghost" href="<%=U("Album.asp")%>?id=<%=featId%>">Ver álbum</a>
    </div>
  </div>
  <img class="hero-art" src="<%=A(featImg)%>" alt="<%=A(featTitle)%>">
</section>
<% End If %>

<%' ------------------------------------------------------- Tus playlists %>
<section class="section">
  <%=SectionHead("Tus playlists", "Crea, edita y organiza tu música", U("Playlists.asp"), "Ver todas")%>
  <div class="grid">
    <a class="card" href="<%=U("Playlists.asp")%>?action=new" style="justify-content:center;align-items:center;text-align:center;min-height:150px;border-style:dashed">
      <span style="width:46px;height:46px;border-radius:50%;display:grid;place-items:center;background:var(--accent-soft);color:var(--accent-3);margin-bottom:10px">
        <svg class="ico"><use href="#i-plus"/></svg>
      </span>
      <span class="card-title" style="margin:0">Nueva playlist</span>
      <span class="card-sub">Empieza desde cero</span>
    </a>
    <%
    Dim rsPl, plCount
    plCount = 0
    Set rsPl = DbSelect("SELECT TOP 5 ID_PLAYLIST, TITLE, PHOTO, TYPE, CREATION_DATE FROM TBL_PLAYLIST WHERE ID_USER = @p0 ORDER BY CREATION_DATE DESC, ID_PLAYLIST DESC", Array(CurrentUserId()))
    Do While Not rsPl.EOF
        plCount = plCount + 1
        Dim plTracks
        plTracks = N(DbScalar("SELECT COUNT(*) FROM TBL_PLAYLIST_SONG WHERE ID_PLAYLIST = @p0", Array(CLng(rsPl("ID_PLAYLIST")))))
        %>
        <div class="card">
          <div class="card-art">
            <a href="<%=U("Playlist.asp")%>?id=<%=rsPl("ID_PLAYLIST")%>">
              <img src="<%=A(MediaUrl(rsPl("PHOTO"), "playlistImages/default.jpg"))%>" alt="" loading="lazy">
            </a>
            <a class="card-play" href="<%=U("Playlist.asp")%>?id=<%=rsPl("ID_PLAYLIST")%>&amp;autoplay=1" title="Reproducir">
              <svg class="ico"><use href="#i-play"/></svg>
            </a>
          </div>
          <a class="card-title" href="<%=U("Playlist.asp")%>?id=<%=rsPl("ID_PLAYLIST")%>"><%=H(rsPl("TITLE"))%></a>
          <p class="card-sub">
            <%=Plural(plTracks, "canción", "canciones")%> ·
            <%=IIfStr(CLng(rsPl("TYPE")) = 1, "Privada", "Pública")%>
          </p>
        </div>
        <%
        rsPl.MoveNext
    Loop
    rsPl.Close
    Set rsPl = Nothing
    %>
  </div>
</section>

<%' --------------------------------------------------- Lo más escuchado %>
<section class="section">
  <%=SectionHead("Lo más escuchado", "Las canciones con más reproducciones del catálogo", U("Search.asp"), "Explorar")%>
  <div class="grid grid-tight">
    <%
    Dim rsS, sIdx
    sIdx = 0
    Set rsS = DbSelect(SongSql() & "ORDER BY ISNULL(s.PLAYS,0) DESC, s.SONG_NAME", Array())
    Do While Not rsS.EOF
        sIdx = sIdx + 1
        Response.Write SongCard(rsS, sIdx)
        rsS.MoveNext
    Loop
    rsS.Close
    Set rsS = Nothing
    If sIdx = 0 Then Response.Write "<div class=""empty""><h3>Sin canciones</h3><p>El catálogo está vacío.</p></div>"
    %>
  </div>
</section>

<%' ------------------------------------------------------- Álbumes %>
<section class="section">
  <%=SectionHead("Álbumes", "Colecciones completas para escuchar de principio a fin", "", "")%>
  <div class="grid">
    <%
    Dim rsA, aCount
    aCount = 0
    Set rsA = DbSelect( _
        "SELECT a.ID_ALBUM, a.TITLE_ALBUM, a.RELEASE_YEAR, a.ALBUM_IMAGE_PATH, " & _
        "(SELECT COUNT(*) FROM TBL_TRACKLIST t WHERE t.ID_ALBUM = a.ID_ALBUM) AS TRACKS, " & _
        "(SELECT TOP 1 LTRIM(RTRIM(ar.ARTIST_NAME + ISNULL(' ' + ar.ARTIST_LASTNAME,''))) " & _
        " FROM TBL_TRACKLIST t INNER JOIN TBL_PLAYER p ON p.ID_SONG = t.ID_SONG " & _
        " INNER JOIN TBL_ARTIST ar ON ar.ID_ARTIST = p.ID_ARTIST WHERE t.ID_ALBUM = a.ID_ALBUM) AS ARTIST " & _
        "FROM TBL_ALBUM a ORDER BY a.TITLE_ALBUM", Array())
    Do While Not rsA.EOF
        aCount = aCount + 1
        Dim aHref, aPlay, aSub
        aHref = U("Album.asp") & "?id=" & rsA("ID_ALBUM")
        aPlay = aHref & "&autoplay=1"
        aSub = H(rsA("ARTIST") & "") & " · " & H(rsA("RELEASE_YEAR") & "")
        Response.Write CardItem(aHref, MediaUrl(rsA("ALBUM_IMAGE_PATH"), "albumImages/default.png"), _
                                rsA("TITLE_ALBUM") & "", aSub, aPlay, False)
        rsA.MoveNext
    Loop
    rsA.Close
    Set rsA = Nothing
    If aCount = 0 Then Response.Write "<div class=""empty""><h3>Sin álbumes</h3><p>Aún no hay álbumes registrados.</p></div>"
    %>
  </div>
</section>

<%' ------------------------------------------------------- Artistas %>
<section class="section">
  <%=SectionHead("Artistas populares", "Las voces detrás de las canciones", "", "")%>
  <div class="grid grid-tight">
    <%
    Dim rsAr, arCount
    arCount = 0
    Set rsAr = DbSelect( _
        "SELECT TOP 8 ar.ID_ARTIST, ar.ARTIST_NAME, ar.ARTIST_LASTNAME, ar.ARTIST_IMAGE, " & _
        "(SELECT COUNT(*) FROM TBL_PLAYER p WHERE p.ID_ARTIST = ar.ID_ARTIST) AS SONGS " & _
        "FROM TBL_ARTIST ar " & _
        "ORDER BY (SELECT COUNT(*) FROM TBL_PLAYER p WHERE p.ID_ARTIST = ar.ID_ARTIST) DESC, ar.ARTIST_NAME", Array())
    Do While Not rsAr.EOF
        arCount = arCount + 1
        Dim arHref, arName, arSub
        arHref = U("Artist.asp") & "?id=" & rsAr("ID_ARTIST")
        arName = Trim(rsAr("ARTIST_NAME") & " " & rsAr("ARTIST_LASTNAME") & "")
        arSub = IIfStr(N(rsAr("SONGS")) > 0, Plural(N(rsAr("SONGS")), "canción", "canciones"), "Artista")
        Response.Write CardItem(arHref, MediaUrl(rsAr("ARTIST_IMAGE"), "ArtistImages/default.jpg"), _
                                arName, arSub, arHref & "&autoplay=1", True)
        rsAr.MoveNext
    Loop
    rsAr.Close
    Set rsAr = Nothing
    If arCount = 0 Then Response.Write "<div class=""empty""><h3>Sin artistas</h3><p>Aún no hay artistas registrados.</p></div>"
    %>
  </div>
</section>

<%' ------------------------------------------------------- Playlists públicas %>
<section class="section">
  <%=SectionHead("Playlists públicas", "Lo que escucha la comunidad PoliMusic", "", "")%>
  <div class="grid">
    <%
    Dim rsPub, pubCount
    pubCount = 0
    Set rsPub = DbSelect( _
        "SELECT TOP 8 p.ID_PLAYLIST, p.TITLE, p.PHOTO, u.USERNAME, " & _
        "(SELECT COUNT(*) FROM TBL_PLAYLIST_SONG ps WHERE ps.ID_PLAYLIST = p.ID_PLAYLIST) AS TRACKS " & _
        "FROM TBL_PLAYLIST p INNER JOIN TBL_USER u ON u.ID_USER = p.ID_USER " & _
        "WHERE p.TYPE = 0 ORDER BY p.CREATION_DATE DESC", Array())
    Do While Not rsPub.EOF
        pubCount = pubCount + 1
        Dim pSub, pHref
        pHref = U("Playlist.asp") & "?id=" & rsPub("ID_PLAYLIST")
        pSub = H(NombreVisible(rsPub("USERNAME"))) & " · " & Plural(N(rsPub("TRACKS")), "canción", "canciones")
        Response.Write CardItem(pHref, MediaUrl(rsPub("PHOTO"), "playlistImages/default.jpg"), _
                                rsPub("TITLE") & "", pSub, pHref & "&autoplay=1", False)
        rsPub.MoveNext
    Loop
    rsPub.Close
    Set rsPub = Nothing
    If pubCount = 0 Then Response.Write "<div class=""empty""><h3>Sin playlists públicas</h3><p>Cuando alguien comparta una, aparecerá aquí.</p></div>"
    %>
  </div>
</section>

<%=QueueScript(False)%>

<!--#include file="inc/footer.asp"-->
