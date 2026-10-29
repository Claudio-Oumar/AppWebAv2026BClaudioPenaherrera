<%@ Language="VBScript" CodePage="65001" %>
<!--#include file="inc/config.asp"-->
<%
If IsLoggedIn() Then Go U("Home.asp")

Dim errMsg, vUser, vEmail, vBirth, vPass
errMsg = ""
vUser = ""
vEmail = ""
vBirth = ""
vPass = ""

If IsPost() Then
    RequireCsrf
    vUser  = FORM("username")
    vEmail = FORM("email")
    vBirth = FORM("birthday")
    vPass  = FORM("password")
    Dim vPass2
    vPass2 = FORM("password2")

    If Len(vUser) < 3 Or Len(vUser) > 50 Then
        errMsg = "El usuario debe tener entre 3 y 50 caracteres."
    ElseIf InStr(vUser, " ") > 0 Then
        errMsg = "El nombre de usuario no puede contener espacios."
    ElseIf Len(vEmail) = 0 Or InStr(vEmail, "@") = 0 Or InStr(vEmail, ".") = 0 Then
        errMsg = "Ingresa un correo electrónico válido."
    ElseIf Len(vPass) < 6 Then
        errMsg = "La contraseña debe tener al menos 6 caracteres."
    ElseIf vPass <> vPass2 Then
        errMsg = "Las contraseñas no coinciden."
    ElseIf Len(vBirth) > 0 And Not IsDate(vBirth) Then
        errMsg = "La fecha de nacimiento no es válida."
    ElseIf N(DbScalar("SELECT COUNT(*) FROM TBL_USER WHERE USERNAME = @p0", Array(vUser))) > 0 Then
        errMsg = "Ese nombre de usuario ya está en uso."
    ElseIf N(DbScalar("SELECT COUNT(*) FROM TBL_USER WHERE EMAIL = @p0", Array(vEmail))) > 0 Then
        errMsg = "Ese correo ya está registrado."
    Else
        Dim newId, bdSql
        bdSql = "CONVERT(datetime, NULLIF(@p3, ''), 120)"

        newId = DbInsert( _
            "INSERT INTO TBL_USER (USERNAME, PASSWORD, EMAIL, BIRTHDAY, USER_PHOTO, USER_TYPE) " & _
            "VALUES (@p0, CONVERT(varchar(40), HASHBYTES('SHA1', CONVERT(varchar(50), @p1)), 2), " & _
            "@p2, " & bdSql & ", @p4, 0)", _
            Array(vUser, vPass, vEmail, vBirth, "~/userImages/default.jpg"))

        If newId > 0 Then
            LoginUser vUser, vPass
            SetOk "¡Bienvenido a PoliMusic, " & vUser & "! Tu cuenta fue creada."
            Go U("Home.asp")
        Else
            errMsg = "No se pudo crear la cuenta. Inténtalo de nuevo."
        End If
    End If
End If
%>
<!DOCTYPE html>
<html lang="es">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<meta name="theme-color" content="#0b0710">
<title>Crear cuenta · <%=APP_NAME%></title>
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
      <h2>Crea tu cuenta y arma tu universo sonoro.</h2>
      <p>Regístrate gratis para guardar tus playlists favoritas y descubrir nuevos artistas.</p>
      <ul>
        <li><svg class="ico ico-sm"><use href="#i-check"/></svg> Sin costo, sin tarjetas</li>
        <li><svg class="ico ico-sm"><use href="#i-check"/></svg> Playlists ilimitadas</li>
        <li><svg class="ico ico-sm"><use href="#i-check"/></svg> Tu perfil personalizable</li>
      </ul>
    </div>
    <footer>&copy; <%=Year(Now())%> <%=APP_NAME%> · Escuela Politécnica Nacional</footer>
  </section>

  <section class="auth-panel">
    <div class="auth-card">
      <h1>Crear cuenta</h1>
      <p class="sub">Solo necesitas unos segundos.</p>

      <% If Len(errMsg) > 0 Then %>
      <div class="err-box">
        <svg class="ico ico-sm"><use href="#i-alert"/></svg>
        <span><%=H(errMsg)%></span>
      </div>
      <% End If %>

      <form method="post" action="<%=U("Register.asp")%>">
        <%=CsrfField()%>

        <div class="field">
          <label for="username">Nombre de usuario</label>
          <input class="input" type="text" id="username" name="username" value="<%=A(vUser)%>"
                 placeholder="Ej. claudio_penaherrera" required minlength="3" maxlength="50" autofocus>
        </div>

        <div class="field">
          <label for="email">Correo electrónico</label>
          <input class="input" type="email" id="email" name="email" value="<%=A(vEmail)%>"
                 placeholder="tucorreo@epn.edu.ec" required maxlength="50">
        </div>

        <div class="field">
          <label for="birthday">Fecha de nacimiento <span class="hint">(opcional)</span></label>
          <input class="input" type="date" id="birthday" name="birthday" value="<%=A(vBirth)%>">
        </div>

        <div class="field">
          <label for="password">Contraseña</label>
          <input class="input" type="password" id="password" name="password"
                 placeholder="Mínimo 6 caracteres" required minlength="6">
        </div>

        <div class="field">
          <label for="password2">Confirmar contraseña</label>
          <input class="input" type="password" id="password2" name="password2"
                 placeholder="Repite la contraseña" required minlength="6">
        </div>

        <button class="btn btn-primary btn-block" type="submit">
          <svg class="ico ico-sm"><use href="#i-user"/></svg> Crear mi cuenta
        </button>
      </form>

      <p class="auth-alt">¿Ya tienes cuenta? <a href="<%=U("Login.asp")%>">Inicia sesión</a></p>
    </div>
  </section>
</div>
<%
DbClose
%>
</body>
</html>
