<%@page import="db.DBConnection"%>
<%@page import="java.sql.*"%>
<%@page import="java.util.*"%>
<%@page contentType="text/html" pageEncoding="UTF-8"%>

<% 
    request.setCharacterEncoding("UTF-8");
    response.setCharacterEncoding("UTF-8");

    String departmentName = request.getParameter("dept");
    if (departmentName == null) {
        departmentName = "Department View"; 
    }
    
    String searchQuery = request.getParameter("searchQuery");
    if (searchQuery == null) {
        searchQuery = "";
    }
    
    List<Map<String, String>> staffList = new ArrayList<>();
    
    Connection conn = null;
    PreparedStatement pstmt = null;
    ResultSet rs = null;
    
    try {
        conn = DBConnection.getConnection();
        
        String sql = "SELECT s.Staff_ID, s.Staff_Name, s.Email, s.Office_No, d.Dept_Name " +
                     "FROM Staff s JOIN Departments d ON s.Dept_ID = d.Dept_ID " +
                     "WHERE d.Dept_Name = ?";
        
        if (!searchQuery.trim().isEmpty()) {
            sql += " AND (s.Staff_Name LIKE ? OR s.Office_No LIKE ?)";
        }
        
        pstmt = conn.prepareStatement(sql);
        int paramIndex = 1;
        
        pstmt.setString(paramIndex++, departmentName);
        
        if (!searchQuery.trim().isEmpty()) {
            String searchPattern = "%" + searchQuery + "%";
            pstmt.setString(paramIndex++, searchPattern);
            pstmt.setString(paramIndex++, searchPattern);
        }
        
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
        
    } catch (SQLException e) {
        System.err.println("Database Error: Could not fetch staff list for department " + departmentName + ". " + e.getMessage());
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
    <title><%= departmentName %> Staff</title>
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
            <form action="department_view.jsp" method="GET" style="margin-bottom: 20px;">
                <input type="hidden" name="dept" value="<%= departmentName.replace("\"", "&quot;") %>">
                
                <div class="search-bar"> 
                    <input type="text" name="searchQuery" placeholder="Search by Name or Office No." class="search-input" value="<%= searchQuery.replace("\"", "&quot;") %>">
                    <button type="submit" class="search-btn">
                        <i class="fas fa-search"></i>
                    </button>
                </div>
            </form>

            <%
                String headerText = "Staff in the " + departmentName + " Department";
                if (!searchQuery.trim().isEmpty()) {
                    headerText = "Search Results in " + departmentName;
                }
            %>
            <h3 class="last-search-title"><%= headerText %> (<%= staffList.size() %>)</h3>
            
            <div class="last-search-list">
                <% 
                    if (staffList.isEmpty()) { 
                %>
                    <p style="text-align: center; color: #666; margin-top: 50px;">No staff members found matching your search criteria.</p>
                <% 
                    } else {
                        for (Map<String, String> staff : staffList) {
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