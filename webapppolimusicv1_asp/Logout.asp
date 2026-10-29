<%@ Language="VBScript" CodePage="65001" %>
<!--#include file="inc/config.asp"-->
<%
LogoutUser
Go U("Login.asp") & "?bye=1"
%>
