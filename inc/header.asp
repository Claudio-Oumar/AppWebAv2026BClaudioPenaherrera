<%
' ============================================================================
'  Cabecera comun: <head>, barra lateral y barra superior
'  Requiere que la pagina defina PageTitle y PageId antes de incluirla.
' ============================================================================
If IsEmpty(PageTitle) Then PageTitle = APP_NAME
If IsEmpty(PageId) Then PageId = ""
If IsEmpty(BodyClass) Then BodyClass = ""

SyncUser

Dim sb_rs, sb_pls, sb_hasPls
Set sb_rs = DbSelect("SELECT TOP 12 ID_PLAYLIST, TITLE, PHOTO FROM TBL_PLAYLIST WHERE ID_USER = @p0 ORDER BY TITLE", Array(CurrentUserId()))
%><!DOCTYPE html>
<html lang="es">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<meta name="theme-color" content="#0b0710">
<title><%=H(PageTitle)%> &middot; <%=APP_NAME%></title>
<link rel="icon" href="data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 32 32'%3E%3Crect width='32' height='32' rx='9' fill='%23a855f7'/%3E%3Ccircle cx='16' cy='16' r='6' fill='%230b0710'/%3E%3C/svg%3E">
<link rel="stylesheet" href="<%=U("Assets/Css/app.css")%>">
</head>
<body data-page="<%=A(PageId)%>" class="<%=A(BodyClass)%>">
<!--#include file="icons.asp"-->
<div class="app" id="app">

  <aside class="sidebar" id="sidebar">
    <a class="brand" href="<%=U("Home.asp")%>">
      <span class="brand-mark"><svg width="20" height="20"><use href="#i-music"/></svg></span>
      <span class="brand-name"><%=APP_NAME%></span>
    </a>

    <nav class="nav">
      <a class="nav-item <%=IIfStr(PageId = "home", "is-active", "")%>" href="<%=U("Home.asp")%>" data-nav="home">
        <svg class="ico"><use href="#i-home"/></svg><span>Inicio</span>
      </a>
      <a class="nav-item <%=IIfStr(PageId = "search", "is-active", "")%>" href="<%=U("Search.asp")%>" data-nav="search">
        <svg class="ico"><use href="#i-search"/></svg><span>Buscar</span>
      </a>
      <a class="nav-item <%=IIfStr(PageId = "songs", "is-active", "")%>" href="<%=U("Canciones.asp")%>" data-nav="songs">
        <svg class="ico"><use href="#i-music"/></svg><span>Canciones</span>
      </a>
      <a class="nav-item <%=IIfStr(PageId = "playlists" Or PageId = "playlist", "is-active", "")%>" href="<%=U("Playlists.asp")%>" data-nav="playlists">
        <svg class="ico"><use href="#i-library"/></svg><span>Tu biblioteca</span>
      </a>
    </nav>

    <div class="side-block">
      <div class="side-head">
        <span>Playlists</span>
        <a class="side-add" href="<%=U("Playlists.asp")%>?action=new" title="Crear playlist">
          <svg class="ico"><use href="#i-plus"/></svg>
        </a>
      </div>
      <div class="side-list">
        <%
        sb_hasPls = False
        Do While Not sb_rs.EOF
            sb_hasPls = True
            %>
            <a class="side-pl <%=IIfStr(PageId = "playlist" And CLng(CurrentPlaylistId()) = CLng(sb_rs("ID_PLAYLIST")), "is-active", "")%>"
               href="<%=U("Playlist.asp")%>?id=<%=sb_rs("ID_PLAYLIST")%>">
              <img src="<%=A(MediaUrl(sb_rs("PHOTO"), "playlistImages/default.jpg"))%>" alt="" loading="lazy">
              <span><%=H(sb_rs("TITLE"))%></span>
            </a>
            <%
            sb_rs.MoveNext
        Loop
        sb_rs.Close
        Set sb_rs = Nothing
        If Not sb_hasPls Then
            %>
            <p class="side-empty">A&uacute;n no tienes playlists.<br>
              <a href="<%=U("Playlists.asp")%>?action=new">Crea la primera</a>
            </p>
            <%
        End If
        %>
      </div>
    </div>

    <% If IsAdmin() Then %>
    <div class="side-block side-admin">
      <div class="side-head">
        <span><svg class="ico ico-sm"><use href="#i-shield"/></svg> Administraci&oacute;n</span>
      </div>
      <div class="side-list">
        <a class="side-link <%=IIfStr(PageId = "admin-users", "is-active", "")%>" href="<%=U("Admin/Users.asp")%>">
          <svg class="ico"><use href="#i-users"/></svg><span>Usuarios</span></a>
        <a class="side-link <%=IIfStr(PageId = "admin-songs", "is-active", "")%>" href="<%=U("Admin/Songs.asp")%>">
          <svg class="ico"><use href="#i-music"/></svg><span>Canciones</span></a>
        <a class="side-link <%=IIfStr(PageId = "admin-artists", "is-active", "")%>" href="<%=U("Admin/Artists.asp")%>">
          <svg class="ico"><use href="#i-mic"/></svg><span>Artistas</span></a>
        <a class="side-link <%=IIfStr(PageId = "admin-albums", "is-active", "")%>" href="<%=U("Admin/Albums.asp")%>">
          <svg class="ico"><use href="#i-disc"/></svg><span>&Aacute;lbumes</span></a>
        <a class="side-link <%=IIfStr(PageId = "admin-playlists", "is-active", "")%>" href="<%=U("Admin/Playlists.asp")%>">
          <svg class="ico"><use href="#i-list"/></svg><span>Playlists</span></a>
      </div>
    </div>
    <% End If %>

    <div class="side-foot">
      <a class="user-chip" href="<%=U("Profile.asp")%>">
        <img class="avatar" src="<%=A(MediaUrl(CurrentUserPhoto(), "userImages/default.jpg"))%>" alt="">
        <span class="user-chip-txt">
          <strong><%=H(NombreVisible(CurrentUserName()))%></strong>
          <em><%=IIfStr(IsAdmin(), "Administrador", "Usuario")%></em>
        </span>
      </a>
      <a class="logout-btn" href="<%=U("Logout.asp")%>" title="Cerrar sesi&oacute;n">
        <svg class="ico"><use href="#i-logout"/></svg>
      </a>
    </div>
  </aside>

  <div class="scrim" id="scrim"></div>

  <main class="main">
    <header class="topbar">
      <button class="icon-btn only-mobile" id="menuBtn" type="button" aria-label="Men&uacute;">
        <svg class="ico"><use href="#i-menu"/></svg>
      </button>

      <div class="history only-desktop">
        <button class="icon-btn" type="button" data-history="back" aria-label="Atr&aacute;s">
          <svg class="ico"><use href="#i-chevron-left"/></svg>
        </button>
        <button class="icon-btn" type="button" data-history="forward" aria-label="Adelante">
          <svg class="ico"><use href="#i-chevron-right"/></svg>
        </button>
      </div>

      <form class="searchbar" id="searchForm" action="<%=U("Search.asp")%>" method="get" role="search">
        <svg class="ico"><use href="#i-search"/></svg>
        <input type="search" name="q" id="searchInput" placeholder="&iquest;Qu&eacute; quieres escuchar?"
               value="<%=A(QS("q"))%>" autocomplete="off" aria-label="Buscar">
        <button type="submit" class="searchbar-go" aria-label="Buscar">Enter</button>
      </form>

      <div class="topbar-right">
        <a class="pill-btn only-desktop" href="<%=U("Playlists.asp")%>?action=new">
          <svg class="ico ico-sm"><use href="#i-plus"/></svg> Nueva playlist
        </a>
        <details class="usermenu">
          <summary>
            <img class="avatar" src="<%=A(MediaUrl(CurrentUserPhoto(), "userImages/default.jpg"))%>" alt="">
            <span class="usermenu-name only-desktop"><%=H(NombreVisible(CurrentUserName()))%></span>
            <svg class="ico ico-sm"><use href="#i-chevron-down"/></svg>
          </summary>
          <div class="usermenu-pop">
            <a href="<%=U("Profile.asp")%>"><svg class="ico ico-sm"><use href="#i-user"/></svg> Mi perfil</a>
            <a href="<%=U("Playlists.asp")%>"><svg class="ico ico-sm"><use href="#i-library"/></svg> Mis playlists</a>
            <% If IsAdmin() Then %>
            <a href="<%=U("Admin/Users.asp")%>"><svg class="ico ico-sm"><use href="#i-shield"/></svg> Panel de administraci&oacute;n</a>
            <% End If %>
            <hr>
            <a class="danger" href="<%=U("Logout.asp")%>"><svg class="ico ico-sm"><use href="#i-logout"/></svg> Cerrar sesi&oacute;n</a>
          </div>
        </details>
      </div>
    </header>

    <div class="view" id="main-view">
<%=FlashHtml()%>
