# Student Services Platform – Appointment & Notification System

A web application that simplifies communication between students and instructors: students can search for staff, view their office hours, book appointments, and subscribe to updates. Built as a team project for **CS378 – Introduction to Web Development** at Yanbu Industrial College.

📄 **[Full project report with screenshots](CS378_Report2.pdf)**

## Features

- **Secure login** with session-based authentication; protected pages redirect to login if there is no active session
- **Remembered email**: the login form auto-fills the student's email using a cookie (kept for one week, non-sensitive data only)
- **Search** for instructors by name or department
- **Department pages** listing staff with office number and contact info
- **Staff profile** with a weekly office-hours table (office hours vs. classes)
- **Appointment booking** on available office-hour slots
- **My Appointments** page showing each booking's status, with the option to cancel
- **Notifications**: subscribe to a staff member's office-hour updates, and unsubscribe at any time
- **Logout** with session invalidation

## Tech Stack

| Layer        | Technology                                  |
|--------------|---------------------------------------------|
| Presentation | JSP, HTML, CSS (Flexbox and Grid), Font Awesome |
| Logic        | Java, JDBC, HTTP Sessions and Cookies       |
| Database     | MySQL                                       |
| Server       | Apache Tomcat                               |
| IDE          | Eclipse                                     |

The system follows a **3-tier architecture**: presentation (JSP + CSS), logic (Java, JDBC, sessions, validation) and data (MySQL).

## Database Design

My role in the team was **Database Designer**. The schema in [`database.sql`](database.sql) has six related tables:

- `Departments` → `Staff` (one-to-many)
- `Staff` → `Office_Hours` (weekly schedule, unique per staff/day/start time to prevent duplicate slots)
- `Staff` → `Appointments` (status: Pending, Confirmed, Canceled)
- `Students` + `Staff` → `Notification_Subscriptions` (unique per student/staff pair)

All queries use `PreparedStatement`, and the app performs full CRUD:

- **Create**: book appointments, subscribe to notifications
- **Read**: staff lists, search results, office hours, appointments
- **Update**: appointment status
- **Delete**: cancel subscriptions

## Testing

| Scenario                                  | Expected Result         | Status |
|-------------------------------------------|-------------------------|--------|
| Valid login                               | Redirect to home page   | Passed |
| Invalid login                             | Show error message      | Passed |
| Cookie loaded                             | Email auto-filled       | Passed |
| Open protected page without a session     | Redirect to login       | Passed |
| Book an appointment                       | Stored in database      | Passed |
| Cancel subscription                       | Removed from database   | Passed |

Notable bugs fixed during development include a login query using the wrong password column, protected pages missing a session check, and the notifications page not filtering by the logged-in student's email. Details are in the report.

## Running Locally

1. Install MySQL and run `database.sql` to create the database with sample data.
2. Open `src/main/java/db/DBConnection.java` and set your MySQL username and password.
3. Import the project into Eclipse as a Dynamic Web Project and add an Apache Tomcat server.
4. Run on the server and open `student_login.jsp`.

## Project Structure

```
src/main/
├── java/db/DBConnection.java     # Database connection helper
└── webapp/
    ├── student_login.jsp         # Login with cookie auto-fill
    ├── student_logout.jsp        # Session invalidation
    ├── index.jsp                 # Home and search
    ├── department_view.jsp       # Staff by department
    ├── staff_profile.jsp         # Staff details and office hours
    ├── appointment_booking.jsp   # Book an appointment
    ├── student_appointments.jsp  # Student's bookings
    ├── notifications.jsp         # Active subscriptions
    └── css/style.css
```

## Future Improvements

Staff login, email reminders, more departments, language switching and dark mode.

## Team

- **Amjad Baali** – Database Designer
- **Wafa** – Front-End Developer
- **Sarah** – Back-End Developer

> Sample data in `database.sql` is fictional.
