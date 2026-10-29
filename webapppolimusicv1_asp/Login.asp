<%@ Language="VBScript" CodePage="65001" %>
<!--#include file="inc/config.asp"-->
<%
If IsLoggedIn() Then Go U("Home.asp")

Dim errMsg, usr, nextUrl, pwd
errMsg = ""
usr = ""
pwd = ""
nextUrl = QS("next")

If IsPost() Then
    RequireCsrf
    usr = FORM("username")
    pwd = FORM("password")
    nextUrl = FORM("next")

    errMsg = LoginUser(usr, pwd)

    If Len(errMsg) = 0 Then
        If Len(nextUrl) > 0 And InStr(1, nextUrl, "//") = 0 And InStr(1, nextUrl, "http", vbTextCompare) = 0 Then
            Go nextUrl
        Else
            Go U("Home.asp")
        End If
    End If
ElseIf QS("expired") = "1" Then
    errMsg = "Tu sesión expiró. Vuelve a iniciar sesión."
ElseIf QS("bye") = "1" Then
    errMsg = ""
End If
%>
<!DOCTYPE html>
<html lang="es">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<meta name="theme-color" content="#0b0710">
<title>Iniciar sesión · <%=APP_NAME%></title>
<link rel="icon" href="data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 32 32'%3E%3Crect width='32' height='32' rx='9' fill='%23a855f7'/%3E%3Ccircle cx='16' cy='16' r='6' fill='%230b0710'/%3E%3C/svg%3E">
<link rel="stylesheet" href="<%=U("Assets/Css/app.css")%>">
</head>
<body class="auth-body">
<!--#include file="inc/icons.asp"-->
<div class="auth">

  <section class="auth-art">
    <div class="auth-logo">
      <span class="brand-mark"><svg width="20" height="20"><use href="#i-music"/></svg></span>
      <%=APP_NAME%>
    </div>
    <div>
      <h2>Tu música suena mejor en morado.</h2>
      <p>Miles de canciones, álbumes y artistas en un solo lugar. Crea tus playlists y escúchalas donde quieras.</p>
      <ul>
        <li><svg class="ico ico-sm"><use href="#i-play"/></svg> Reproducción continua mientras navegas</li>
        <li><svg class="ico ico-sm"><use href="#i-heart"/></svg> Playlists públicas y privadas</li>
        <li><svg class="ico ico-sm"><use href="#i-disc"/></svg> Álbumes, artistas y catálogo completo</li>
      </ul>
    </div>
    <footer>&copy; <%=Year(Now())%> <%=APP_NAME%> · Escuela Politécnica Nacional</footer>
  </section>

  <section class="auth-panel">
    <div class="auth-card">
      <h1>Bienvenido de nuevo</h1>
      <p class="sub">Inicia sesión para continuar escuchando.</p>

      <% If Len(errMsg) > 0 Then %>
      <div class="err-box">
        <svg class="ico ico-sm"><use href="#i-alert"/></svg>
        <span><%=H(errMsg)%></span>
      </div>
      <% End If %>

      <form method="post" action="<%=U("Login.asp")%>" autocomplete="on">
        <%=CsrfField()%>
        <input type="hidden" name="next" value="<%=A(nextUrl)%>">

        <div class="field">
          <label for="username">Usuario</label>
          <input class="input" type="text" id="username" name="username" value="<%=A(usr)%>"
                 placeholder="Tu nombre de usuario" required autofocus>
        </div>

        <div class="field">
          <label for="password">Contraseña</label>
          <input class="input" type="password" id="password" name="password"
                 placeholder="••••••••" required>
        </div>

        <button class="btn btn-primary btn-block" type="submit">
          <svg class="ico ico-sm"><use href="#i-arrow-right"/></svg> Entrar
        </button>
      </form>

      <p class="auth-alt">¿No tienes cuenta? <a href="<%=U("Register.asp")%>">Regístrate gratis</a></p>

      <%
      ' Cuentas reales leidas de TBL_USER (no se asume ninguna credencial fija).
      Dim rsDemo, dName, dPwd, dRole
      Set rsDemo = DbSelect("SELECT TOP 4 USERNAME, USER_TYPE, PASSWORD FROM TBL_USER " & _
                            "ORDER BY USER_TYPE DESC, ID_USER", Array())
      %>
      <div class="demo-box">
        <strong>Cuentas en tu base de datos</strong><br>
        <%
        If rsDemo.EOF Then
            Response.Write "Todavía no hay usuarios registrados."
        End If
        Do While Not rsDemo.EOF
            dName = rsDemo("USERNAME") & ""
            dPwd  = rsDemo("PASSWORD") & ""
            dRole = IIfStr(N(rsDemo("USER_TYPE")) = 1, "Administrador", "Usuario")
            If Len(dPwd) = 40 Then dPwd = "contraseña SHA1"
            Response.Write H(dName) & " &middot; " & dRole & " &middot; <code>" & H(dPwd) & "</code><br>"
            rsDemo.MoveNext
        Loop
        rsDemo.Close
        Set rsDemo = Nothing
        %>
      </div>
    </div>
  </section>
</div>
<%
DbClose
%>
</body>
</html>
