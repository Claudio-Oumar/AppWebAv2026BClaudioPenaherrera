<%@ Language="VBScript" CodePage="65001" %>
<!--#include file="inc/config.asp"-->
<%
RequireLogin
InitPost

Dim PageTitle, PageId
PageTitle = "Mi perfil"
PageId = "profile"

Dim errMsg, okMsg
errMsg = ""

' Datos actuales
Dim rsU, uName, uEmail, uBirth, uPhoto, uType
Set rsU = DbSelect("SELECT USERNAME, EMAIL, BIRTHDAY, USER_PHOTO, USER_TYPE FROM TBL_USER WHERE ID_USER = @p0", Array(CurrentUserId()))
uName  = rsU("USERNAME") & ""
uEmail = rsU("EMAIL") & ""
uBirth = rsU("BIRTHDAY")
uPhoto = MediaUrl(rsU("USER_PHOTO"), "userImages/default.jpg")
uType  = N(rsU("USER_TYPE"))
rsU.Close
Set rsU = Nothing

' --------------------------------------------------------------------------
'  Actualizar datos
' --------------------------------------------------------------------------
If IsPost() Then
    RequireCsrfToken PostVal("_csrf")

    Dim fAction
    fAction = LCase(PostVal("form"))

    If fAction = "profile" Then
        Dim nName, nEmail, nBirth, nPhoto, upErr, dup
        nName  = PostVal("username")
        nEmail = PostVal("email")
        nBirth = PostVal("birthday")
        nPhoto = uPhoto
        upErr = ""

        dup = 0

        If Len(nName) < 3 Or Len(nName) > 50 Then
            errMsg = "El usuario debe tener entre 3 y 50 caracteres."
        ElseIf InStr(nName, " ") > 0 Then
            errMsg = "El nombre de usuario no puede contener espacios."
        ElseIf Len(nEmail) = 0 Or InStr(nEmail, "@") = 0 Then
            errMsg = "Ingresa un correo electrónico válido."
        ElseIf Len(nBirth) > 0 And Not IsDate(nBirth) Then
            errMsg = "La fecha de nacimiento no es válida."
        Else
            dup = N(DbScalar("SELECT COUNT(*) FROM TBL_USER WHERE USERNAME = @p0 AND ID_USER <> @p1", Array(nName, CurrentUserId())))
            If dup > 0 Then
                errMsg = "Ese nombre de usuario ya está en uso."
            Else
                dup = N(DbScalar("SELECT COUNT(*) FROM TBL_USER WHERE EMAIL = @p0 AND ID_USER <> @p1", Array(nEmail, CurrentUserId())))
                If dup > 0 Then
                    errMsg = "Ese correo ya está registrado por otro usuario."
                End If
            End If
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

        If Len(errMsg) = 0 Then
            ' Guarda la ruta relativa ("~/...") y no la URL resuelta
            Dim rawPhoto
            rawPhoto = PostVal("current_photo")
            If InStr(nPhoto, "~/") = 1 Then
                rawPhoto = nPhoto
            End If
            If Len(rawPhoto) = 0 Then rawPhoto = "~/userImages/default.jpg"

            DbExec "UPDATE TBL_USER SET USERNAME = @p1, EMAIL = @p2, " & _
                   "BIRTHDAY = CONVERT(datetime, NULLIF(@p3, ''), 120), USER_PHOTO = @p4 WHERE ID_USER = @p0", _
                   Array(CurrentUserId(), nName, nEmail, nBirth, rawPhoto)

            Session("pm_uname")  = nName
            Session("pm_uemail") = nEmail
            Session("pm_uphoto") = rawPhoto
            SetOk "Perfil actualizado correctamente."
            Go U("Profile.asp")
        End If

    ElseIf fAction = "password" Then
        Dim pNew, pNew2
        pNew  = PostVal("new_password")
        pNew2 = PostVal("new_password2")

        If Len(pNew) < 6 Then
            errMsg = "La nueva contraseña debe tener al menos 6 caracteres."
        ElseIf pNew <> pNew2 Then
            errMsg = "Las contraseñas no coinciden."
        Else
            DbExec "UPDATE TBL_USER SET PASSWORD = CONVERT(varchar(40), HASHBYTES('SHA1', CONVERT(varchar(50), @p1)), 2) WHERE ID_USER = @p0", _
                   Array(CurrentUserId(), pNew)
            SetOk "Contraseña actualizada correctamente."
            Go U("Profile.asp")
        End If
    End If
End If

If Len(errMsg) > 0 Then SetError errMsg

Dim nMyPlaylists, nMyTracks
nMyPlaylists = N(DbScalar("SELECT COUNT(*) FROM TBL_PLAYLIST WHERE ID_USER = @p0", Array(CurrentUserId())))
nMyTracks = N(DbScalar("SELECT COUNT(*) FROM TBL_PLAYLIST_SONG ps INNER JOIN TBL_PLAYLIST p ON p.ID_PLAYLIST = ps.ID_PLAYLIST WHERE p.ID_USER = @p0", Array(CurrentUserId())))
%>
<!--#include file="inc/header.asp"-->

<div class="detail-head" style="align-items:center">
  <img class="detail-art round" style="width:160px;height:160px" src="<%=A(uPhoto)%>" alt="<%=A(uName)%>">
  <div class="detail-info">
    <div class="detail-kind">Perfil</div>
    <h1><%=H(NombreVisible(uName))%></h1>
    <div class="detail-meta">
      <span class="badge <%=IIfStr(uType = 1, "badge-admin", "badge-user")%>">
        <svg class="ico ico-sm"><use href="#i-<%=IIfStr(uType = 1, "shield", "user")%>"/></svg>
        <%=IIfStr(uType = 1, "Administrador", "Usuario")%>
      </span>
      <span class="dot">·</span><span><%=H(uEmail)%></span>
    </div>
  </div>
</div>

<div class="stats" style="max-width:520px">
  <div class="stat accent">
    <span>Playlists</span>
    <strong><%=nMyPlaylists%></strong>
  </div>
  <div class="stat">
    <span>Canciones guardadas</span>
    <strong><%=nMyTracks%></strong>
  </div>
</div>

<section class="section" style="margin-top:6px">
  <div class="panel">
    <div class="panel-head">
      <div>
        <h2>Datos personales</h2>
        <p>Actualiza tu información de cuenta.</p>
      </div>
    </div>

    <form method="post" action="<%=U("Profile.asp")%>" enctype="multipart/form-data">
      <%=CsrfField()%>
      <input type="hidden" name="form" value="profile">
      <input type="hidden" name="current_photo" value="<%=A(CurrentUserPhoto())%>">

      <div class="form-grid">
        <div class="field">
          <label for="username">Nombre de usuario</label>
          <input class="input" type="text" id="username" name="username" maxlength="50" required value="<%=A(uName)%>">
        </div>

        <div class="field">
          <label for="email">Correo electrónico</label>
          <input class="input" type="email" id="email" name="email" maxlength="50" required value="<%=A(uEmail)%>">
        </div>

        <div class="field">
          <label for="birthday">Fecha de nacimiento</label>
          <input class="input" type="date" id="birthday" name="birthday" value="<%=A(FechaInput(uBirth))%>">
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
          <svg class="ico ico-sm"><use href="#i-save"/></svg> Guardar cambios
        </button>
      </div>
    </form>
  </div>
</section>

<section class="section">
  <div class="panel">
    <div class="panel-head">
      <div>
        <h2>Seguridad</h2>
        <p>Cambia tu contraseña cuando lo necesites.</p>
      </div>
    </div>

    <form method="post" action="<%=U("Profile.asp")%>">
      <%=CsrfField()%>
      <input type="hidden" name="form" value="password">

      <div class="form-grid">
        <div class="field">
          <label for="new_password">Nueva contraseña</label>
          <input class="input" type="password" id="new_password" name="new_password" minlength="6"
                 placeholder="Mínimo 6 caracteres" required>
        </div>
        <div class="field">
          <label for="new_password2">Confirmar contraseña</label>
          <input class="input" type="password" id="new_password2" name="new_password2" minlength="6"
                 placeholder="Repite la contraseña" required>
        </div>
      </div>

      <div class="form-actions">
        <button class="btn btn-ghost" type="submit">
          <svg class="ico ico-sm"><use href="#i-lock"/></svg> Actualizar contraseña
        </button>
      </div>
    </form>
  </div>
</section>

<!--#include file="inc/footer.asp"-->
