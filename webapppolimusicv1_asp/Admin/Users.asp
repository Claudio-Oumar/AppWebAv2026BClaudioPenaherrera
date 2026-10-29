<%@ Language="VBScript" CodePage="65001" %>
<!--#include file="../inc/config.asp"-->
<%
RequireAdmin
InitPost

Dim PageTitle, PageId
PageTitle = "Usuarios"
PageId = "admin-users"

Dim action, editId, errMsg
action = LCase(QS("action"))
If Len(action) = 0 Then action = LCase(PostVal("action"))
editId = N(QS("id"))
If editId = 0 Then editId = N(PostVal("user_id"))
errMsg = ""

' --------------------------------------------------------------------------
'  Acciones
' --------------------------------------------------------------------------
If IsPost() Then
    RequireCsrfToken PostVal("_csrf")

    Select Case action
        Case "delete"
            If editId = CurrentUserId() Then
                SetError "No puedes eliminar tu propia cuenta."
                Go U("Admin/Users.asp")
            End If
            DbExec "DELETE FROM TBL_PLAYLIST_SONG WHERE ID_PLAYLIST IN (SELECT ID_PLAYLIST FROM TBL_PLAYLIST WHERE ID_USER = @p0)", Array(editId)
            DbExec "DELETE FROM TBL_PLAYLIST WHERE ID_USER = @p0", Array(editId)
            DbExec "DELETE FROM TBL_USER WHERE ID_USER = @p0", Array(editId)
            SetOk "Usuario eliminado junto con sus playlists."
            Go U("Admin/Users.asp")

        Case "create", "update"
            Dim nUser, nEmail, nPass, nBirth, nType, nPhoto, upErr
            nUser  = PostVal("username")
            nEmail = PostVal("email")
            nPass  = PostVal("password")
            nBirth = PostVal("birthday")
            nType  = N(PostVal("user_type"))
            nPhoto = PostVal("current_photo")
            upErr  = ""

            If Len(nUser) < 3 Or Len(nUser) > 50 Then
                errMsg = "El usuario debe tener entre 3 y 50 caracteres."
            ElseIf InStr(nUser, " ") > 0 Then
                errMsg = "El nombre de usuario no puede contener espacios."
            ElseIf Len(nEmail) = 0 Or InStr(nEmail, "@") = 0 Then
                errMsg = "Ingresa un correo electrónico válido."
            ElseIf Len(nBirth) > 0 And Not IsDate(nBirth) Then
                errMsg = "La fecha de nacimiento no es válida."
            ElseIf N(DbScalar("SELECT COUNT(*) FROM TBL_USER WHERE USERNAME = @p0 AND ID_USER <> @p1", Array(nUser, editId))) > 0 Then
                errMsg = "Ese nombre de usuario ya está en uso."
            ElseIf N(DbScalar("SELECT COUNT(*) FROM TBL_USER WHERE EMAIL = @p0 AND ID_USER <> @p1", Array(nEmail, editId))) > 0 Then
                errMsg = "Ese correo ya está registrado."
            ElseIf action = "create" And Len(nPass) < 6 Then
                errMsg = "La contraseña debe tener al menos 6 caracteres."
            ElseIf action = "update" And Len(nPass) > 0 And Len(nPass) < 6 Then
                errMsg = "La nueva contraseña debe tener al menos 6 caracteres."
            ElseIf action = "update" And editId = CurrentUserId() And nType <> ROLE_ADMIN Then
                errMsg = "No puedes quitarte a ti mismo el rol de administrador."
            End If

            If Len(errMsg) = 0 And gMultipart Then
                Dim sp
                sp = SaveUploaded(gUpl, "photo", "userImages", "jpg,jpeg,png,gif,webp", MAX_IMAGE_BYTES, upErr)
                If Len(upErr) > 0 Then
                    errMsg = upErr
                ElseIf Len(sp) > 0 Then
                    nPhoto = sp
                End If
            End If
            If Len(nPhoto) = 0 Then nPhoto = "~/userImages/default.jpg"

            If Len(errMsg) = 0 Then
                If action = "create" Then
                    DbExec "INSERT INTO TBL_USER (USERNAME, PASSWORD, EMAIL, BIRTHDAY, USER_PHOTO, USER_TYPE) " & _
                           "VALUES (@p0, CONVERT(varchar(40), HASHBYTES('SHA1', CONVERT(varchar(50), @p1)), 2), " & _
                           "@p2, CONVERT(datetime, NULLIF(@p3, ''), 120), @p4, @p5)", _
                           Array(nUser, nPass, nEmail, nBirth, nPhoto, nType)
                    SetOk "Usuario «" & nUser & "» creado."
                Else
                    If Len(nPass) > 0 Then
                        DbExec "UPDATE TBL_USER SET USERNAME = @p1, EMAIL = @p2, " & _
                               "BIRTHDAY = CONVERT(datetime, NULLIF(@p3, ''), 120), USER_PHOTO = @p4, USER_TYPE = @p5, " & _
                               "PASSWORD = CONVERT(varchar(40), HASHBYTES('SHA1', CONVERT(varchar(50), @p6)), 2) " & _
                               "WHERE ID_USER = @p0", _
                               Array(editId, nUser, nEmail, nBirth, nPhoto, nType, nPass)
                    Else
                        DbExec "UPDATE TBL_USER SET USERNAME = @p1, EMAIL = @p2, " & _
                               "BIRTHDAY = CONVERT(datetime, NULLIF(@p3, ''), 120), USER_PHOTO = @p4, USER_TYPE = @p5 " & _
                               "WHERE ID_USER = @p0", _
                               Array(editId, nUser, nEmail, nBirth, nPhoto, nType)
                    End If
                    SetOk "Usuario actualizado."
                End If
                Go U("Admin/Users.asp")
            End If

            If action = "create" Then action = "new" Else action = "edit"
    End Select
End If

If Len(errMsg) > 0 Then SetError errMsg

' --------------------------------------------------------------------------
'  Datos para el formulario
' --------------------------------------------------------------------------
Dim fUser, fEmail, fBirth, fPhoto, fType, fHasPass
fUser = ""
fEmail = ""
fBirth = ""
fPhoto = "~/userImages/default.jpg"
fType = 0
fHasPass = False

If (action = "edit") And editId > 0 Then
    Dim rsE
    Set rsE = DbSelect("SELECT USERNAME, EMAIL, BIRTHDAY, USER_PHOTO, USER_TYPE FROM TBL_USER WHERE ID_USER = @p0", Array(editId))
    If Not rsE.EOF Then
        fUser  = rsE("USERNAME") & ""
        fEmail = rsE("EMAIL") & ""
        fBirth = FechaInput(rsE("BIRTHDAY"))
        fPhoto = rsE("USER_PHOTO") & ""
        fType  = N(rsE("USER_TYPE"))
        fHasPass = True
    Else
        action = ""
        SetError "El usuario no existe."
    End If
    rsE.Close
    Set rsE = Nothing
End If

If Len(fPhoto) = 0 Then fPhoto = "~/userImages/default.jpg"
%>
<!--#include file="../inc/header.asp"-->

<div class="section" style="margin-top:6px">
  <div class="section-head">
    <div>
      <h2>Usuarios</h2>
      <p>Administra las cuentas y los roles del sistema.</p>
    </div>
    <a class="btn btn-primary btn-sm" href="<%=U("Admin/Users.asp")%>?action=new">
      <svg class="ico ico-sm"><use href="#i-plus"/></svg> Nuevo usuario
    </a>
  </div>
</div>

<div class="stats">
  <div class="stat accent"><span>Total usuarios</span><strong><%=N(DbScalar("SELECT COUNT(*) FROM TBL_USER", Array()))%></strong></div>
  <div class="stat"><span>Administradores</span><strong><%=N(DbScalar("SELECT COUNT(*) FROM TBL_USER WHERE USER_TYPE = 1", Array()))%></strong></div>
  <div class="stat"><span>Usuarios normales</span><strong><%=N(DbScalar("SELECT COUNT(*) FROM TBL_USER WHERE USER_TYPE = 0", Array()))%></strong></div>
</div>

<% If action = "new" Or action = "edit" Then %>
<section class="section" style="margin-top:0">
  <div class="panel">
    <div class="panel-head">
      <div>
        <h2><%=IIfStr(action = "new", "Nuevo usuario", "Editar usuario")%></h2>
        <p><%=IIfStr(action = "new", "Crea una cuenta con rol de usuario o administrador.", "Modifica los datos de la cuenta.")%></p>
      </div>
      <a class="btn btn-ghost btn-sm" href="<%=U("Admin/Users.asp")%>">Cancelar</a>
    </div>

    <form method="post" action="<%=U("Admin/Users.asp")%>" enctype="multipart/form-data">
      <%=CsrfField()%>
      <input type="hidden" name="action" value="<%=IIfStr(action = "new", "create", "update")%>">
      <input type="hidden" name="user_id" value="<%=editId%>">
      <input type="hidden" name="current_photo" value="<%=A(fPhoto)%>">

      <div class="form-grid">
        <div class="field">
          <label for="username">Usuario</label>
          <input class="input" type="text" id="username" name="username" maxlength="50" required value="<%=A(fUser)%>">
        </div>

        <div class="field">
          <label for="email">Correo electrónico</label>
          <input class="input" type="email" id="email" name="email" maxlength="50" required value="<%=A(fEmail)%>">
        </div>

        <div class="field">
          <label for="password">Contraseña <%=IIfStr(action = "edit", "· dejar vacío para no cambiar", "")%></label>
          <input class="input" type="password" id="password" name="password"
                 placeholder="Mínimo 6 caracteres" <%=IIfStr(action = "new", "required minlength=""6""", "")%>>
        </div>

        <div class="field">
          <label for="birthday">Fecha de nacimiento</label>
          <input class="input" type="date" id="birthday" name="birthday" value="<%=A(fBirth)%>">
        </div>

        <div class="field">
          <label for="user_type">Rol</label>
          <select class="select" id="user_type" name="user_type">
            <option value="0" <%=IIfStr(fType = 0, "selected", "")%>>Usuario normal</option>
            <option value="1" <%=IIfStr(fType = 1, "selected", "")%>>Administrador</option>
          </select>
        </div>

        <div class="field">
          <label for="photo">Foto de perfil</label>
          <label class="file-drop" for="photo">
            <svg class="ico"><use href="#i-upload"/></svg>
            <span class="file-name" data-empty="Ningún archivo seleccionado">Ningún archivo seleccionado</span>
            <input type="file" id="photo" name="photo" accept="image/*">
          </label>
        </div>
      </div>

      <div class="form-actions">
        <button class="btn btn-primary" type="submit">
          <svg class="ico ico-sm"><use href="#i-save"/></svg> <%=IIfStr(action = "new", "Crear usuario", "Guardar cambios")%>
        </button>
      </div>
    </form>
  </div>
</section>
<% End If %>

<section class="section">
  <div class="table-wrap">
    <table class="data">
      <thead>
        <tr>
          <th>Usuario</th>
          <th>Correo</th>
          <th>Rol</th>
          <th>Nacimiento</th>
          <th class="num">Playlists</th>
          <th style="text-align:right">Acciones</th>
        </tr>
      </thead>
      <tbody>
        <%
        Dim rsL
        Set rsL = DbSelect("SELECT u.ID_USER, u.USERNAME, u.EMAIL, u.BIRTHDAY, u.USER_PHOTO, u.USER_TYPE, " & _
                           "(SELECT COUNT(*) FROM TBL_PLAYLIST p WHERE p.ID_USER = u.ID_USER) AS PLAYLISTS " & _
                           "FROM TBL_USER u ORDER BY u.USER_TYPE DESC, u.USERNAME", Array())
        Do While Not rsL.EOF
            %>
            <tr>
              <td>
                <div class="cell-main">
                  <img src="<%=A(MediaUrl(rsL("USER_PHOTO"), "userImages/default.jpg"))%>" alt="">
                  <div>
                    <strong><%=H(NombreVisible(rsL("USERNAME")))%></strong>
                    <small>#<%=rsL("ID_USER")%></small>
                  </div>
                </div>
              </td>
              <td><%=H(rsL("EMAIL"))%></td>
              <td>
                <span class="badge <%=IIfStr(N(rsL("USER_TYPE")) = 1, "badge-admin", "badge-user")%>">
                  <%=IIfStr(N(rsL("USER_TYPE")) = 1, "Admin", "Usuario")%>
                </span>
              </td>
              <td><%=FechaCorta(rsL("BIRTHDAY"))%></td>
              <td class="num"><%=N(rsL("PLAYLISTS"))%></td>
              <td>
                <div class="actions">
                  <a class="t-act" href="<%=U("Admin/Users.asp")%>?action=edit&amp;id=<%=rsL("ID_USER")%>" title="Editar">
                    <svg class="ico ico-sm"><use href="#i-edit"/></svg>
                  </a>
                  <% If CLng(rsL("ID_USER")) <> CurrentUserId() Then %>
                  <form method="post" action="<%=U("Admin/Users.asp")%>" class="inline"
                        data-confirm="¿Eliminar al usuario «<%=A(rsL("USERNAME") & "")%>» y todas sus playlists?">
                    <%=CsrfField()%>
                    <input type="hidden" name="action" value="delete">
                    <input type="hidden" name="user_id" value="<%=rsL("ID_USER")%>">
                    <button class="t-act danger" type="submit" title="Eliminar">
                      <svg class="ico ico-sm"><use href="#i-trash"/></svg>
                    </button>
                  </form>
                  <% End If %>
                </div>
              </td>
            </tr>
            <%
            rsL.MoveNext
        Loop
        rsL.Close
        Set rsL = Nothing
        %>
      </tbody>
    </table>
  </div>
</section>

<!--#include file="../inc/footer.asp"-->
