<%
' ============================================================================
'  Subida de archivos multipart/form-data (100% ASP clasico, sin componentes)
' ============================================================================

' ---------------------------------------------------------------------------
'  Raiz fisica de la aplicacion (funciona en raiz o en directorio virtual)
' ---------------------------------------------------------------------------
Function PhysRoot()
    Dim scriptVirt, scriptPhys, cut

    If Not IsEmpty(Application("PM_PHYS_ROOT")) Then
        PhysRoot = Application("PM_PHYS_ROOT")
        Exit Function
    End If

    scriptVirt = Request.ServerVariables("SCRIPT_NAME") & ""
    scriptPhys = Server.MapPath(scriptVirt)
    cut = Len(scriptVirt) - Len(AppPath())
    If cut < 0 Then cut = 0
    If cut > 0 Then
        PhysRoot = Left(scriptPhys, Len(scriptPhys) - cut)
    Else
        PhysRoot = scriptPhys
    End If

    Application.Lock
    Application("PM_PHYS_ROOT") = PhysRoot
    Application.Unlock
End Function

' ---------------------------------------------------------------------------
'  Conversiones binario <-> cadena (mapeo 1 byte = 1 caracter, iso-8859-1)
' ---------------------------------------------------------------------------
Function B2S(bin)
    Dim st
    Set st = Server.CreateObject("ADODB.Stream")
    st.Type = 1
    st.Open
    st.Write bin
    st.Position = 0
    st.Type = 2
    st.Charset = "iso-8859-1"
    st.Position = 0
    B2S = st.ReadText
    st.Close
    Set st = Nothing
End Function

Function S2B(str)
    Dim st
    Set st = Server.CreateObject("ADODB.Stream")
    st.Type = 2
    st.Charset = "iso-8859-1"
    st.Open
    st.WriteText str
    st.Position = 0
    st.Type = 1
    S2B = st.Read
    st.Close
    Set st = Nothing
End Function

' Convierte bytes UTF-8 (en cadena binaria) a texto Unicode
Function Utf8Decode(binStr)
    Dim st
    On Error Resume Next
    Set st = Server.CreateObject("ADODB.Stream")
    st.Type = 1
    st.Open
    st.Write S2B(binStr)
    st.Position = 0
    st.Type = 2
    st.Charset = "utf-8"
    st.Position = 0
    Utf8Decode = st.ReadText
    st.Close
    Set st = Nothing
    If Err.Number <> 0 Then
        Utf8Decode = binStr
        Err.Clear
    End If
    On Error GoTo 0
End Function

' ---------------------------------------------------------------------------
'  Guarda una cadena binaria en disco
' ---------------------------------------------------------------------------
Function SaveBinaryToFile(binStr, physPath)
    Dim st, ok
    ok = False
    On Error Resume Next
    Set st = Server.CreateObject("ADODB.Stream")
    st.Type = 1
    st.Open
    st.Write S2B(binStr)
    st.SaveToFile physPath, 2
    st.Close
    Set st = Nothing
    If Err.Number = 0 Then ok = True
    Err.Clear
    On Error GoTo 0
    SaveBinaryToFile = ok
End Function

' ---------------------------------------------------------------------------
'  Nombre de archivo seguro
' ---------------------------------------------------------------------------
Function SanitizeSlug(txt)
    Dim t, i, c, out
    t = LCase(Trim(txt & ""))
    t = Replace(t, "á", "a") : t = Replace(t, "é", "e") : t = Replace(t, "í", "i")
    t = Replace(t, "ó", "o") : t = Replace(t, "ú", "u") : t = Replace(t, "ñ", "n")
    t = Replace(t, "à", "a") : t = Replace(t, "è", "e") : t = Replace(t, "ì", "i")
    t = Replace(t, "ò", "o") : t = Replace(t, "ù", "u") : t = Replace(t, "ü", "u")
    out = ""
    For i = 1 To Len(t)
        c = Mid(t, i, 1)
        If (c >= "a" And c <= "z") Or (c >= "0" And c <= "9") Then
            out = out & c
        ElseIf c = " " Or c = "_" Or c = "-" Then
            If Right(out, 1) <> "-" Then out = out & "-"
        End If
    Next
    Do While Left(out, 1) = "-"
        out = Mid(out, 2)
    Loop
    Do While Right(out, 1) = "-"
        out = Left(out, Len(out) - 1)
    Loop
    SanitizeSlug = out
End Function

' ---------------------------------------------------------------------------
'  Clase de lectura de formularios multipart
' ---------------------------------------------------------------------------
Class PoliUpload
    Public Fields
    Public Files
    Public ErrorMessage
    Private mData
    Private mBoundary
    Private mParsed

    Private Sub Class_Initialize()
        Set Fields = Server.CreateObject("Scripting.Dictionary")
        Set Files  = Server.CreateObject("Scripting.Dictionary")
        Fields.CompareMode = 1
        Files.CompareMode  = 1
        ErrorMessage = ""
        mParsed = False
    End Sub

    Private Sub Class_Terminate()
        Set Fields = Nothing
        Set Files  = Nothing
    End Sub

    Public Function Parse()
        Dim total, i, ct, bp, delim, pos, nxt, startPos, part, sep, headers, body
        Dim re, mName, mFile, mCt, fname, fvalue

        Parse = False
        If mParsed Then
            Parse = True
            Exit Function
        End If

        On Error Resume Next
        total = Request.TotalBytes
        If Err.Number <> 0 Then
            ErrorMessage = "No se pudo leer el formulario."
            On Error GoTo 0
            Exit Function
        End If
        On Error GoTo 0

        If total <= 0 Then
            mParsed = True
            Parse = True
            Exit Function
        End If

        ct = Request.ServerVariables("CONTENT_TYPE") & ""
        If InStr(1, ct, "multipart/form-data", vbTextCompare) = 0 Then
            ErrorMessage = "El formulario no es multipart."
            Exit Function
        End If

        bp = InStr(1, ct, "boundary=", vbTextCompare)
        If bp = 0 Then
            ErrorMessage = "Falta el boundary del formulario."
            Exit Function
        End If
        mBoundary = Mid(ct, bp + 9)
        If InStr(mBoundary, ";") > 0 Then mBoundary = Left(mBoundary, InStr(mBoundary, ";") - 1)
        mBoundary = Replace(mBoundary, """", "")
        mBoundary = Trim(mBoundary)

        mData = B2S(Request.BinaryRead(total))
        delim = "--" & mBoundary

        pos = InStr(mData, delim)
        Do While pos > 0
            startPos = pos + Len(delim)
            If Mid(mData, startPos, 2) = "--" Then Exit Do
            If Mid(mData, startPos, 2) = vbCrLf Then startPos = startPos + 2

            nxt = InStr(startPos, mData, vbCrLf & delim)
            If nxt = 0 Then Exit Do

            part = Mid(mData, startPos, nxt - startPos)
            sep  = InStr(part, vbCrLf & vbCrLf)
            If sep > 0 Then
                headers = Left(part, sep - 1)
                body    = Mid(part, sep + 4)

                Set re = Server.CreateObject("VBScript.RegExp")
                re.IgnoreCase = True
                re.Global = False

                re.Pattern = "name=""([^""]*)"""
                mName = ""
                If re.Test(headers) Then mName = re.Execute(headers)(0).SubMatches(0)

                re.Pattern = "filename=""([^""]*)"""
                mFile = ""
                If re.Test(headers) Then mFile = re.Execute(headers)(0).SubMatches(0)

                re.Pattern = "Content-Type:\s*([^\r\n]+)"
                mCt = "application/octet-stream"
                If re.Test(headers) Then mCt = Trim(re.Execute(headers)(0).SubMatches(0))

                Set re = Nothing

                If Len(mName) > 0 Then
                    If Len(mFile) > 0 Then
                        If Not Files.Exists(mName) Then
                            Files.Add mName, Array(mFile, mCt, body)
                        End If
                    Else
                        fvalue = Utf8Decode(body)
                        ' quita CRLF final que agrega el navegador
                        Do While Right(fvalue, 2) = vbCrLf
                            fvalue = Left(fvalue, Len(fvalue) - 2)
                        Loop
                        If Fields.Exists(mName) Then
                            Fields(mName) = Fields(mName) & "," & fvalue
                        Else
                            Fields.Add mName, fvalue
                        End If
                    End If
                End If
            End If

            pos = nxt + 2
        Loop

        mParsed = True
        Parse = True
    End Function

    Public Function FieldValue(name)
        If Fields.Exists(name) Then
            FieldValue = Fields(name)
        Else
            FieldValue = ""
        End If
    End Function
End Class

' ---------------------------------------------------------------------------
'  Acceso unificado a campos POST (soporta urlencoded y multipart)
' ---------------------------------------------------------------------------
Dim gUpl, gMultipart, gPostReady

Sub InitPost()
    If gPostReady Then Exit Sub
    gPostReady = True
    gMultipart = (InStr(1, Request.ServerVariables("CONTENT_TYPE") & "", "multipart/form-data", vbTextCompare) > 0)
    If gMultipart Then
        Set gUpl = New PoliUpload
        gUpl.Parse
    End If
End Sub

Function PostVal(name)
    If gMultipart Then
        PostVal = Trim(gUpl.FieldValue(name))
    Else
        PostVal = FORM(name)
    End If
End Function

' ---------------------------------------------------------------------------
'  Guarda un archivo subido y devuelve la ruta "~/carpeta/archivo.ext"
' ---------------------------------------------------------------------------
Function SaveUploaded(upl, fieldName, folder, allowedExts, maxBytes, ByRef errMsg)
    Dim info, fname, ext, base, newName, phys, folderPhys, fso

    errMsg = ""
    SaveUploaded = ""

    If Not upl.Files.Exists(fieldName) Then Exit Function

    info  = upl.Files(fieldName)
    fname = Trim(info(0) & "")
    If Len(fname) = 0 Then Exit Function

    fname = Replace(fname, "\", "/")
    If InStr(fname, "/") > 0 Then fname = Mid(fname, InStrRev(fname, "/") + 1)

    ext = ""
    If InStrRev(fname, ".") > 0 Then ext = LCase(Mid(fname, InStrRev(fname, ".") + 1))
    If Len(ext) = 0 Then
        errMsg = "El archivo no tiene una extensión válida."
        Exit Function
    End If
    If InStr("," & LCase(allowedExts) & ",", "," & ext & ",") = 0 Then
        errMsg = "Formato ." & ext & " no permitido. Use: " & allowedExts & "."
        Exit Function
    End If
    If Len(info(2)) > maxBytes Then
        errMsg = "El archivo supera el tamaño máximo (" & Int(maxBytes / 1048576) & " MB)."
        Exit Function
    End If

    base = fname
    If InStrRev(base, ".") > 1 Then base = Left(base, InStrRev(base, ".") - 1)
    base = SanitizeSlug(base)
    If Len(base) > 40 Then base = Left(base, 40)
    If Len(base) = 0 Then base = "archivo"

    Randomize
    newName = base & "-" & CStr(Int(Timer * 1000)) & CStr(Int(Rnd() * 900) + 100) & "." & ext

    folderPhys = PhysRoot() & "\" & Replace(folder, "/", "\")
    Set fso = Server.CreateObject("Scripting.FileSystemObject")
    On Error Resume Next
    If Not fso.FolderExists(folderPhys) Then fso.CreateFolder folderPhys
    On Error GoTo 0
    Set fso = Nothing

    phys = folderPhys & "\" & newName

    If SaveBinaryToFile(info(2), phys) Then
        SaveUploaded = "~/" & folder & "/" & newName
    Else
        errMsg = "No se pudo guardar el archivo en el servidor."
    End If
End Function
%>
