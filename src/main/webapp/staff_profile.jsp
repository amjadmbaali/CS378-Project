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

    String staffIdStr = request.getParameter("staffId");
    int staffId = 0;
    if (staffIdStr != null) {
        try {
            staffId = Integer.parseInt(staffIdStr);
        } catch (NumberFormatException e) { /* ignore */ }
    }
    
    String staffName = "Staff Member Not Found"; 
    String email = "N/A";
    String officeNo = "N/A";
    String departmentName = "N/A";

    boolean isSubscribed = false; 
    String action = request.getParameter("action"); 
    
    Map<String, String[]> scheduleMap = new LinkedHashMap<>();
    String[] timeSlots = {"7-8", "8-9", "9-10", "10-11", "11-12", "12-13", "13-14", "14-15", "15-16"}; 
    String[] days = {"SUNDAY", "MONDAY", "TUESDAY", "WEDNESDAY", "THURSDAY"};
    
    for (String time : timeSlots) {
        scheduleMap.put(time, new String[]{"None", "None", "None", "None", "None"});
    }
    
    Connection conn = null;
    PreparedStatement pstmt = null;
    ResultSet rs = null;
    ResultSet rsDetails = null;
    ResultSet rsAppointments = null;
    
    try {
        conn = DBConnection.getConnection();

        if (action != null && !staffIdStr.isEmpty()) {
            if (action.equals("subscribe")) {
                String subscribeSql = "INSERT INTO Notification_Subscriptions (Student_Email, Staff_ID, Status) VALUES (?, ?, 'Active') " +
                                      "ON DUPLICATE KEY UPDATE Status = 'Active'";
                pstmt = conn.prepareStatement(subscribeSql);
                pstmt.setString(1, studentEmail);
                pstmt.setInt(2, staffId);
                pstmt.executeUpdate();
                pstmt.close();
            } else if (action.equals("unsubscribe")) {
                String unsubscribeSql = "UPDATE Notification_Subscriptions SET Status = 'Inactive' WHERE Student_Email = ? AND Staff_ID = ?";
                pstmt = conn.prepareStatement(unsubscribeSql);
                pstmt.setString(1, studentEmail);
                pstmt.setInt(2, staffId);
                pstmt.executeUpdate();
                pstmt.close();
            }
            response.sendRedirect("staff_profile.jsp?staffId=" + staffId);
            return;
        }

        String sqlDetails = "SELECT s.Staff_Name, s.Email, s.Office_No, d.Dept_Name FROM Staff s JOIN Departments d ON s.Dept_ID = d.Dept_ID WHERE s.Staff_ID = ?";
        pstmt = conn.prepareStatement(sqlDetails);
        pstmt.setInt(1, staffId);
        rsDetails = pstmt.executeQuery();
        
        if (rsDetails.next()) {
            staffName = rsDetails.getString("Staff_Name");
            email = rsDetails.getString("Email");
            officeNo = rsDetails.getString("Office_No");
            departmentName = rsDetails.getString("Dept_Name");

            String checkSubSql = "SELECT Status FROM Notification_Subscriptions WHERE Student_Email = ? AND Staff_ID = ?";
            
            if (rsDetails != null) rsDetails.close();
            if (pstmt != null) pstmt.close();
            
            pstmt = conn.prepareStatement(checkSubSql);
            pstmt.setString(1, studentEmail);
            pstmt.setInt(2, staffId);
            rsDetails = pstmt.executeQuery();
            
            if (rsDetails.next()) {
                isSubscribed = "Active".equals(rsDetails.getString("Status"));
            }

            Map<String, String> currentStaff = new HashMap<>();
            currentStaff.put("id", String.valueOf(staffId));
            currentStaff.put("name", staffName);
            currentStaff.put("email", email);
            currentStaff.put("officeNo", officeNo);
            currentStaff.put("department", departmentName);

            List<Map<String, String>> lastSearchList = (List<Map<String, String>>) session.getAttribute("lastSearchList");
            if (lastSearchList == null) {
                lastSearchList = new ArrayList<>();
                session.setAttribute("lastSearchList", lastSearchList);
            }

            lastSearchList.removeIf(s -> s.get("id").equals(currentStaff.get("id")));
            lastSearchList.add(0, currentStaff); 

            if (lastSearchList.size() > 6) {
                lastSearchList.remove(6);
            }
            
            String sql = "SELECT Day_of_Week, Status, HOUR(Start_Time) AS startHour, HOUR(End_Time) AS endHour FROM Office_Hours WHERE Staff_ID = ?";
            
            if (rsDetails != null) rsDetails.close();
            if (pstmt != null) pstmt.close();
                        
            pstmt = conn.prepareStatement(sql);
            pstmt.setInt(1, staffId);
            rs = pstmt.executeQuery();
            
            while (rs.next()) {
                String day = rs.getString("Day_of_Week");
                String status = rs.getString("Status"); 
                
                int startHour = rs.getInt("startHour");
                int endHour = rs.getInt("endHour");
                
                String timeKey = startHour + "-" + endHour;

                int dayIndex = Arrays.asList(days).indexOf(day.toUpperCase());
                
                if (dayIndex != -1 && scheduleMap.containsKey(timeKey)) {
                    scheduleMap.get(timeKey)[dayIndex] = status;
                }
            }
            
            String sqlAppointments = "SELECT Appointment_Time_Slot, Day_of_Week FROM Appointments WHERE Staff_ID = ? AND Status = 'Confirmed' AND Appointment_Date = CURDATE()";
            
            if (rs != null) rs.close();
            if (pstmt != null) pstmt.close();

            pstmt = conn.prepareStatement(sqlAppointments);
            pstmt.setInt(1, staffId);
            rsAppointments = pstmt.executeQuery();

            while (rsAppointments.next()) {
                String bookedSlot = rsAppointments.getString("Appointment_Time_Slot");
                String bookedDay = rsAppointments.getString("Day_of_Week");

                int dayIndex = Arrays.asList(days).indexOf(bookedDay.toUpperCase());
                
                if (dayIndex != -1 && scheduleMap.containsKey(bookedSlot)) {
                    scheduleMap.get(bookedSlot)[dayIndex] = "Booked";
                }
            }

        } 
        
    } catch (SQLException e) {
        System.err.println("Database Error: Could not fetch staff data or process subscription. " + e.getMessage());
    } finally {
        if (rs != null) try { rs.close(); } catch (SQLException ignore) { /* ignore */ }
        if (rsDetails != null) try { rsDetails.close(); } catch (SQLException ignore) { /* ignore */ }
        if (rsAppointments != null) try { rsAppointments.close(); } catch (SQLException ignore) { /* ignore */ }
        if (pstmt != null) try { pstmt.close(); } catch (SQLException ignore) { /* ignore */ }
        DBConnection.closeConnection(conn);
    }
%>

<!DOCTYPE html>
<html lang="en">
<head>
    <style>
.class-slot { background-color: white !important; color: #0f3576 !important; font-weight: normal !important; cursor: default; }
.available-oh-slot { background-color: white !important; color: #0f3576 !important; font-weight: normal !important; cursor: pointer; }
td.booked-slot { background-color: #ADD8E6 !important; color: #0f3576 !important; font-weight: bold !important; cursor: default; }
.office-hours-table th { background-color: #0f3576 !important; color: white !important; }
.office-hours-table td { border: 1px solid #ddd !important; text-align: center; }

.notification-btn {
    border: none;
    background: none;
    color: var(--dark-blue); 
    cursor: pointer;
    transition: color 0.3s;
    outline: none;
}
.notification-btn .fas.fa-bell {
    display: none; 
    color: orange; 
}
.notification-btn.active .far.fa-bell {
    display: none; 
}
.notification-btn.active .fas.fa-bell {
    display: inline; 
}
.appointment-btn {
    display: inline-block;
    padding: 10px 20px;
    background-color: var(--dark-blue);
    color: white;
    text-decoration: none;
    border-radius: 5px;
    transition: background-color 0.3s;
}
.appointment-btn:hover {
    background-color: var(--light-skyblue);
}
</style>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Staff Profile - <%= staffName %></title>
    <link rel="stylesheet" href="/StudentServices1/css/style.css">
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.0.0-beta3/css/all.min.css">
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
        <div class="profile-container">
            <div class="profile-header">
               <div class="profile-name"> <%= staffName %> </div> 
                <p>Office No. <%= officeNo %></p>
                <p>Email: <%= email %></p>
                <p>Department: <%= departmentName %></p>
                
                <div style="text-align: center; margin-bottom: 20px; margin-top: 20px;">
                    <form method="POST" action="staff_profile.jsp?staffId=<%= staffId %>" style="margin: 0; display: inline;">
                        <input type="hidden" name="action" value="<%= isSubscribed ? "unsubscribe" : "subscribe" %>">
                        
                        <button type="submit" class="icon-btn notification-btn <%= isSubscribed ? "active" : "" %>" style="font-size: 2rem;"
                                title="<%= isSubscribed ? "Click to Unsubscribe" : "Click to Subscribe" %>">
                            <i class="far fa-bell"></i> 
                            <i class="fas fa-bell"></i> 
                        </button>
                        <p style="margin-top: 5px; font-size: 0.8rem; color: <%= isSubscribed ? "orange" : "#666" %>;">
                            <%= isSubscribed ? "Notifications Active" : "Click to Subscribe" %>
                        </p>
                    </form>
                </div>
            </div>

            <h3 style="color: var(--dark-blue); border-bottom: 2px solid var(--light-skyblue); padding-bottom: 5px; margin-bottom: 15px;">Office hours:</h3>
            <table class="office-hours-table">
                <thead>
                    <tr><th>TIME</th><th>SUNDAY</th><th>MONDAY</th><th>TUESDAY</th><th>WEDNESDAY</th><th>THURSDAY</th></tr>
                </thead>
                <tbody>
                    <% 
                        for (Map.Entry<String, String[]> entry : scheduleMap.entrySet()) {
                            String timeKey24Hour = entry.getKey(); 
                            String[] statuses = entry.getValue();
                            
                            String displayTime = timeKey24Hour; 
                            if (timeKey24Hour.equals("12-13")) {
                                displayTime = "12-1";
                            } else if (timeKey24Hour.equals("13-14")) {
                                displayTime = "1-2";
                            } else if (timeKey24Hour.equals("14-15")) {
                                displayTime = "2-3";
                            } else if (timeKey24Hour.equals("15-16")) {
                                displayTime = "3-4";
                            }
                    %>
                    <tr>
                        <td><%= displayTime %></td> 
                        <% 
                            for (String status : statuses) {
                                String cellClass = "";
                                String cellContent = "";
                                
                                if (status.equals("OH")) {
                                    cellClass = "available-oh-slot"; 
                                    cellContent = "OH";
                                } else if (status.equals("Class")) {
                                    cellClass = "class-slot"; 
                                    cellContent = "Class";
                                } else if (status.equals("Booked")) {
                                    cellClass = "booked-slot"; 
                                    cellContent = "OH"; 
                                } else {
                                    cellClass = ""; 
                                    cellContent = "";
                                }
                        %>
                        <td class="<%= cellClass %>"><%= cellContent %></td>
                        <% 
                            } 
                        %>
                    </tr>
                    <% } %>
                </tbody>
            </table>
            
            <div class="appointment-section">
                <p style="margin-bottom: 15px;">Do you want to make an appointment?</p>
                <a href="appointment_booking.jsp?staffId=<%= staffId %>" class="appointment-btn">Click here</a>
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