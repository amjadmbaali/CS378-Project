<%@page import="db.DBConnection"%>
<%@page import="java.sql.*"%>
<%@page import="jakarta.servlet.http.Cookie"%>
<%@page contentType="text/html" pageEncoding="UTF-8"%>

<%
    String savedEmail = "";
    Cookie[] cookies = request.getCookies();
    if (cookies != null) {
        for (Cookie c : cookies) {
            if ("savedEmail".equals(c.getName())) {
                savedEmail = c.getValue();
            }
        }
    }
    
    if (session.getAttribute("studentEmail") != null) {
        response.sendRedirect("index.jsp");
        return; 
    }

    String errorMessage = "";
    
    if ("POST".equalsIgnoreCase(request.getMethod())) {
        
        String email = request.getParameter("username");
        String password = request.getParameter("password"); 

        Connection conn = null;
        PreparedStatement pstmt = null;
        ResultSet rs = null;

        try {
            conn = DBConnection.getConnection();
            
            String sql = "SELECT Student_Name, Email FROM Students WHERE Email = ? AND Password_Hash = ?";
            pstmt = conn.prepareStatement(sql);
            pstmt.setString(1, email);
            pstmt.setString(2, password); 

            rs = pstmt.executeQuery();

            if (rs.next()) {
                String studentName = rs.getString("Student_Name");
                String studentEmail = rs.getString("Email");
                
                session.setAttribute("studentEmail", studentEmail);
                session.setAttribute("studentName", studentName);

                Cookie emailCookie = new Cookie("savedEmail", email);
                emailCookie.setMaxAge(7 * 24 * 60 * 60); 
                response.addCookie(emailCookie);
                
                response.sendRedirect("index.jsp");
                return;

            } else {
                errorMessage = "Login Failed: Incorrect Email or Password.";
            }

        } catch (SQLException e) {
            errorMessage = "Database Error: Please check server logs.";
        } finally {
            if (rs != null) try { rs.close(); } catch (SQLException ignore) { /* ignore */ }
            if (pstmt != null) try { pstmt.close(); } catch (SQLException ignore) { /* ignore */ }
            DBConnection.closeConnection(conn);
        }
    }
%>

<!DOCTYPE html>
<html lang="en"> 
<head>
    <meta charset="UTF-8">
    <title>Student Login</title>
    <link rel="stylesheet" href="/StudentServices1/css/style.css">
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.0.0-beta3/css/all.min.css">
    <style>
        .login-container {
            max-width: 400px;
            margin: 80px auto;
            padding: 30px;
            background-color: var(--white);
            border-radius: 10px;
            box-shadow: 0 4px 15px rgba(0, 0, 0, 0.1);
            text-align: center;
        }
        .login-container h2 {
            color: var(--dark-blue);
            margin-bottom: 25px;
            font-size: 1.5rem;
        }
        .login-form input[type="text"],
        .login-form input[type="password"] {
            width: 100%;
            padding: 12px;
            margin-bottom: 15px;
            border: 1px solid #ccc;
            border-radius: 25px;
            text-align: left;
            box-sizing: border-box;
        }
        .login-form button {
            width: 100%;
            padding: 12px;
            background-color: var(--dark-blue);
            color: var(--white);
            border: none;
            border-radius: 25px;
            font-size: 1.1rem;
            cursor: pointer;
            transition: background-color 0.3s;
            margin-top: 10px;
        }
        .login-form button:hover {
            background-color: #0c2957;
        }
        .forgot-password a {
            color: var(--dark-blue);
            text-decoration: none;
            font-size: 0.9rem;
            display: block;
            margin-top: 15px;
        }
    </style>
</head>
<body>
    <div class="header" style="justify-content: flex-start;">
        <div class="logo">
            <img src="https://skhic.com.sa/wp-content/uploads/2024/07/RCJY-Horizontal-Lockup.png" alt="Royal Commission Logo"> 
        </div>
    </div>

    <div class="login-container">
        <h2 style="color: var(--dark-blue);">STUDENT LOGIN</h2>
        <h2>WELCOME TO STUDENT SERVICES</h2>
        
        <form class="login-form" method="POST" action="student_login.jsp">
            
            <% if (!errorMessage.isEmpty()) { %>
                <p style="color: red; margin-bottom: 10px;"><%= errorMessage %></p>
            <% } %>
            
            <input type="text" name="username" value="<%= savedEmail %>" placeholder="Email:" required>
            <input type="password" name="password" placeholder="Password:" required>            
            <button type="submit">Sign In</button>

        </form>
    </div>
    
</body>
</html>