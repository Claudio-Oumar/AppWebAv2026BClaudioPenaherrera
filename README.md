# PoliMusic — Clon de Spotify en ASP clásico (tema morado)

Aplicación web de streaming de música construida con **ASP clásico (VBScript) + SQL Server**,
con la estética de Spotify pero en **morado**. Incluye autenticación por roles, catálogo de
canciones/álbumes/artistas, playlists y un reproductor persistente que no se corta al navegar.

> **Sobre la base de datos:** la aplicación **usa tu base existente** (`BDD_PoliMusic`) y
> **no crea bases, ni tablas, ni modifica el esquema**. Tampoco inserta datos de ejemplo:
> solo lee lo que ya tienes. Las escrituras ocurren únicamente cuando tú usas las pantallas
> de registro, CRUD o el reproductor (contador de reproducciones).

---

## 1. Requisitos

| Componente | Detalle |
|---|---|
| IIS | Con la característica **Classic ASP** (`IIS-ASP`) habilitada |
| SQL Server | Instancia en `localhost,1433` con la base `BDD_PoliMusic` ya poblada |
| Usuario SQL | `usr_polimusic` / `Politecnica1` (ya existe en el script de la BD) |
| Permisos | Cuenta de **administrador** de Windows para desplegar en `C:\inetpub\wwwroot` |

---

## 2. Despliegue automático (recomendado)

1. Haz **doble clic en `Deploy.bat`** (está en la raíz del proyecto).
2. Acepta el aviso de **UAC** (se necesitan permisos de administrador).
3. Espera a que termine. El script:
   - Habilita la característica *Classic ASP* de IIS.
   - Copia la aplicación a `C:\inetpub\wwwroot`.
   - Crea el App Pool **PoliMusicPool** (sin código administrado).
   - Da permisos de escritura a `IIS_IUSRS` en las carpetas de medios.
   - Registra los tipos MIME `.webp`, `.m4a`, `.ogg`.
   - Reinicia IIS.
4. Abre **http://localhost/** en el navegador.

El detalle del proceso queda en `tools\deploy-log.txt`.

> Si al terminar aparece un error 404.2, ejecuta `iisreset` o revisa
> *Administrador de IIS → Restricciones de ISAPI y CGI → asp.dll = Permitido*.

---

## 3. Despliegue manual (Administrador de IIS)

1. **Panel de control → Programas → Activar o desactivar características de Windows**
   → *Servicios de Internet Information Server → Servicios World Wide Web → Características de desarrollo de aplicaciones*
   → marcar **ASP** (y *Extensiones ISAPI*).
2. Copiar todo el contenido del proyecto a `C:\inetpub\wwwroot`
   (excluyendo `tools`, `SongFilesAndImages_resources`, `BDD_PoliMusic.sql`).
3. *Administrador de IIS* → **Grupos de aplicaciones** → crear `PoliMusicPool`
   con *.NET CLR = Sin código administrado*.
4. *Sitios* → **Default Web Site** → *Configuración básica* → ruta `C:\inetpub\wwwroot`
   y grupo de aplicaciones `PoliMusicPool`.
5. Permisos NTFS: dar **Modificar** a `IIS_IUSRS` sobre las carpetas
   `songFiles`, `albumImages`, `ArtistImages`, `playlistImages`, `userImages`.
6. `iisreset` y abrir `http://localhost/`.

El documento predeterminado (`Default.asp`) y los límites de subida (25 MB) ya están
declarados en `web.config`.

---

## 4. Cuentas

La aplicación **no crea usuarios ni credenciales por su cuenta**: inicia sesión contra la tabla
`TBL_USER` tal como esté en tu base. El login acepta las dos formas de contraseña que existen
en el esquema original:

- **Texto plano** (`12345678`, `Claudio23`, …) → comparación directa.
- **SHA1 en hexadecimal** (40 caracteres) → `HASHBYTES('SHA1', …)` del lado de SQL Server.

Por eso funciona con cualquier combinación que tengas cargada, sin migrar nada.

En la **pantalla de login** se listan las cuentas que hay realmente en `TBL_USER`
(si la contraseña está en texto plano se muestra; si está en SHA1 se indica como cifrada).
Así la ayuda siempre coincide con tu base y no hay credenciales escritas a mano en el código.

Los roles se leen de `USER_TYPE`:

| `USER_TYPE` | Rol | Permisos |
|---|---|---|
| `1` | Administrador | CRUD de usuarios, canciones, artistas, álbumes y playlists |
| `0` | Usuario normal | Reproducir, consultar catálogo y CRUD de sus propias playlists |

---

## 5. Funcionalidades

### Usuario normal (`USER_TYPE = 0`)
- Reproducir cualquier canción del catálogo.
- Consultar álbumes, artistas y playlists públicas.
- **CRUD completo de sus propias playlists**: crear, renombrar, cambiar portada,
  pasar de pública a privada, añadir/quitar canciones y eliminar.
- Editar su perfil (usuario, correo, cumpleaños, foto y contraseña).
- Buscar en todo el catálogo.

### Administrador (`USER_TYPE = 1`)
Todo lo anterior **más** el panel de administración:
- **Usuarios**: crear, editar (incluye rol y contraseña), eliminar (con sus playlists).
- **Canciones**: crear/editar con subida de MP3, asignar artistas y álbumes, eliminar.
- **Artistas**: crear/editar con fotografía, eliminar.
- **Álbumes**: crear/editar con portada y selección de pistas, eliminar.
- **Playlists**: ver y administrar las de todos los usuarios.

### Reproductor (siempre visible)
- Cola de reproducción, anterior/siguiente, aleatorio y repetir (off / todo / una).
- Barra de progreso y volumen con memoria en `localStorage`.
- **No se reinicia al navegar**: la navegación es tipo SPA (PJAX) y la barra vive fuera
  del área que se reemplaza.
- Contador de reproducciones que se incrementa en la base de datos (`Api/Play.asp`).
- Integración con *Media Session* (controles del sistema operativo).

---

## 6. Estructura del proyecto

```
/
├─ Default.asp            Punto de entrada (redirige a Home o Login)
├─ Login.asp / Register.asp / Logout.asp
├─ Home.asp               Pantalla principal
├─ Search.asp             Búsqueda con filtros
├─ Album.asp / Artist.asp Vistas de detalle
├─ Playlist.asp           Detalle + CRUD de canciones de la playlist
├─ Playlists.asp          Biblioteca del usuario + creación
├─ Profile.asp            Perfil y contraseña
├─ Admin/
│   ├─ Users.asp  Songs.asp  Artists.asp  Albums.asp  Playlists.asp
├─ Api/Play.asp           Incremento de reproducciones (JSON)
├─ inc/
│   ├─ config.asp         Constantes y arranque
│   ├─ db.asp             Capa ADO parametrizada
│   ├─ util.asp           Helpers (URLs, formato, flash, JSON)
│   ├─ auth.asp           Sesión, roles, CSRF
│   ├─ upload.asp         Parser multipart propio (sin componentes)
│   ├─ ui.asp             Componentes (fila, tarjeta, cola del player)
│   ├─ header.asp / footer.asp / icons.asp
├─ Assets/Css/app.css     Tema morado completo
├─ Assets/Js/player.js    Reproductor persistente
├─ Assets/Js/app.js       Navegación PJAX e interacciones
├─ songFiles/  albumImages/  ArtistImages/  playlistImages/  userImages/
├─ web.config             Documento por defecto, límites, MIME, filtros
├─ Deploy.bat             Instalador de un clic (eleva privilegios)
└─ tools/                 Scripts de apoyo (no se despliegan)
```

---

## 7. Decisiones técnicas

- **Consultas parametrizadas** con `ADODB.Command` en toda la aplicación → sin inyección SQL.
- **Salida escapada** con `Server.HTMLEncode` / helper `A()` → sin XSS.
- **Token CSRF** en todos los formularios POST, validado en servidor.
- **Autorización en servidor**: cada acción de administración llama a `RequireAdmin`;
  las playlists verifican propiedad (`ID_USER`) antes de cualquier cambio.
- **Subida de archivos** implementada con `Request.BinaryRead` + `ADODB.Stream`,
  sin componentes de terceros. Se validan extensión y tamaño.
- **Contraseñas** con `HASHBYTES('SHA1', …)` calculado en SQL Server (no hay que
  implementar SHA1 en VBScript).
- **Conexión** con reintento automático entre proveedores OLE DB
  (`MSOLEDBSQL` → `SQLNCLI11` → `SQLOLEDB`).
- **Cursor del lado del cliente** (`adUseClient`) para poder usar `RecordCount`/`MoveFirst`.

---

## 8. Notas sobre los recursos

- El paquete original solo traía `bensound-adventure.mp3`. Para que las 5 canciones de la
  base de datos suenen, se copió ese archivo como `bensound-dreams.mp3`, `bensound-energy.mp3`,
  `bensound-scifi.mp3` y `bensound-tomorrow.mp3`. **Reemplázalos por los audios reales cuando
  los tengas** (mismo nombre de archivo y no hay que tocar la base).
- Las portadas de álbumes y las fotos de artistas no venían en el paquete, así que se
  generaron con el script `tools/generate_assets.py` (degradados morados con el título).
  También se generó `userImages/username1.png`, que faltaba.
- Los archivos que suba el administrador se guardan en las mismas carpetas y la base
  almacena la ruta relativa (`~/carpeta/archivo.ext`).

---

## 9. Solución de problemas

| Síntoma | Causa / solución |
|---|---|
| **404.2 – ISAPI/CGI** | Classic ASP no está habilitado, o `asp.dll` está restringido. Ejecuta `Deploy.bat`. |
| **404.3** en `.mp3`/`.webp` | Falta el tipo MIME. El script de despliegue lo registra. |
| **500.100 – Error de compilación ASP** | `scriptErrorSentToBrowser` está activo en `web.config`; el mensaje indica la línea. |
| **"No se pudo conectar a SQL Server"** | Verifica el servicio `MSSQLSERVER` y que `BDD_PoliMusic` exista. |
| **No se guardan las fotos/audios subidos** | Faltan permisos de escritura para `IIS_IUSRS` en las carpetas de medios. |
| **El reproductor no avanza** | El navegador bloquea el autoplay; pulsa play una vez (política del navegador). |

---

## 10. Verificación realizada

- Las **17 páginas ASP** se compilaron con `cscript` (`tools/check_asp.py`) → 0 errores de sintaxis.
- Las **10 consultas SQL** principales se ejecutaron contra `BDD_PoliMusic` (`tools/test_queries.sql`) → resultados correctos.
- El login se validó contra los dos formatos de contraseña del esquema (texto plano y SHA1).

La instalación de IIS y la ejecución en navegador deben hacerse en una cuenta con permisos
de administrador (esta sesión no los tiene).
