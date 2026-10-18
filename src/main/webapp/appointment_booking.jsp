<%@page import="db.DBConnection"%>
<%@page import="java.sql.*"%>
<%@page import="java.util.*"%>
<%@page import="java.text.SimpleDateFormat"%>
<%@page contentType="text/html" pageEncoding="UTF-8"%>

<%
    String staffIdStr = request.getParameter("staffId");
    int staffId = 0;
    if (staffIdStr != null) {
        try {
            staffId = Integer.parseInt(staffIdStr);
        } catch (NumberFormatException e) {
        }
    }

    String studentEmail = (String) session.getAttribute("studentEmail");
    String studentName = (String) session.getAttribute("studentName"); 

    if (studentEmail == null) {
        response.sendRedirect("student_login.jsp");
        return;
    }
    
    String staffName = "Staff Member"; 
    String successMessage = "";
    String errorMessage = "";

    request.setCharacterEncoding("UTF-8");
    response.setCharacterEncoding("UTF-8");

    if ("POST".equalsIgnoreCase(request.getMethod())) {
        
        String appointmentDay = request.getParameter("appointmentDay");
        String appointmentTime = request.getParameter("appointmentTime");

        Connection insertConn = null;
        PreparedStatement insertPstmt = null;

        try {
            insertConn = DBConnection.getConnection();
            
            String insertSql = "INSERT INTO Appointments " +
                    "(Staff_ID, Student_Name, Student_Email, Appointment_Date, Appointment_Time_Slot, Status, Day_of_Week) " +
                    "VALUES (?, ?, ?, CURDATE(), ?, 'Confirmed', ?)";
                    
            insertPstmt = insertConn.prepareStatement(insertSql);
            
            // 1. Staff_ID
            insertPstmt.setInt(1, staffId);
            // 2. Student_Name
            insertPstmt.setString(2, studentName);
            // 3. Student_Email 
            insertPstmt.setString(3, studentEmail); 
            // 4. Appointment_Time_Slot
            insertPstmt.setString(4, appointmentTime);
            // 5. Day_of_Week
            insertPstmt.setString(5, appointmentDay);

            int rowsAffected = insertPstmt.executeUpdate();

            if (rowsAffected > 0) {
                successMessage = "Appointment successfully booked! You can view it in My Appointments.";
            } else {
                errorMessage = "Booking failed. Please try again.";
            }

        } catch (SQLException e) {
            errorMessage = "Error saving appointment: " + e.getMessage();
        } finally {
            if (insertPstmt != null) try { insertPstmt.close(); } catch (SQLException ignore) {}
            DBConnection.closeConnection(insertConn);
        }
    }

    Map<String, List<String>> availableSlots = new LinkedHashMap<>();

    Connection conn = null;
    PreparedStatement pstmt = null;
    ResultSet rs = null;
    ResultSet rsDetails = null;

    try {
        conn = DBConnection.getConnection();

        String sqlName = "SELECT Staff_Name FROM Staff WHERE Staff_ID = ?";
        pstmt = conn.prepareStatement(sqlName);
        pstmt.setInt(1, staffId);
        rsDetails = pstmt.executeQuery();
        if (rsDetails.next()) {
            staffName = rsDetails.getString("Staff_Name");
        }

        String sqlSlots = "SELECT Day_of_Week, HOUR(Start_Time) AS startHour, HOUR(End_Time) AS endHour FROM Office_Hours oh " +
                "WHERE oh.Staff_ID = ? AND oh.Status = 'OH' AND NOT EXISTS (" +
                "SELECT 1 FROM Appointments a WHERE a.Staff_ID = oh.Staff_ID AND a.Appointment_Time_Slot = CONCAT(HOUR(oh.Start_Time), '-', HOUR(oh.End_Time)) " +
                "AND a.Day_of_Week = oh.Day_of_Week AND a.Appointment_Date = CURDATE() AND a.Status = 'Confirmed')";

        pstmt = conn.prepareStatement(sqlSlots);
        pstmt.setInt(1, staffId);
        rs = pstmt.executeQuery();

        while (rs.next()) {
            String day = rs.getString("Day_of_Week");
            int startHour = rs.getInt("startHour");
            int endHour = rs.getInt("endHour");

            String displayTime = startHour > 12 ? (startHour - 12) + " PM" : startHour + " AM";
            String slotKey = startHour + "-" + endHour;

            availableSlots.computeIfAbsent(day, k -> new ArrayList<>())
                    .add(slotKey + " (" + displayTime + " - " + (endHour > 12 ? (endHour - 12) + " PM" : endHour + " AM") + ")");
        }

    } catch (SQLException e) {
        errorMessage = "Error fetching available slots: " + e.getMessage();
    } finally {
        if (rs != null) try { rs.close(); } catch (SQLException ignore) {}
        if (rsDetails != null) try { rsDetails.close(); } catch (SQLException ignore) {}
        if (pstmt != null) try { pstmt.close(); } catch (SQLException ignore) {}
        DBConnection.closeConnection(conn);
    }
%>

<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Book Appointment - <%= staffName %></title>
    <link rel="stylesheet" href="/StudentServices1/css/style.css">
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.0.0-beta3/css/all.min.css">
</head>
<body>
<div class="content-area">
    <h2 class="last-search-title" style="text-align: center;">Book Appointment with <%= staffName %></h2>

    <div class="appointment-form">
        <% if (!successMessage.isEmpty()) { %>
            <p style="color: green; font-weight: bold; margin-bottom: 15px;"><%= successMessage %></p>
        <% } else if (!errorMessage.isEmpty()) { %>
            <p style="color: red; font-weight: bold; margin-bottom: 15px;"><%= errorMessage %></p>
        <% } %>

        <form action="appointment_booking.jsp?staffId=<%= staffId %>" method="POST">
            
            <div class="form-group">
                <label for="studentName">Student Name:</label>
                <p style="font-weight: bold; color: var(--text-color);"><%= studentName %></p>
                <input type="hidden" name="studentName" value="<%= studentName %>">
            </div>

            <div class="form-group">
                <label for="appointmentDay">Day:</label>
                <select id="appointmentDay" name="appointmentDay" required>
                    <option value="" disabled selected>Select Day</option>
                    <% for (String day : availableSlots.keySet()) { %>
                        <option value="<%= day %>"><%= day %></option>
                    <% } %>
                </select>
            </div>

            <div class="form-group">
                <label for="appointmentTime">Time Slot:</label>
                <select id="appointmentTime" name="appointmentTime" required>
                    <option value="" disabled selected>Select Time Slot (Choose Day First)</option>
                </select>
            </div>

            <p style="text-align: center; margin-top: 30px; font-weight: bold;">Do you want to save the changes?</p>

            <div class="form-actions">
                <a href="staff_profile.jsp?staffId=<%= staffId %>" class="back-btn">Back to Home page</a>
                <button type="submit" class="save-btn">Yes</button>
            </div>
        </form>
    </div>
</div>

<script>
    var availableSlots = {};
    <% for (Map.Entry<String, List<String>> entry : availableSlots.entrySet()) { %>
        availableSlots["<%= entry.getKey() %>"] = [
        <% for (int i = 0; i < entry.getValue().size(); i++) { 
                String slot = entry.getValue().get(i);
        %>
            "<%= slot.replace("\"", "\\\"") %>"<%= (i < entry.getValue().size() - 1) ? "," : "" %>
        <% } %>
        ];
    <% } %>

    var daySelect = document.getElementById("appointmentDay");
    var timeSelect = document.getElementById("appointmentTime");

    daySelect.addEventListener("change", function() {
        var selectedDay = this.value;

        timeSelect.innerHTML = '<option value="" disabled selected>Select Time Slot</option>';

        if (availableSlots[selectedDay]) {
            availableSlots[selectedDay].forEach(function(slot) {
                var slotValue = slot.split(" ")[0];
                var option = document.createElement("option");
                option.value = slotValue;
                option.textContent = slot;
                timeSelect.appendChild(option);
            });
        }
    });
</script>
</body>
</html>