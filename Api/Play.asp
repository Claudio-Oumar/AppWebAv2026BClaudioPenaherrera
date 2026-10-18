<%@ Language="VBScript" CodePage="65001" %>
<!--#include file="../inc/config.asp"-->
<%
Response.ContentType = "application/json"
Response.CacheControl = "no-store"

Dim sid, plays
sid = N(QS("id"))

If Not IsLoggedIn() Then
    Response.Status = "401 Unauthorized"
    Response.Write "{""ok"":false,""error"":""auth""}"
ElseIf sid <= 0 Then
    Response.Status = "400 Bad Request"
    Response.Write "{""ok"":false,""error"":""id""}"
Else
    DbExec "UPDATE TBL_SONG SET PLAYS = ISNULL(PLAYS,0) + 1 WHERE ID_SONG = @p0", Array(sid)
    plays = N(DbScalar("SELECT ISNULL(PLAYS,0) FROM TBL_SONG WHERE ID_SONG = @p0", Array(sid)))
    Response.Write "{""ok"":true,""id"":" & sid & ",""plays"":" & plays & "}"
End If

DbClose
%>
