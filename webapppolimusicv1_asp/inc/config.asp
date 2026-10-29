<%
' ============================================================================
'  PoliMusic - Configuracion global
'  Aplicacion web ASP clasico
' ============================================================================

Response.Buffer   = True
Response.Charset  = "utf-8"
Response.CodePage = 65001
Session.CodePage  = 65001
Session.Timeout   = 120

' --- Identidad de la aplicacion ---------------------------------------------
Const APP_NAME    = "PoliMusic"
Const APP_TAGLINE = "Tu musica, tu universo morado"
Const APP_VERSION = "1.0"

' --- Base de datos ----------------------------------------------------------
Const DB_SERVER = "localhost,1433"
Const DB_NAME   = "BDD_PoliMusic"
Const DB_USER   = "usr_polimusic"
Const DB_PASS   = "Politecnica1"

' --- Roles ------------------------------------------------------------------
Const ROLE_USER  = 0
Const ROLE_ADMIN = 1

' --- Limites de subida (bytes) ----------------------------------------------
Const MAX_AUDIO_BYTES = 20971520   ' 20 MB
Const MAX_IMAGE_BYTES = 4194304    '  4 MB

' --- Catalogos --------------------------------------------------------------
Const CAT_USER_TYPE     = "1"
Const CAT_PLAYLIST_TYPE = "2"
%>
<!--#include file="db.asp"-->
<!--#include file="util.asp"-->
<!--#include file="auth.asp"-->
<!--#include file="upload.asp"-->
<!--#include file="ui.asp"-->
