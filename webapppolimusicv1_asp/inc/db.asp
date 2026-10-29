<%
' ============================================================================
'  Capa de acceso a datos (ADO + SQL Server)
'  Todas las consultas son parametrizadas para evitar inyeccion SQL.
' ============================================================================

Dim gConn
Dim gConnProvider

' ---------------------------------------------------------------------------
'  Abre (una sola vez por pagina) la conexion a SQL Server.
'  Prueba varios proveedores OLE DB hasta encontrar uno disponible.
' ---------------------------------------------------------------------------
Sub DbOpen()
    If IsObject(gConn) Then
        If Not (gConn Is Nothing) Then
            If gConn.State = 1 Then Exit Sub
        End If
    End If

    Dim providers, i, cs, ok
    providers = Array("MSOLEDBSQL", "SQLNCLI11", "SQLOLEDB")
    ok = False

    For i = 0 To UBound(providers)
        Select Case providers(i)
            Case "MSOLEDBSQL"
                cs = "Provider=MSOLEDBSQL;Server=" & DB_SERVER & ";Database=" & DB_NAME & _
                     ";UID=" & DB_USER & ";PWD=" & DB_PASS & _
                     ";Encrypt=Optional;TrustServerCertificate=Yes;"
            Case "SQLNCLI11"
                cs = "Provider=SQLNCLI11;Server=" & DB_SERVER & ";Database=" & DB_NAME & _
                     ";UID=" & DB_USER & ";PWD=" & DB_PASS & ";Encrypt=no;"
            Case Else
                cs = "Provider=SQLOLEDB;Server=" & DB_SERVER & ";Database=" & DB_NAME & _
                     ";UID=" & DB_USER & ";PWD=" & DB_PASS & ";"
        End Select

        On Error Resume Next
        Set gConn = Server.CreateObject("ADODB.Connection")
        gConn.ConnectionTimeout = 15
        gConn.CursorLocation = 3          ' adUseClient: permite RecordCount y MoveFirst
        gConn.Open cs
        If Err.Number = 0 Then
            ok = True
            gConnProvider = providers(i)
        Else
            Err.Clear
            Set gConn = Nothing
        End If
        On Error GoTo 0

        If ok Then Exit For
    Next

    If Not ok Then
        Response.Write "<!DOCTYPE html><html lang=""es""><head><meta charset=""utf-8"">" & _
            "<title>Sin conexion</title><style>body{background:#0b0710;color:#e9e2f5;" & _
            "font-family:Segoe UI,sans-serif;display:flex;align-items:center;justify-content:center;" & _
            "height:100vh;margin:0}div{max-width:560px;padding:40px;border:1px solid #2c1f3d;" & _
            "border-radius:18px;background:#150e1f}h1{color:#a855f7;margin-top:0}</style></head><body><div>" & _
            "<h1>No se pudo conectar a SQL Server</h1><p>Verifique que el servicio est&eacute; activo y que la " & _
            "base de datos <b>" & DB_NAME & "</b> exista en <b>" & DB_SERVER & "</b>.</p>" & _
            "<p style=""color:#a99bbd;font-size:13px"">Credenciales: " & DB_USER & "</p></div></body></html>"
        Response.End
    End If
End Sub

' ---------------------------------------------------------------------------
'  Cierra la conexion (se invoca desde el pie de pagina).
' ---------------------------------------------------------------------------
Sub DbClose()
    On Error Resume Next
    If IsObject(gConn) Then
        If Not (gConn Is Nothing) Then
            If gConn.State = 1 Then gConn.Close
            Set gConn = Nothing
        End If
    End If
    On Error GoTo 0
End Sub

' ---------------------------------------------------------------------------
'  Construye un ADODB.Command parametrizado.
'  Acepta Null, Boolean, Date, numeros y cadenas.
' ---------------------------------------------------------------------------
Function DbCmd(sql, params)
    Dim cmd, i, v, vt

    If Not IsObject(gConn) Then
        DbOpen
    ElseIf gConn Is Nothing Then
        DbOpen
    End If

    Set cmd = Server.CreateObject("ADODB.Command")
    Set cmd.ActiveConnection = gConn
    cmd.CommandType = 1            ' adCmdText
    cmd.CommandText = sql
    cmd.CommandTimeout = 30

    If IsArray(params) Then
        For i = 0 To UBound(params)
            v  = params(i)
            vt = VarType(v)

            If vt = 1 Then
                cmd.Parameters.Append cmd.CreateParameter("@p" & i, 200, 1, 4000, Null)
            ElseIf vt = 11 Then
                If v Then
                    cmd.Parameters.Append cmd.CreateParameter("@p" & i, 3, 1, , 1)
                Else
                    cmd.Parameters.Append cmd.CreateParameter("@p" & i, 3, 1, , 0)
                End If
            ElseIf vt = 7 Then
                cmd.Parameters.Append cmd.CreateParameter("@p" & i, 135, 1, , v)
            ElseIf vt = 2 Or vt = 3 Or vt = 16 Or vt = 17 Then
                cmd.Parameters.Append cmd.CreateParameter("@p" & i, 3, 1, , CLng(v))
            ElseIf vt = 4 Or vt = 5 Or vt = 6 Then
                cmd.Parameters.Append cmd.CreateParameter("@p" & i, 5, 1, , CDbl(v))
            Else
                cmd.Parameters.Append cmd.CreateParameter("@p" & i, 200, 1, 4000, CStr(v))
            End If
        Next
    End If

    Set DbCmd = cmd
End Function

' ---------------------------------------------------------------------------
'  SELECT -> Recordset de solo avance (el llamador debe cerrarlo).
' ---------------------------------------------------------------------------
Function DbSelect(sql, params)
    Dim cmd
    Set cmd = DbCmd(sql, params)
    Set DbSelect = cmd.Execute
End Function

' ---------------------------------------------------------------------------
'  INSERT / UPDATE / DELETE -> numero de filas afectadas.
' ---------------------------------------------------------------------------
Function DbExec(sql, params)
    Dim cmd, rs, n
    n = 0
    Set cmd = DbCmd("SET NOCOUNT ON; " & sql & "; SELECT @@ROWCOUNT AS N", params)
    Set rs  = cmd.Execute
    If Not (rs Is Nothing) Then
        If Not rs.EOF Then n = CLng(rs("N").Value)
        rs.Close
    End If
    Set rs = Nothing
    DbExec = n
End Function

' ---------------------------------------------------------------------------
'  Primer valor de la primera fila.
' ---------------------------------------------------------------------------
Function DbScalar(sql, params)
    Dim rs
    Set rs = DbSelect(sql, params)
    If rs.EOF Then
        DbScalar = Null
    Else
        DbScalar = rs(0).Value
    End If
    rs.Close
    Set rs = Nothing
End Function

' ---------------------------------------------------------------------------
'  INSERT que devuelve el IDENTITY generado.
' ---------------------------------------------------------------------------
Function DbInsert(sql, params)
    Dim cmd, rs, newId
    newId = 0
    Set cmd = DbCmd("SET NOCOUNT ON; " & sql & "; SELECT CAST(SCOPE_IDENTITY() AS int) AS NEWID", params)
    Set rs  = cmd.Execute
    If Not rs.EOF Then
        If Not IsNull(rs("NEWID").Value) Then newId = CLng(rs("NEWID").Value)
    End If
    rs.Close
    Set rs = Nothing
    DbInsert = newId
End Function

' ---------------------------------------------------------------------------
'  Utilidades de fecha para SQL Server
' ---------------------------------------------------------------------------
Function SqlDateTime(d)
    If IsEmpty(d) Or IsNull(d) Then
        SqlDateTime = Null
    ElseIf Not IsDate(d) Then
        SqlDateTime = Null
    Else
        SqlDateTime = Year(d) & "-" & Right("0" & Month(d), 2) & "-" & Right("0" & Day(d), 2) & _
                      " " & Right("0" & Hour(d), 2) & ":" & Right("0" & Minute(d), 2) & ":" & Right("0" & Second(d), 2)
    End If
End Function

Function SqlDateOnly(d)
    If IsEmpty(d) Or IsNull(d) Then
        SqlDateOnly = Null
    ElseIf Not IsDate(d) Then
        SqlDateOnly = Null
    Else
        SqlDateOnly = Year(d) & "-" & Right("0" & Month(d), 2) & "-" & Right("0" & Day(d), 2)
    End If
End Function
%>
