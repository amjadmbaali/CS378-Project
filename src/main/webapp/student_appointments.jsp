<%@page import="db.DBConnection"%>
<%@page import="java.sql.*"%>
<%@page import="java.util.*"%>
<%@page import="java.text.SimpleDateFormat"%>
<%@page contentType="text/html" pageEncoding="UTF-8"%>

<%
    String studentEmail = (String) session.getAttribute("studentEmail");
    String studentName = (String) session.getAttribute("studentName"); // للاستخدام في العرض فقط

    if (studentEmail == null) {
        response.sendRedirect("student_login.jsp");
        return;
    }

    String successMessage = "";
    String errorMessage = "";
    
    Connection conn = null;
    PreparedStatement pstmt = null;
    ResultSet rs = null;

    String appointmentIdToCancel = request.getParameter("cancelId");
    
    if (appointmentIdToCancel != null && !appointmentIdToCancel.isEmpty()) {
        try {
            conn = DBConnection.getConnection();
            
            String cancelSql = "UPDATE Appointments SET Status = 'Canceled' WHERE Appointment_ID = ? AND Student_Email = ?";
            pstmt = conn.prepareStatement(cancelSql);
            pstmt.setInt(1, Integer.parseInt(appointmentIdToCancel));
            pstmt.setString(2, studentEmail); 

            int rowsAffected = pstmt.executeUpdate();

            if (rowsAffected > 0) {
                successMessage = "Appointment successfully canceled!";
            } else {
                errorMessage = "Cancellation failed or appointment not found. You can only cancel your own appointments.";
            }

        } catch (SQLException e) {
            errorMessage = "Database Error during cancellation: " + e.getMessage();
        } finally {
            if (pstmt != null) try { pstmt.close(); } catch (SQLException ignore) {}
        }
    }

    List<Map<String, String>> appointments = new ArrayList<>();
    
    try {
        if (conn == null || conn.isClosed()) {
            conn = DBConnection.getConnection();
        }
        
        String readSql = "SELECT a.Appointment_ID, s.Staff_Name, a.Day_of_Week, a.Appointment_Time_Slot, a.Status, a.Appointment_Date " +
                         "FROM Appointments a JOIN Staff s ON a.Staff_ID = s.Staff_ID " +
                         "WHERE a.Student_Email = ? AND a.Appointment_Date >= CURDATE() AND a.Status = 'Confirmed' " +
                         "ORDER BY a.Appointment_Date ASC, a.Appointment_Time_Slot ASC";
                         
        pstmt = conn.prepareStatement(readSql);
        pstmt.setString(1, studentEmail); 
        rs = pstmt.executeQuery();

        while (rs.next()) {
            Map<String, String> appt = new HashMap<>();
            appt.put("id", rs.getString("Appointment_ID"));
            appt.put("staffName", rs.getString("Staff_Name"));
            appt.put("day", rs.getString("Day_of_Week"));
            appt.put("time", rs.getString("Appointment_Time_Slot"));
            appt.put("date", rs.getString("Appointment_Date"));
            appt.put("status", rs.getString("Status"));
            appointments.add(appt);
        }

    } catch (SQLException e) {
        errorMessage = "Error fetching appointments: " + e.getMessage();
    } finally {
        if (rs != null) try { rs.close(); } catch (SQLException ignore) {}
        if (pstmt != null) try { pstmt.close(); } catch (SQLException ignore) {}
        DBConnection.closeConnection(conn);
    }
%>

<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>My Appointments</title>
    <link rel="stylesheet" href="/StudentServices1/css/style.css">
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.0.0-beta3/css/all.min.css">
    <style>
        .appointment-card {
            background-color: #e9f6fb; 
            padding: 15px;
            border-radius: 8px;
            margin-bottom: 15px;
            border-left: 5px solid var(--dark-blue);
            display: flex;
            justify-content: space-between;
            align-items: center;
            max-width: 800px;
        }
        .cancel-btn {
            background-color: #dc3545; 
            color: white;
            border: none;
            padding: 8px 15px;
            border-radius: 25px;
            cursor: pointer;
            text-decoration: none;
            font-size: 0.9rem;
            margin-left: 10px;
        }
        .content-area {
            max-width: 800px;
            margin: 20px auto;
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
        <h2 class="last-search-title">My Appointments (<%= studentName != null ? studentName : studentEmail %>)</h2>
        
        <% if (!successMessage.isEmpty()) { %>
            <p style="color: green; font-weight: bold; margin-bottom: 15px;"><%= successMessage %></p>
        <% } else if (!errorMessage.isEmpty()) { %>
            <p style="color: red; font-weight: bold; margin-bottom: 15px;"><%= errorMessage %></p>
        <% } %>
        
        <% if (appointments.isEmpty()) { %>
            <p style="text-align: center; margin-top: 30px;">You have no future confirmed appointments.</p>
        <% } else { %>
            <div class="appointment-list">
                <% for (Map<String, String> appt : appointments) { %>
                    <div class="appointment-card">
                        <div>
                            <strong>Staff:</strong> <%= appt.get("staffName") %><br>
                            <strong>Date:</strong> <%= appt.get("date") %> (<%= appt.get("day") %>)<br>
                            <strong>Time:</strong> <%= appt.get("time") %>
                        </div>
                        <a href="student_appointments.jsp?cancelId=<%= appt.get("id") %>" class="cancel-btn" onclick="return confirm('Are you sure you want to cancel this appointment?');">
                            Cancel
                        </a>
                    </div>
                <% } %>
            </div>
        <% } %>
        
    </div>

    <script>
        function toggleNav() {
            document.getElementById("menu-sidebar").classList.toggle("open");
        }
    </script>
</body>
</html>