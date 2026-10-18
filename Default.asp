<%@ Language="VBScript" CodePage="65001" %>
<!--#include file="inc/config.asp"-->
<%
If IsLoggedIn() Then
    Go U("Home.asp")
Else
    Go U("Login.asp")
End If
%>
