<%
' ============================================================================
'  Autenticacion, sesion, roles y proteccion CSRF
' ============================================================================

Function IsLoggedIn()
    IsLoggedIn = False
    If IsNumeric(Session("pm_uid") & "") Then
        If CLng(Session("pm_uid")) > 0 Then IsLoggedIn = True
    End If
End Function

Function CurrentUserId()
    If IsLoggedIn() Then
        CurrentUserId = CLng(Session("pm_uid"))
    Else
        CurrentUserId = 0
    End If
End Function

Function CurrentUserName()
    CurrentUserName = Session("pm_uname") & ""
End Function

Function CurrentUserPhoto()
    CurrentUserPhoto = Session("pm_uphoto") & ""
End Function

Function CurrentUserEmail()
    CurrentUserEmail = Session("pm_uemail") & ""
End Function

Function CurrentUserType()
    If IsLoggedIn() Then
        CurrentUserType = CLng(Session("pm_utype"))
    Else
        CurrentUserType = -1
    End If
End Function

Function IsAdmin()
    IsAdmin = (IsLoggedIn() And CurrentUserType() = ROLE_ADMIN)
End Function

' ---------------------------------------------------------------------------
'  Guardas de acceso
' ---------------------------------------------------------------------------
Sub RequireLogin()
    If Not IsLoggedIn() Then
        Go U("Login.asp") & "?next=" & Server.URLEncode(CurrentUrl())
    End If
End Sub

Sub RequireAdmin()
    RequireLogin
    If Not IsAdmin() Then
        SetError "No tienes permisos para acceder a esa seccion."
        Go U("Home.asp")
    End If
End Sub

' Impide que un usuario normal ejecute acciones de administrador
Sub DenyUnlessAdmin()
    If Not IsAdmin() Then
        Response.Status = "403 Forbidden"
        Response.Write "<!DOCTYPE html><html lang=""es""><head><meta charset=""utf-8""><title>403</title></head>" & _
                       "<body style=""background:#0b0710;color:#e9e2f5;font-family:Segoe UI,sans-serif;" & _
                       "display:flex;align-items:center;justify-content:center;height:100vh;margin:0"">" & _
                       "<div style=""text-align:center""><h1 style=""color:#a855f7"">403 &middot; Acceso denegado</h1>" & _
                       "<p>Esta operaci&oacute;n requiere una cuenta de administrador.</p>" & _
                       "<a href=""" & U("Home.asp") & """ style=""color:#c084fc"">Volver al inicio</a></div></body></html>"
        Response.End
    End If
End Sub

' ---------------------------------------------------------------------------
'  CSRF
' ---------------------------------------------------------------------------
Function CsrfToken()
    If Len(Session("pm_csrf") & "") = 0 Then
        Randomize
        Session("pm_csrf") = Session.SessionID & "." & Replace(CStr(Timer), ",", "") & "." & _
                             CStr(Int(Rnd() * 9999999))
    End If
    CsrfToken = Session("pm_csrf") & ""
End Function

Function CsrfField()
    CsrfField = "<input type=""hidden"" name=""_csrf"" value=""" & A(CsrfToken()) & """>"
End Function

Sub RequireCsrf()
    If Not IsPost() Then Exit Sub
    RequireCsrfToken FORM("_csrf")
End Sub

' Variante para formularios multipart (el token se lee del parser)
Sub RequireCsrfToken(tok)
    If Not IsPost() Then Exit Sub
    If tok <> CsrfToken() Then
        Response.Status = "400 Bad Request"
        Response.Write "<!DOCTYPE html><html lang=""es""><head><meta charset=""utf-8""><title>400</title></head>" & _
                       "<body style=""background:#0b0710;color:#e9e2f5;font-family:Segoe UI,sans-serif;" & _
                       "padding:60px;text-align:center""><h1 style=""color:#a855f7"">Sesi&oacute;n expirada</h1>" & _
                       "<p>El formulario perdi&oacute; su validez. Vuelve a iniciar sesi&oacute;n.</p>" & _
                       "<a href=""" & U("Login.asp") & """ style=""color:#c084fc"">Ir al login</a></body></html>"
        Response.End
    End If
End Sub

' ---------------------------------------------------------------------------
'  Inicio / cierre de sesion
' ---------------------------------------------------------------------------
' Devuelve "" si el login fue correcto, o el mensaje de error.
Function LoginUser(usr, pwd)
    Dim rs, sql, params
    LoginUser = "Usuario o contraseña incorrectos."

    If Len(usr) = 0 Or Len(pwd) = 0 Then
        LoginUser = "Debes ingresar usuario y contraseña."
        Exit Function
    End If

    sql = "SELECT TOP 1 ID_USER, USERNAME, EMAIL, USER_TYPE, USER_PHOTO " & _
          "FROM TBL_USER " & _
          "WHERE USERNAME = @p0 AND ( " & _
          "      UPPER(PASSWORD) = UPPER(CONVERT(varchar(40), HASHBYTES('SHA1', CONVERT(varchar(50), @p1)), 2)) " & _
          "      OR PASSWORD = @p1 )"

    Set rs = DbSelect(sql, Array(usr, pwd))
    If rs.EOF Then
        rs.Close
        Set rs = Nothing
        Exit Function
    End If

    Session("pm_uid")    = CLng(rs("ID_USER"))
    Session("pm_uname")  = rs("USERNAME") & ""
    Session("pm_uemail") = rs("EMAIL") & ""
    Session("pm_utype")  = CLng(rs("USER_TYPE"))
    Session("pm_uphoto") = rs("USER_PHOTO") & ""
    rs.Close
    Set rs = Nothing

    ' Token CSRF nuevo en cada inicio de sesion
    Session("pm_csrf") = ""

    LoginUser = ""
End Function

Sub LogoutUser()
    Session.Contents.RemoveAll()
    Session.Abandon
End Sub

' ---------------------------------------------------------------------------
'  Sincroniza los datos de sesion con la BD (refleja cambios del administrador)
' ---------------------------------------------------------------------------
Sub SyncUser()
    Dim rs
    If Not IsLoggedIn() Then Exit Sub

    Set rs = DbSelect("SELECT USERNAME, EMAIL, USER_TYPE, USER_PHOTO FROM TBL_USER WHERE ID_USER = @p0", _
                      Array(CurrentUserId()))
    If rs.EOF Then
        rs.Close
        Set rs = Nothing
        LogoutUser
        Go U("Login.asp") & "?expired=1"
    Else
        Session("pm_uname")  = rs("USERNAME") & ""
        Session("pm_uemail") = rs("EMAIL") & ""
        Session("pm_utype")  = CLng(rs("USER_TYPE"))
        Session("pm_uphoto") = rs("USER_PHOTO") & ""
    End If
    rs.Close
    Set rs = Nothing
End Sub
%>
