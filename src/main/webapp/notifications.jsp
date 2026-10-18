<%@page import="db.DBConnection"%>
<%@page import="java.sql.*"%>
<%@page import="java.util.*"%>
<%@page contentType="text/html" pageEncoding="UTF-8"%>

<%
    String studentEmail = (String) session.getAttribute("studentEmail");

    if (studentEmail == null) {
        response.sendRedirect("student_login.jsp");
        return;
    }

    Connection conn = null;
    PreparedStatement pstmt = null;
    String errorMessage = "";
    String successMessage = "";
    
    String staffIdToCancel = request.getParameter("cancel_staff_id");
    
    if (staffIdToCancel != null && !staffIdToCancel.isEmpty()) {
        try {
            conn = DBConnection.getConnection();
            
            String cancelSql = "UPDATE Notification_Subscriptions SET Status = 'Inactive' WHERE Student_Email = ? AND Staff_ID = ?";
            pstmt = conn.prepareStatement(cancelSql);
            pstmt.setString(1, studentEmail);
            pstmt.setInt(2, Integer.parseInt(staffIdToCancel));
            
            int rowsAffected = pstmt.executeUpdate();
            
            if (rowsAffected > 0) {
                successMessage = "Subscription successfully cancelled";
            } else {
                errorMessage = "Cancellation failed or subscription not found.";
            }

        } catch (SQLException e) {
            errorMessage = "Database Error during cancellation: " + e.getMessage();
        } finally {
            if (pstmt != null) try { pstmt.close(); } catch (SQLException ignored) {}
        }
    }
 
    List<Map<String, String>> activeSubscriptions = new ArrayList<>();
    ResultSet rs = null;

    try {
        if (conn == null || conn.isClosed()) {
            conn = DBConnection.getConnection();
        }
        
        String readSql = "SELECT s.Staff_ID, s.Staff_Name, ns.Status " +
                         "FROM Staff s JOIN Notification_Subscriptions ns ON s.Staff_ID = ns.Staff_ID " +
                         "WHERE ns.Student_Email = ? AND ns.Status = 'Active' " +
                         "ORDER BY s.Staff_Name";
                         
        pstmt = conn.prepareStatement(readSql);
        pstmt.setString(1, studentEmail);
        rs = pstmt.executeQuery();

        while (rs.next()) {
            Map<String, String> staff = new HashMap<>();
            staff.put("id", rs.getString("Staff_ID"));
            staff.put("name", rs.getString("Staff_Name"));
            activeSubscriptions.add(staff);
        }

    } catch (SQLException e) {
        errorMessage = "Error fetching subscriptions: " + e.getMessage();
    } finally {
        if (rs != null) try { rs.close(); } catch (SQLException ignored) {}
        if (pstmt != null) try { pstmt.close(); } catch (SQLException ignored) {}
        DBConnection.closeConnection(conn);
    }
%>

<!DOCTYPE html>
<html lang="en"> 
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>My Subscribed Notifications</title>
    <link rel="stylesheet" href="/StudentServices1/css/style.css"> 
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.0.0-beta3/css/all.min.css">
    
    <style>
        body { background-color: var(--background-color, #F4F6F9); min-height: 100vh; display: flex; flex-direction: column; }
        .content-area { max-width: 500px; margin: 20px auto; padding: 20px; width: 100%; }
        .save-btn-container { display: none; } 
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
            <div class="header-title">Student services</div>
        </div>
        <div class="header-icons">
             <button class="icon-btn" onclick="toggleNav()">
                <i class="fas fa-bars"></i> 
            </button>
        </div>
    </div>
    
    <div class="content-area">
        
        <h2 class="settings-title">My Active Subscriptions</h2>
        
        <% if (!successMessage.isEmpty()) { %>
            <p style="color: green; font-weight: bold; margin-bottom: 15px;"><%= successMessage %></p>
        <% } else if (!errorMessage.isEmpty()) { %>
            <p style="color: red; font-weight: bold; margin-bottom: 15px;"><%= errorMessage %></p>
        <% } %>
        
        <div class="settings-card">
            
            <% if (activeSubscriptions.isEmpty()) { %>
                <p style="padding: 15px; text-align: center; color: #666;">You are not subscribed to notifications for any staff member. Please subscribe from the staff member's profile page.</p>
            <% } else { %>
                
                <% 
                    for (Map<String, String> staff : activeSubscriptions) {
                        String staffId = staff.get("id");
                        String staffName = staff.get("name");
                %>
                
                <div class="setting-list-item" style="<%= activeSubscriptions.indexOf(staff) == activeSubscriptions.size() - 1 ? "border-bottom: none;" : "" %>">
                    
                    <div class="item-content">
                        <i class="fas fa-user"></i> 
                        <div class="item-text">
                            <h4><%= staffName %></h4>
                            <p>Click the toggle to unsubscribe and remove.</p>
                        </div>
                    </div>
                    
                    <form method="POST" action="notifications.jsp" style="margin: 0;">
                        <input type="hidden" name="cancel_staff_id" value="<%= staffId %>">
                        <label class="toggle-switch">
                            <input type="checkbox" checked onchange="this.form.submit()">
                            <span class="slider"></span>
                        </label>
                    </form>
                </div>
                
                <% } %>
                
            <% } %>
            
        </div>
    </div>
    
    <script>
        function toggleNav() {
            document.getElementById("menu-sidebar").classList.toggle("open");
        }
    </script>
</body>
</html>