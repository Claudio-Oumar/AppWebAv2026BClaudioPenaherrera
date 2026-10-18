<%
' ============================================================================
'  Componentes de interfaz reutilizables + constructor de la cola del player
' ============================================================================

Dim gQueueJson
gQueueJson = ""

Sub QueueAdd(id, name, url, cover, artist, albumName)
    If Len(gQueueJson) > 0 Then gQueueJson = gQueueJson & ","
    gQueueJson = gQueueJson & "{""id"":" & CLng(id) & _
        ",""name"":" & JsonStr(name) & _
        ",""url"":" & JsonStr(url) & _
        ",""cover"":" & JsonStr(cover) & _
        ",""artist"":" & JsonStr(artist) & _
        ",""album"":" & JsonStr(albumName) & "}"
End Sub

Function QueueScript(autoplay)
    Dim flag
    If autoplay Then flag = "1" Else flag = "0"
    QueueScript = "<script type=""application/json"" id=""pm-queue"" data-autoplay=""" & flag & """>" & _
                  "{""tracks"":[" & gQueueJson & "]}</script>"
End Function

' ---------------------------------------------------------------------------
'  SELECT estandar de canciones con album y artista resueltos
' ---------------------------------------------------------------------------
Function SongSql()
    SongSql = "SELECT s.ID_SONG, s.SONG_NAME, s.SONG_PATH, ISNULL(s.PLAYS,0) AS PLAYS, " & _
        "(SELECT TOP 1 a.ID_ALBUM FROM TBL_TRACKLIST t INNER JOIN TBL_ALBUM a ON a.ID_ALBUM = t.ID_ALBUM WHERE t.ID_SONG = s.ID_SONG) AS ALBUM_ID, " & _
        "(SELECT TOP 1 a.TITLE_ALBUM FROM TBL_TRACKLIST t INNER JOIN TBL_ALBUM a ON a.ID_ALBUM = t.ID_ALBUM WHERE t.ID_SONG = s.ID_SONG) AS ALBUM_NAME, " & _
        "(SELECT TOP 1 a.ALBUM_IMAGE_PATH FROM TBL_TRACKLIST t INNER JOIN TBL_ALBUM a ON a.ID_ALBUM = t.ID_ALBUM WHERE t.ID_SONG = s.ID_SONG) AS COVER, " & _
        "(SELECT TOP 1 ar.ID_ARTIST FROM TBL_PLAYER p INNER JOIN TBL_ARTIST ar ON ar.ID_ARTIST = p.ID_ARTIST WHERE p.ID_SONG = s.ID_SONG) AS ARTIST_ID, " & _
        "(SELECT TOP 1 LTRIM(RTRIM(ar.ARTIST_NAME + ISNULL(' ' + ar.ARTIST_LASTNAME,''))) FROM TBL_PLAYER p INNER JOIN TBL_ARTIST ar ON ar.ID_ARTIST = p.ID_ARTIST WHERE p.ID_SONG = s.ID_SONG) AS ARTIST " & _
        "FROM TBL_SONG s "
End Function

' ---------------------------------------------------------------------------
'  Fila de cancion
' ---------------------------------------------------------------------------
Function TrackRow(rs, idx, showAlbum, removePlaylistId)
    Dim sid, nm, path, cover, artist, albumName, albumId, artistId, url, h, artistLink, albumCell

    sid    = CLng(rs("ID_SONG"))
    nm     = rs("SONG_NAME") & ""
    path   = rs("SONG_PATH") & ""
    cover  = MediaUrl(rs("COVER"), "albumImages/default.png")
    artist = rs("ARTIST") & ""
    albumName = rs("ALBUM_NAME") & ""
    albumId   = N(rs("ALBUM_ID"))
    artistId  = N(rs("ARTIST_ID"))
    url    = MediaUrl(path, "songFiles/bensound-adventure.mp3")

    If artistId > 0 Then
        artistLink = "<a href=""" & U("Artist.asp") & "?id=" & artistId & """>" & H(artist) & "</a>"
    Else
        artistLink = H(artist)
    End If

    If showAlbum And albumId > 0 Then
        albumCell = "<a href=""" & U("Album.asp") & "?id=" & albumId & """>" & H(albumName) & "</a>"
    Else
        albumCell = H(albumName)
    End If

    h = "<div class=""track"" data-song-id=""" & sid & """ data-index=""" & idx & """" & _
        " data-name=""" & A(nm) & """ data-artist=""" & A(artist) & """" & _
        " data-cover=""" & A(cover) & """ data-url=""" & A(url) & """>" & _
        "<div class=""t-idx""><span class=""idx-num"">" & idx & "</span>" & _
        "<button class=""idx-play"" type=""button"" data-play aria-label=""Reproducir"">" & _
        "<svg class=""ico""><use href=""#i-play""/></svg></button></div>" & _
        "<div class=""t-main""><img class=""t-cover"" src=""" & A(cover) & """ alt="""" loading=""lazy"">" & _
        "<div class=""t-txt""><span class=""t-name"">" & H(nm) & "</span>" & _
        "<span class=""t-artist"">" & artistLink & "</span></div></div>" & _
        "<div class=""t-album"">" & albumCell & "</div>" & _
        "<div class=""t-plays"">" & N(rs("PLAYS")) & " reps.</div>" & _
        "<div class=""t-actions"">"

    If removePlaylistId > 0 Then
        h = h & "<form method=""post"" action=""" & U("Playlist.asp") & """ class=""inline"" data-confirm=""&iquest;Quitar esta canci&oacute;n de la playlist?"">" & _
                CsrfField() & _
                "<input type=""hidden"" name=""action"" value=""remove_song"">" & _
                "<input type=""hidden"" name=""playlist_id"" value=""" & removePlaylistId & """>" & _
                "<input type=""hidden"" name=""song_id"" value=""" & sid & """>" & _
                "<button class=""t-act danger"" type=""submit"" title=""Quitar de la playlist"">" & _
                "<svg class=""ico ico-sm""><use href=""#i-trash""/></svg></button></form>"
    End If

    h = h & "</div></div>"

    QueueAdd sid, nm, url, cover, artist, albumName
    TrackRow = h
End Function

' ---------------------------------------------------------------------------
'  Tarjeta de album / artista / playlist
' ---------------------------------------------------------------------------
Function CardItem(href, img, title, subtitle, playHref, isRound)
    Dim h
    h = "<div class=""card"">" & _
        "<div class=""card-art" & IIfStr(isRound, " round", "") & """>" & _
        "<a href=""" & A(href) & """><img src=""" & A(img) & """ alt="""" loading=""lazy""></a>" & _
        "<a class=""card-play"" href=""" & A(playHref) & """ title=""Reproducir"">" & _
        "<svg class=""ico""><use href=""#i-play""/></svg></a></div>" & _
        "<a class=""card-title"" href=""" & A(href) & """>" & H(title) & "</a>" & _
        "<p class=""card-sub"">" & subtitle & "</p></div>"
    CardItem = h
End Function

' ---------------------------------------------------------------------------
'  Tarjeta de cancion (se reproduce desde la cola de la pagina)
' ---------------------------------------------------------------------------
Function SongCard(rs, idx)
    Dim sid, nm, cover, artist, albumName, albumId, url, h
    sid = CLng(rs("ID_SONG"))
    nm = rs("SONG_NAME") & ""
    cover = MediaUrl(rs("COVER"), "albumImages/default.png")
    artist = rs("ARTIST") & ""
    albumName = rs("ALBUM_NAME") & ""
    albumId = N(rs("ALBUM_ID"))
    url = MediaUrl(rs("SONG_PATH"), "songFiles/bensound-adventure.mp3")

    h = "<div class=""card"" data-song-id=""" & sid & """ data-index=""" & idx & """" & _
        " data-name=""" & A(nm) & """ data-artist=""" & A(artist) & """" & _
        " data-cover=""" & A(cover) & """ data-url=""" & A(url) & """>" & _
        "<div class=""card-art"">" & _
        "<img src=""" & A(cover) & """ alt="""" loading=""lazy"">" & _
        "<button class=""card-play"" type=""button"" data-play title=""Reproducir"">" & _
        "<svg class=""ico""><use href=""#i-play""/></svg></button></div>" & _
        "<span class=""card-title"">" & H(nm) & "</span>" & _
        "<p class=""card-sub"">" & H(artist) & "</p></div>"

    QueueAdd sid, nm, url, cover, artist, albumName
    SongCard = h
End Function

' ---------------------------------------------------------------------------
'  Encabezado de seccion
' ---------------------------------------------------------------------------
Function SectionHead(title, subtitle, linkHref, linkText)
    Dim h
    h = "<div class=""section-head""><div><h2>" & H(title) & "</h2>"
    If Len(subtitle) > 0 Then h = h & "<p>" & H(subtitle) & "</p>"
    h = h & "</div>"
    If Len(linkHref) > 0 Then
        h = h & "<a class=""section-link"" href=""" & A(linkHref) & """>" & H(linkText) & "</a>"
    End If
    h = h & "</div>"
    SectionHead = h
End Function
%>
