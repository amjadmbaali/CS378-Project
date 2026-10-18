<%@page contentType="text/html" pageEncoding="UTF-8"%>

<%
    session.invalidate();

    response.sendRedirect("student_login.jsp");
%>