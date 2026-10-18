"""Prueba unitaria rapida de NombreVisible() extrayendo la funcion de util.asp.

Compara dentro de VBScript para no depender de la codificacion de la consola.
"""
import io, os, re, subprocess, tempfile

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
src = io.open(os.path.join(ROOT, 'inc', 'util.asp'), encoding='utf-8').read()
m = re.search(r"Function NombreVisible.*?End Function", src, re.S)

code = m.group(0) + """
If NombreVisible("Claudio Penaherrera") = "Claudio Pe\u00f1aherrera" Then
    WScript.Echo "1 OK"
Else
    WScript.Echo "1 FAIL"
End If
If NombreVisible("claudio penaherrera") = "Claudio Pe\u00f1aherrera" Then
    WScript.Echo "2 OK (case-insensitive)"
Else
    WScript.Echo "2 FAIL"
End If
If NombreVisible("userAdmin") = "userAdmin" Then
    WScript.Echo "3 OK (sin cambios)"
Else
    WScript.Echo "3 FAIL"
End If
If NombreVisible("") = "" Then
    WScript.Echo "4 OK (vacio)"
Else
    WScript.Echo "4 FAIL"
End If
"""
path = os.path.join(tempfile.gettempdir(), 'pm_nombre.vbs')
io.open(path, 'w', encoding='utf-16-le').write('\ufeff' + code)
r = subprocess.run(['cscript', '//nologo', path], capture_output=True,
                   encoding='cp1252', errors='replace')
print((r.stdout or r.stderr or '').strip())
