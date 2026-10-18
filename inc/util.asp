<%
' ============================================================================
'  Utilidades generales
' ============================================================================

' ---------------------------------------------------------------------------
'  Ruta virtual de la aplicacion (funciona en raiz o en directorio virtual)
' ---------------------------------------------------------------------------
Function AppPath()
    Dim p, i, cached
    If Not IsEmpty(Application("PM_APP_PATH")) Then
        AppPath = Application("PM_APP_PATH")
        Exit Function
    End If

    p = Request.ServerVariables("APPL_MD_PATH") & ""
    i = InStr(1, p, "/ROOT", vbTextCompare)
    If i > 0 Then p = Mid(p, i + 5)
    If p = "/" Then p = ""
    If Right(p, 1) = "/" Then p = Left(p, Len(p) - 1)

    Application.Lock
    Application("PM_APP_PATH") = p
    Application.Unlock

    AppPath = p
End Function

' URL absoluta dentro de la aplicacion
Function U(path)
    If Left(path, 1) = "/" Then
        U = AppPath() & path
    Else
        U = AppPath() & "/" & path
    End If
End Function

' ---------------------------------------------------------------------------
'  Convierte una ruta almacenada en la BD ("~/songFiles/x.mp3") en URL usable
' ---------------------------------------------------------------------------
Function MediaUrl(path, fallback)
    Dim p
    p = Trim(path & "")
    If Len(p) = 0 Then
        MediaUrl = U(fallback)
        Exit Function
    End If
    If Left(p, 2) = "~/" Then
        p = Mid(p, 3)
    ElseIf Left(p, 1) = "~" Then
        p = Mid(p, 2)
    End If
    If InStr(1, p, "http://", vbTextCompare) = 1 Or InStr(1, p, "https://", vbTextCompare) = 1 Then
        MediaUrl = p
    ElseIf Left(p, 1) = "/" Then
        MediaUrl = AppPath() & p
    Else
        MediaUrl = AppPath() & "/" & p
    End If
End Function

' ---------------------------------------------------------------------------
'  Salida segura
' ---------------------------------------------------------------------------
Function H(s)
    H = Server.HTMLEncode(s & "")
End Function

Function A(s)
    Dim t
    t = s & ""
    t = Replace(t, "&", "&amp;")
    t = Replace(t, """", "&quot;")
    t = Replace(t, "<", "&lt;")
    t = Replace(t, ">", "&gt;")
    t = Replace(t, "'", "&#39;")
    A = t
End Function

' Cadena JSON segura
Function JsonStr(s)
    Dim t
    t = s & ""
    t = Replace(t, "\", "\\")
    t = Replace(t, """", "\""")
    t = Replace(t, vbCrLf, " ")
    t = Replace(t, vbCr, " ")
    t = Replace(t, vbLf, " ")
    t = Replace(t, vbTab, " ")
    JsonStr = """" & t & """"
End Function

' ---------------------------------------------------------------------------
'  Conversiones tolerantes
' ---------------------------------------------------------------------------
Function IIfStr(cond, valorSi, valorNo)
    If cond Then
        IIfStr = valorSi
    Else
        IIfStr = valorNo
    End If
End Function

' Playlist activa (la define Playlist.asp antes de incluir la cabecera)
Function CurrentPlaylistId()
    If IsEmpty(ActivePlaylistId) Then
        CurrentPlaylistId = 0
    ElseIf IsNumeric(ActivePlaylistId) Then
        CurrentPlaylistId = CLng(ActivePlaylistId)
    Else
        CurrentPlaylistId = 0
    End If
End Function

Function InCsv(csv, val)
    Dim c
    c = Replace(csv & "", " ", "")
    InCsv = (InStr(1, "," & c & ",", "," & val & ",") > 0)
End Function

Function N(v)
    If IsNull(v) Or IsEmpty(v) Then
        N = 0
    ElseIf IsNumeric(v) Then
        N = CLng(v)
    Else
        N = 0
    End If
End Function

Function S(v)
    If IsNull(v) Or IsEmpty(v) Then
        S = ""
    Else
        S = Trim(CStr(v))
    End If
End Function

Function QS(name)
    QS = Trim(Request.QueryString(name) & "")
End Function

Function FORM(name)
    FORM = Trim(Request.Form(name) & "")
End Function

Function IsPost()
    IsPost = (UCase(Request.ServerVariables("REQUEST_METHOD")) = "POST")
End Function

Function CurrentUrl()
    Dim u
    u = Request.ServerVariables("URL") & ""
    If Len(Request.ServerVariables("QUERY_STRING") & "") > 0 Then
        u = u & "?" & Request.ServerVariables("QUERY_STRING")
    End If
    CurrentUrl = u
End Function

' ---------------------------------------------------------------------------
'  Fechas en espanol
' ---------------------------------------------------------------------------
Function MesNombre(m)
    Dim meses
    meses = Array("enero", "febrero", "marzo", "abril", "mayo", "junio", _
                  "julio", "agosto", "septiembre", "octubre", "noviembre", "diciembre")
    If m >= 1 And m <= 12 Then
        MesNombre = meses(m - 1)
    Else
        MesNombre = ""
    End If
End Function

Function FechaCorta(d)
    If IsNull(d) Or IsEmpty(d) Then
        FechaCorta = "&mdash;"
    ElseIf Not IsDate(d) Then
        FechaCorta = "&mdash;"
    Else
        FechaCorta = Day(d) & " " & Left(MesNombre(Month(d)), 3) & " " & Year(d)
    End If
End Function

Function FechaInput(d)
    If IsNull(d) Or IsEmpty(d) Then
        FechaInput = ""
    ElseIf Not IsDate(d) Then
        FechaInput = ""
    Else
        FechaInput = Year(d) & "-" & Right("0" & Month(d), 2) & "-" & Right("0" & Day(d), 2)
    End If
End Function

Function FechaHora(d)
    If IsNull(d) Or IsEmpty(d) Then
        FechaHora = "&mdash;"
    ElseIf Not IsDate(d) Then
        FechaHora = "&mdash;"
    Else
        FechaHora = Day(d) & " " & Left(MesNombre(Month(d)), 3) & " " & Year(d) & " &middot; " & _
                    Right("0" & Hour(d), 2) & ":" & Right("0" & Minute(d), 2)
    End If
End Function

Function Saludo()
    Dim hh
    hh = Hour(Now())
    If hh < 12 Then
        Saludo = "Buenos d&iacute;as"
    ElseIf hh < 19 Then
        Saludo = "Buenas tardes"
    Else
        Saludo = "Buenas noches"
    End If
End Function

' ---------------------------------------------------------------------------
'  Texto
' ---------------------------------------------------------------------------
Function Trunc(s, n)
    Dim t
    t = s & ""
    If Len(t) > n Then
        Trunc = Left(t, n - 1) & "..."
    Else
        Trunc = t
    End If
End Function

Function Iniciales(nombre)
    Dim partes, i, r
    partes = Split(Trim(nombre & ""), " ")
    r = ""
    For i = 0 To UBound(partes)
        If Len(partes(i)) > 0 And Len(r) < 2 Then
            r = r & UCase(Left(partes(i), 1))
        End If
    Next
    If Len(r) = 0 Then r = "?"
    Iniciales = r
End Function

' ---------------------------------------------------------------------------
'  Nombre visible del usuario.
'  Corrige solo la grafía al mostrar (no escribe nada en la base). Sirve para
'  nombres que en TBL_USER están sin ñ o sin tildes. Si el nombre ya está bien
'  escrito en la base, se devuelve tal cual: esta lista se puede vaciar sin
'  romper nada.
' ---------------------------------------------------------------------------
Function NombreVisible(usuario)
    Dim u
    u = LCase(Trim(usuario & ""))
    Select Case u
        Case "claudio penaherrera"
            NombreVisible = "Claudio Peñaherrera"
        Case Else
            NombreVisible = usuario & ""
    End Select
End Function

Function Plural(n, singular, pluralForm)
    If CLng(n) = 1 Then
        Plural = n & " " & singular
    Else
        Plural = n & " " & pluralForm
    End If
End Function

Function DurMinSeg(seg)
    Dim m, s
    If seg < 0 Then seg = 0
    m = Int(seg / 60)
    s = seg Mod 60
    DurMinSeg = m & ":" & Right("0" & s, 2)
End Function

' ---------------------------------------------------------------------------
'  Mensajes flash
' ---------------------------------------------------------------------------
Sub SetFlash(msg, kind)
    Session("pm_flash")      = msg
    Session("pm_flash_kind") = kind
End Sub

Sub SetOk(msg)
    SetFlash msg, "ok"
End Sub

Sub SetError(msg)
    SetFlash msg, "error"
End Sub

Function FlashHtml()
    Dim m, k, cls, icon
    m = Session("pm_flash") & ""
    k = Session("pm_flash_kind") & ""
    Session("pm_flash") = ""
    Session("pm_flash_kind") = ""
    If Len(m) = 0 Then
        FlashHtml = ""
        Exit Function
    End If
    If k = "error" Then
        cls  = "flash flash-error"
        icon = "alert"
    Else
        cls  = "flash flash-ok"
        icon = "check"
    End If
    FlashHtml = "<div class=""" & cls & """ role=""status""><svg class=""ico"" width=""18"" height=""18"">" & _
                "<use href=""#i-" & icon & """/></svg><span>" & H(m) & "</span></div>"
End Function

' ---------------------------------------------------------------------------
'  Redireccion
' ---------------------------------------------------------------------------
Sub Go(url)
    Response.Redirect url
    Response.End
End Sub

' Redirige de vuelta a una URL interna validada (evita open redirect)
Sub GoBack(defaultUrl)
    Dim n
    n = QS("next")
    If Len(n) = 0 Then n = FORM("next")
    If Len(n) > 0 Then
        If InStr(1, n, "//") = 0 And InStr(1, n, "http", vbTextCompare) = 0 Then
            Go n
            Exit Sub
        End If
    End If
    Go defaultUrl
End Sub
%>
