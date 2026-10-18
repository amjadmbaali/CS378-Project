<%@page import="db.DBConnection"%>
<%@page import="java.sql.*"%>
<%@page import="java.util.*"%>
<%@page contentType="text/html" pageEncoding="UTF-8"%>

<% 
    request.setCharacterEncoding("UTF-8");
    response.setCharacterEncoding("UTF-8");

    Connection conn = null;
    PreparedStatement pstmt = null;
    ResultSet rs = null;
    
    List<Map<String, String>> staffList = new ArrayList<>(); 
    
    List<Map<String, String>> lastSearchList = (List<Map<String, String>>) session.getAttribute("lastSearchList");
    if (lastSearchList == null) {
        lastSearchList = new ArrayList<>();
        session.setAttribute("lastSearchList", lastSearchList);
    }
    
    String searchQuery = request.getParameter("searchQuery");
    if (searchQuery == null) { searchQuery = ""; }
      
    try {
        conn = DBConnection.getConnection();
        
        if (!searchQuery.trim().isEmpty()) {
            String sql = "SELECT s.Staff_ID, s.Staff_Name, s.Email, s.Office_No, d.Dept_Name " +
                         "FROM Staff s JOIN Departments d ON s.Dept_ID = d.Dept_ID " +
                         "WHERE s.Staff_Name LIKE ? OR d.Dept_Name LIKE ?";
            
            pstmt = conn.prepareStatement(sql);
            pstmt.setString(1, "%" + searchQuery + "%");
            pstmt.setString(2, "%" + searchQuery + "%"); 
            
            rs = pstmt.executeQuery();
            
            while (rs.next()) {
                Map<String, String> staff = new HashMap<>();
                staff.put("id", rs.getString("Staff_ID"));
                staff.put("name", rs.getString("Staff_Name"));
                staff.put("email", rs.getString("Email"));
                staff.put("officeNo", rs.getString("Office_No"));
                staff.put("department", rs.getString("Dept_Name"));
                staffList.add(staff);
            }
        }
        
    } catch (SQLException e) {
        System.err.println("Database Error: Could not fetch staff list. " + e.getMessage());
    } finally {
        if (rs != null) try { rs.close(); } catch (SQLException ignore) { /* ignore */ }
        if (pstmt != null) try { pstmt.close(); } catch (SQLException ignore) { /* ignore */ }
        DBConnection.closeConnection(conn);
    }
%>


<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Student Services - Search</title>
    <link rel="stylesheet" href="/StudentServices1/css/style.css">
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.0.0-beta3/css/all.min.css">
    <style>
        .staff-card {
            display: block;
            text-decoration: none;
        }
        .staff-card p, .staff-card div {
            color: var(--dark-blue) !important; 
            text-decoration: none !important; 
        }
        .search-container {
            width: 100%; 
            background-color: var(--white);
            padding: 20px;
            border-radius: 8px;
            box-shadow: 0 2px 4px rgba(0, 0, 0, 0.05);
            margin-bottom: 20px; 
        }
    </style>
</head>
<body>

    <div id="menu-sidebar" class="menu-sidebar">
        <a href="index.jsp" class="menu-item"><i class="fas fa-home"></i> Home (Search)</a> 
        <a href="department_view.jsp?dept=MS" class="menu-item"><i class="fas fa-industry"></i> MS</a>
        <a href="department_view.jsp?dept=CSE" class="menu-item"><i class="fas fa-microchip"></i> CSE</a>
        <a href="department_view.jsp?dept=Math" class="menu-item"><i class="fas fa-calculator"></i> Math</a>
        <a href="department_view.jsp?dept=Design" class="menu-item"><i class="fas fa-pen-ruler"></i> Design</a>
        <a href="department_view.jsp?dept=English" class="menu-item"><i class="fas fa-globe"></i> English</a>
        <a href="student_appointments.jsp" class="menu-item"><i class="fas fa-calendar-check"></i> My Appointments</a>
        <a href="notifications.jsp" class="menu-item"><i class="fas fa-bell"></i> Notifications</a> 
        <a href="student_logout.jsp" class="menu-item"><i class="fas fa-sign-out-alt"></i> Log out</a> 
    </div>

    <div class="header">
        <div class="header-left">
            <div class="logo">
                <img src="https://skhic.com.sa/wp-content/uploads/2024/07/RCJY-Horizontal-Lockup.png" alt="Royal Commission Logo"> 
            </div>
            <div class="header-title">Student Services</div>
        </div>
        <div class="header-icons">
            <button class="icon-btn" onclick="toggleNav()">
                <i class="fas fa-bars"></i> 
            </button>
        </div>
    </div>
    
<div class="content-area">
        
        <div class="search-container">
        
            <form action="index.jsp" method="GET" style="margin-bottom: 20px;">
                <div class="search-bar"> 
                    <input type="text" name="searchQuery" placeholder="Search by Name or Department" class="search-input" value="<%= searchQuery.replace("\"", "&quot;") %>">
                    <button type="submit" class="search-btn">
                        <i class="fas fa-search"></i>
                    </button>
                </div>
            </form>
            
<%
    String headerText = "Last Search"; 
    if (!searchQuery.trim().isEmpty()) {
        headerText = "Search Results";
    }
%>

<h3 class="last-search-title"><%= headerText %></h3>            
<div class="last-search-list">
                <% 
                    List<Map<String, String>> displayList = staffList;
                    boolean isSearching = !searchQuery.trim().isEmpty();
                    
                    if (!isSearching) {
                        displayList = lastSearchList; 
                    }

                    if (displayList.isEmpty()) { 
                %>
                    <p style="text-align: center; color: #666; margin-top: 50px;">Please search for a staff member or view a profile to see recent activity.</p>
                <% 
                    } else {
                        for (Map<String, String> staff : displayList) {
                %>
                    <a href="staff_profile.jsp?staffId=<%= staff.get("id") %>" class="staff-card">
                        <div class="staff-name"><%= staff.get("name") %></div>
                        <p class="staff-office">Office No. <%= staff.get("officeNo") %></p>
                        <p class="staff-email">Email: <%= staff.get("email") %></p>
                        <p class="staff-department">Department: <%= staff.get("department") %></p>
                    </a>
                <% 
                        } 
                    }
                %>
                
            </div>
        </div>
    </div>

    <script>
        function toggleNav() {
            document.getElementById("menu-sidebar").classList.toggle("open");
        }
    </script>
</body>
</html>