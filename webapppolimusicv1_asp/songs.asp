<%@ Language="VBScript" CodePage="65001" %>
<%
' ============================================================================
'  songs.asp - Listado de canciones (Song List) - PoliMusic
'  Archivo UNICO y autocontenido: conexion, sesion, roles, CRUD, tabla HTML,
'  estilos CSS y reproductor. No necesita includes.
'
'  Cumple la consigna:
'   [1] 2 roles (normal / admin) ........... bloque SESION
'   [2] CRUD solo para admin ............... bloque CRUD + columna Acciones
'   [3] diseno propio con html+css+js ...... <style> y <script>
'   [4] bienvenida con usuario de sesion ... tarjeta "Bienvenido"
'   [5] cierre de sesion (logout) .......... enlace songs.asp?logout=1
'   [6] texto que anuncia el Song List ..... cabecera de la tabla
'   [7] tabla HTML con estilos css ......... <table>
'   [8] reproduccion de canciones .......... <audio> + funcion playRow()
' ============================================================================
Response.Buffer  = True
Response.Charset = "utf-8"
Response.CodePage = 65001
Session.CodePage  = 65001

Const CS1 = "Provider=MSOLEDBSQL;Server=localhost,1433;Database=BDD_PoliMusic;UID=usr_polimusic;PWD=Politecnica1;Encrypt=Optional;TrustServerCertificate=Yes;"
Const CS2 = "Provider=SQLOLEDB;Server=localhost,1433;Database=BDD_PoliMusic;UID=usr_polimusic;PWD=Politecnica1;"

Dim cn
Sub AbrirBD()
    On Error Resume Next
    Set cn = Server.CreateObject("ADODB.Connection")
    cn.CursorLocation = 3
    cn.Open CS1
    If Err.Number <> 0 Then
        Err.Clear
        Set cn = Server.CreateObject("ADODB.Connection")
        cn.CursorLocation = 3
        cn.Open CS2
    End If
    If Err.Number <> 0 Then
        Response.Write "<p style=""font-family:sans-serif;color:#f0546a;padding:40px"">" & _
                       "No se pudo conectar a SQL Server (BDD_PoliMusic).</p>"
        Response.End
    End If
    On Error GoTo 0
End Sub

' --- Consulta parametrizada (evita inyeccion SQL) ---------------------------
Function DbQ(sql, p)
    Dim c, i, v
    Set c = Server.CreateObject("ADODB.Command")
    Set c.ActiveConnection = cn
    c.CommandText = sql
    If IsArray(p) Then
        For i = 0 To UBound(p)
            v = p(i)
            If VarType(v) = 1 Then
                c.Parameters.Append c.CreateParameter("p" & i, 200, 1, 4000, Null)
            ElseIf VarType(v) = 2 Or VarType(v) = 3 Then
                c.Parameters.Append c.CreateParameter("p" & i, 3, 1, , CLng(v))
            Else
                c.Parameters.Append c.CreateParameter("p" & i, 200, 1, 4000, CStr(v))
            End If
        Next
    End If
    Set DbQ = c.Execute
End Function

Sub DbX(sql, p)
    Dim rs
    Set rs = DbQ(sql, p)
    If Not (rs Is Nothing) Then
        If rs.State <> 0 Then rs.Close
    End If
End Sub

Function N(v)
    If IsNull(v) Or Not IsNumeric(v) Then N = 0 Else N = CLng(v)
End Function
Function H(s)
    H = Server.HTMLEncode(s & "")
End Function
Function IIf(cond, a, b)
    If cond Then IIf = a Else IIf = b
End Function
Function URLMedia(ruta)
    Dim p
    p = Trim(ruta & "")
    If Left(p, 2) = "~/" Then p = Mid(p, 3)
    URLMedia = p
End Function

' ============================================================================
'  SESION: el nombre y el rol vienen de login.asp
'  (se aceptan varios nombres de variable para adaptarse a tu login.asp)
' ============================================================================
Dim USUARIO, ES_ADMIN, k
USUARIO = ""
For Each k In Array("usuario", "pm_uname", "username", "nombre", "user", "login")
    If Len(USUARIO) = 0 Then
        If Len(Session(k) & "") > 0 Then USUARIO = Session(k) & ""
    End If
Next

Dim rol
rol = Session("tipo")
If Len(rol & "") = 0 Then rol = Session("pm_utype")
If Len(rol & "") = 0 Then rol = Session("rol")
If Len(rol & "") = 0 Then rol = Session("user_type")
If Len(rol & "") = 0 Then rol = Session("admin")
ES_ADMIN = (CStr(rol) = "1" Or LCase(CStr(rol)) = "true" Or LCase(CStr(rol)) = "admin")

' --- Logout ----------------------------------------------------------------
If Request.QueryString("logout") = "1" Then
    Session.Contents.RemoveAll
    Session.Abandon
    Response.Redirect "login.asp"
End If

' --- Sin sesion -> al login -------------------------------------------------
If Len(USUARIO) = 0 Then
    Response.Redirect "login.asp"
End If

AbrirBD()

' ============================================================================
'  CRUD (solo administrador)
' ============================================================================
Dim accion, editId, formNombre, formRuta, formPlays
accion = LCase(Request.QueryString("action"))
editId = N(Request.QueryString("id"))
formNombre = ""
formRuta = ""
formPlays = 0

If Request.ServerVariables("REQUEST_METHOD") = "POST" Then
    If ES_ADMIN Then
        Dim pAcc, pId
        pAcc = LCase(Request.Form("acc"))
        pId  = N(Request.Form("id"))

        If pAcc = "del" Then
            DbX "DELETE FROM TBL_PLAYLIST_SONG WHERE ID_SONG = @p0", Array(pId)
            DbX "DELETE FROM TBL_TRACKLIST WHERE ID_SONG = @p0", Array(pId)
            DbX "DELETE FROM TBL_PLAYER WHERE ID_SONG = @p0", Array(pId)
            DbX "DELETE FROM TBL_SONG WHERE ID_SONG = @p0", Array(pId)
        ElseIf pAcc = "save" Then
            Dim pNom, pRut, pPla
            pNom = Trim(Request.Form("song_name") & "")
            pRut = Trim(Request.Form("song_path") & "")
            pPla = N(Request.Form("plays"))
            If Len(pNom) > 0 And Len(pRut) > 0 Then
                If pId > 0 Then
                    DbX "UPDATE TBL_SONG SET SONG_NAME = @p1, SONG_PATH = @p2, PLAYS = @p3 WHERE ID_SONG = @p0", _
                        Array(pId, pNom, pRut, pPla)
                Else
                    DbX "INSERT INTO TBL_SONG (SONG_NAME, SONG_PATH, PLAYS) VALUES (@p0, @p1, @p2)", _
                        Array(pNom, pRut, pPla)
                End If
            End If
        End If
    End If
    Response.Redirect "songs.asp"
End If

' --- Si se esta editando, se cargan los datos en el formulario --------------
If ES_ADMIN And accion = "edit" And editId > 0 Then
    Dim rsE
    Set rsE = DbQ("SELECT SONG_NAME, SONG_PATH, ISNULL(PLAYS,0) AS PLAYS FROM TBL_SONG WHERE ID_SONG = @p0", Array(editId))
    If Not rsE.EOF Then
        formNombre = rsE("SONG_NAME") & ""
        formRuta   = rsE("SONG_PATH") & ""
        formPlays  = N(rsE("PLAYS"))
    End If
    rsE.Close
End If
%>
<!DOCTYPE html>
<html lang="es">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>Song List · PoliMusic</title>
<style>
  :root{
    --bg:#0b0712; --panel:#150e22; --panel2:#1d1330; --line:rgba(255,255,255,.09);
    --txt:#f3edff; --muted:#a99bc2; --accent:#a855f7; --accent2:#7c3aed; --accent3:#c084fc;
  }
  *{box-sizing:border-box}
  body{margin:0;background:radial-gradient(1200px 600px at 15% -10%,#2a1145 0%,var(--bg) 55%);
       color:var(--txt);font-family:"Segoe UI",Inter,Roboto,Arial,sans-serif;font-size:14px;
       min-height:100vh;padding:28px 18px 120px}
  .wrap{max-width:1080px;margin:0 auto}
  .top{display:flex;align-items:center;gap:14px;flex-wrap:wrap;margin-bottom:22px}
  .logo{width:44px;height:44px;border-radius:14px;display:grid;place-items:center;font-size:22px;
        background:linear-gradient(140deg,var(--accent3),var(--accent2));box-shadow:0 10px 24px rgba(124,58,237,.45)}
  .brand{font-size:20px;font-weight:800;letter-spacing:-.4px}
  .brand small{display:block;font-size:11px;font-weight:600;color:var(--muted);letter-spacing:.14em;text-transform:uppercase}
  .spacer{flex:1}
  .user{display:flex;align-items:center;gap:10px;background:var(--panel);border:1px solid var(--line);
        padding:8px 14px;border-radius:999px}
  .dot{width:9px;height:9px;border-radius:50%;background:#46d6a0}
  .badge{font-size:10px;font-weight:800;letter-spacing:.08em;text-transform:uppercase;padding:4px 9px;
         border-radius:999px;background:rgba(168,85,247,.18);color:var(--accent3)}
  .badge.u{background:rgba(70,214,160,.15);color:#46d6a0}
  .btn{border:0;cursor:pointer;font:inherit;font-weight:700;border-radius:999px;padding:9px 16px;
       background:rgba(255,255,255,.08);color:var(--txt);text-decoration:none;display:inline-flex;
       align-items:center;gap:7px;transition:.15s}
  .btn:hover{background:rgba(255,255,255,.15)}
  .btn.p{background:linear-gradient(135deg,var(--accent),var(--accent2));box-shadow:0 10px 24px rgba(124,58,237,.4)}
  .btn.p:hover{filter:brightness(1.1)}
  .btn.d{background:rgba(240,84,106,.15);color:#ff9aab}
  .btn.s{padding:6px 12px;font-size:12.5px}
  .card{background:var(--panel);border:1px solid var(--line);border-radius:18px;padding:22px 24px;margin-bottom:20px}
  h1{margin:0 0 6px;font-size:clamp(24px,3.4vw,34px);letter-spacing:-1px}
  h1 span{background:linear-gradient(90deg,#fff,var(--accent3));-webkit-background-clip:text;
          background-clip:text;color:transparent}
  h2{margin:0;font-size:19px;letter-spacing:-.3px}
  p.sub{margin:6px 0 0;color:var(--muted);font-size:13.5px}
  .rowhead{display:flex;align-items:flex-end;justify-content:space-between;gap:14px;flex-wrap:wrap;margin-bottom:14px}
  table{width:100%;border-collapse:collapse;font-size:13.5px}
  thead th{text-align:left;padding:11px 12px;font-size:10.5px;letter-spacing:.1em;text-transform:uppercase;
           color:var(--muted);background:rgba(255,255,255,.04);border-bottom:1px solid var(--line)}
  tbody td{padding:10px 12px;border-bottom:1px solid var(--line);color:var(--muted);vertical-align:middle}
  tbody tr:last-child td{border-bottom:0}
  tbody tr:hover{background:rgba(255,255,255,.035)}
  tbody tr.on{background:rgba(168,85,247,.16)}
  tbody tr.on .nm{color:var(--accent3)}
  .nm{color:var(--txt);font-weight:600}
  .cell{display:flex;align-items:center;gap:10px}
  .cell img{width:38px;height:38px;border-radius:8px;object-fit:cover;background:var(--panel2)}
  .cell small{display:block;color:var(--muted);font-size:11px}
  .num{text-align:right;font-variant-numeric:tabular-nums}
  .play{width:34px;height:34px;border-radius:50%;border:0;cursor:pointer;display:grid;place-items:center;
        background:linear-gradient(135deg,var(--accent3),var(--accent2));color:#fff;font-size:12px;
        box-shadow:0 6px 16px rgba(124,58,237,.45);transition:.15s}
  .play:hover{transform:scale(1.09)}
  .acc{display:flex;gap:6px;justify-content:flex-end}
  .acc a,.acc button{width:30px;height:30px;border-radius:8px;border:0;cursor:pointer;display:grid;
        place-items:center;background:transparent;color:var(--muted);text-decoration:none;font-size:14px}
  .acc a:hover{background:rgba(255,255,255,.1);color:#fff}
  .acc button:hover{background:rgba(240,84,106,.18);color:#ff9aab}
  .frm{display:grid;grid-template-columns:2fr 2fr 100px auto;gap:12px;align-items:end}
  .fld{display:flex;flex-direction:column;gap:6px}
  .fld label{font-size:11px;font-weight:700;letter-spacing:.05em;text-transform:uppercase;color:var(--muted)}
  .fld input{padding:10px 12px;border-radius:10px;border:1px solid var(--line);background:#0e0917;
             color:var(--txt);font:inherit;outline:none}
  .fld input:focus{border-color:rgba(168,85,247,.6);box-shadow:0 0 0 3px rgba(168,85,247,.12)}
  .bar{position:fixed;left:0;right:0;bottom:0;display:flex;align-items:center;gap:14px;padding:12px 22px;
       background:rgba(13,8,21,.94);border-top:1px solid var(--line);backdrop-filter:blur(18px)}
  .bar .t{font-weight:700;font-size:13px}
  .bar .a{color:var(--muted);font-size:12px}
  .bar audio{height:36px;margin-left:auto;width:min(420px,52vw)}
  .empty{text-align:center;padding:34px;color:var(--muted)}
  @media(max-width:760px){
    .frm{grid-template-columns:1fr}
    .hide{display:none}
    .bar audio{width:52vw}
  }
</style>
</head>
<body>
<div class="wrap">

  <%' ------------------------------------------------ Bienvenida + logout %>
  <div class="top">
    <div class="logo">&#9835;</div>
    <div class="brand">PoliMusic<small>Song list</small></div>
    <div class="spacer"></div>
    <div class="user">
      <span class="dot"></span>
      <span><strong><%=H(USUARIO)%></strong></span>
      <span class="badge <%=IIf(ES_ADMIN, "", "u")%>"><%=IIf(ES_ADMIN, "Administrador", "Usuario")%></span>
    </div>
    <a class="btn" href="songs.asp?logout=1">Cerrar sesión</a>
  </div>

  <div class="card">
    <h1>Bienvenido, <span><%=H(USUARIO)%></span></h1>
    <p class="sub">
      Has iniciado sesión con el rol de <strong><%=IIf(ES_ADMIN, "Administrador", "Usuario normal")%></strong>.
      <% If ES_ADMIN Then %>
        Puedes crear, editar y eliminar canciones.
      <% Else %>
        Puedes escuchar todas las canciones del catálogo.
      <% End If %>
    </p>
  </div>

  <%' ------------------------------------------------------ Formulario CRUD %>
  <% If ES_ADMIN Then %>
  <div class="card">
    <div class="rowhead">
      <div>
        <h2><%=IIf(editId > 0 And accion = "edit", "Editar canción", "Nueva canción")%></h2>
        <p class="sub">Solo el administrador puede modificar el catálogo.</p>
      </div>
      <% If editId > 0 And accion = "edit" Then %>
        <a class="btn s" href="songs.asp">Cancelar edición</a>
      <% End If %>
    </div>

    <form method="post" action="songs.asp" class="frm">
      <input type="hidden" name="acc" value="save">
      <input type="hidden" name="id" value="<%=IIf(editId > 0 And accion = "edit", editId, 0)%>">
      <div class="fld">
        <label>Nombre</label>
        <input type="text" name="song_name" maxlength="50" required value="<%=H(formNombre)%>" placeholder="Ej. Adventure">
      </div>
      <div class="fld">
        <label>Ruta del archivo</label>
        <input type="text" name="song_path" maxlength="255" required value="<%=H(formRuta)%>" placeholder="~/songFiles/bensound-adventure.mp3">
      </div>
      <div class="fld">
        <label>Reproducciones</label>
        <input type="number" name="plays" min="0" value="<%=formPlays%>">
      </div>
      <button class="btn p" type="submit"><%=IIf(editId > 0 And accion = "edit", "Guardar", "Crear")%></button>
    </form>
  </div>
  <% End If %>

  <%' --------------------------------------------------------------- Tabla %>
  <div class="card">
    <div class="rowhead">
      <div>
        <h2>Song List</h2>
        <p class="sub">A continuación se presenta el listado de canciones disponibles en el catálogo.</p>
      </div>
      <button class="btn p s" type="button" onclick="playAll()">▶ Reproducir todo</button>
    </div>

    <table>
      <thead>
        <tr>
          <th style="width:46px">#</th>
          <th>Song Name</th>
          <th class="hide">Artista</th>
          <th class="hide">Álbum</th>
          <th class="num" style="width:120px">Reproducciones</th>
          <th style="width:70px;text-align:center">Play</th>
          <% If ES_ADMIN Then %><th style="width:90px;text-align:right">Acciones</th><% End If %>
        </tr>
      </thead>
      <tbody>
        <%
        Dim rs, i, sid, nm, ruta, cover, art, alb, plays
        i = 0
        Set rs = DbQ("SELECT s.ID_SONG, s.SONG_NAME, s.SONG_PATH, ISNULL(s.PLAYS,0) AS PLAYS, " & _
                     "(SELECT TOP 1 a.TITLE_ALBUM FROM TBL_TRACKLIST t INNER JOIN TBL_ALBUM a ON a.ID_ALBUM=t.ID_ALBUM WHERE t.ID_SONG=s.ID_SONG) AS ALBUM, " & _
                     "(SELECT TOP 1 a.ALBUM_IMAGE_PATH FROM TBL_TRACKLIST t INNER JOIN TBL_ALBUM a ON a.ID_ALBUM=t.ID_ALBUM WHERE t.ID_SONG=s.ID_SONG) AS COVER, " & _
                     "(SELECT TOP 1 ar.ARTIST_NAME FROM TBL_PLAYER p INNER JOIN TBL_ARTIST ar ON ar.ID_ARTIST=p.ID_ARTIST WHERE p.ID_SONG=s.ID_SONG) AS ARTIST " & _
                     "FROM TBL_SONG s ORDER BY s.SONG_NAME", Array())

        If rs.EOF Then
            Response.Write "<tr><td colspan=""" & IIf(ES_ADMIN, 7, 6) & """ class=""empty"">No hay canciones registradas.</td></tr>"
        End If

        Do While Not rs.EOF
            i = i + 1
            sid   = CLng(rs("ID_SONG"))
            nm    = rs("SONG_NAME") & ""
            ruta  = URLMedia(rs("SONG_PATH"))
            cover = URLMedia(rs("COVER"))
            If Len(cover) = 0 Then cover = "albumImages/default.png"
            art   = rs("ARTIST") & ""
            alb   = rs("ALBUM") & ""
            plays = N(rs("PLAYS"))
            %>
            <tr class="songrow" data-url="<%=H(ruta)%>" data-name="<%=H(nm)%>" data-artist="<%=H(art)%>">
              <td class="num"><%=i%></td>
              <td>
                <div class="cell">
                  <img src="<%=H(cover)%>" alt="" onerror="this.style.visibility='hidden'">
                  <div><span class="nm"><%=H(nm)%></span><small>ID #<%=sid%></small></div>
                </div>
              </td>
              <td class="hide"><%=H(art)%></td>
              <td class="hide"><%=H(alb)%></td>
              <td class="num"><%=plays%></td>
              <td style="text-align:center">
                <button class="play" type="button" title="Reproducir" onclick="playRow(this)">&#9654;</button>
              </td>
              <% If ES_ADMIN Then %>
              <td>
                <div class="acc">
                  <a href="songs.asp?action=edit&amp;id=<%=sid%>" title="Editar">&#9998;</a>
                  <form method="post" action="songs.asp" style="display:inline"
                        onsubmit="return confirm('¿Eliminar la canción?');">
                    <input type="hidden" name="acc" value="del">
                    <input type="hidden" name="id" value="<%=sid%>">
                    <button type="submit" title="Eliminar">&#128465;</button>
                  </form>
                </div>
              </td>
              <% End If %>
            </tr>
            <%
            rs.MoveNext
        Loop
        rs.Close
        %>
      </tbody>
    </table>
  </div>
</div>

<div class="bar">
  <div>
    <div class="t" id="nowT">Sin reproducción</div>
    <div class="a" id="nowA">Elige una canción</div>
  </div>
  <audio id="au" controls preload="none"></audio>
</div>

<script>
  var au = document.getElementById('au');

  function playRow(btn) {
    var tr = btn.closest('tr');
    var url = tr.getAttribute('data-url');
    if (!url) return;
    au.src = url;
    au.play();
    document.getElementById('nowT').textContent = tr.getAttribute('data-name');
    document.getElementById('nowA').textContent = tr.getAttribute('data-artist');
    var rows = document.querySelectorAll('tr.songrow');
    for (var i = 0; i < rows.length; i++) rows[i].classList.remove('on');
    tr.classList.add('on');
  }

  function playAll() {
    var first = document.querySelector('tr.songrow');
    if (first) playRow(first.querySelector('.play'));
  }
</script>
</body>
</html>
<%
cn.Close
Set cn = Nothing
%>
