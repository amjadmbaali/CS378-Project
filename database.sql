-- Student Services Appointment System
-- Database schema with sample (fictional) data
-- MySQL 8+

CREATE DATABASE IF NOT EXISTS StudentServicesDB;
USE StudentServicesDB;

SET FOREIGN_KEY_CHECKS = 0;
DROP TABLE IF EXISTS Notification_Subscriptions;
DROP TABLE IF EXISTS Appointments;
DROP TABLE IF EXISTS Office_Hours;
DROP TABLE IF EXISTS Students;
DROP TABLE IF EXISTS Staff;
DROP TABLE IF EXISTS Departments;
SET FOREIGN_KEY_CHECKS = 1;

-- --------------------------------------------------------
-- Departments
-- --------------------------------------------------------
CREATE TABLE Departments (
  Dept_ID   INT NOT NULL AUTO_INCREMENT,
  Dept_Name VARCHAR(100) NOT NULL,
  PRIMARY KEY (Dept_ID),
  UNIQUE KEY Dept_Name (Dept_Name)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- --------------------------------------------------------
-- Staff
-- --------------------------------------------------------
CREATE TABLE Staff (
  Staff_ID      INT NOT NULL AUTO_INCREMENT,
  Dept_ID       INT NOT NULL,
  Staff_Name    VARCHAR(150) NOT NULL,
  Email         VARCHAR(150) NOT NULL,
  Office_No     VARCHAR(20) DEFAULT NULL,
  Password_Hash VARCHAR(255) NOT NULL,
  Role          ENUM('Staff','Admin') NOT NULL DEFAULT 'Staff',
  PRIMARY KEY (Staff_ID),
  UNIQUE KEY Email (Email),
  KEY Dept_ID (Dept_ID),
  CONSTRAINT staff_ibfk_1 FOREIGN KEY (Dept_ID) REFERENCES Departments (Dept_ID)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- --------------------------------------------------------
-- Students
-- --------------------------------------------------------
CREATE TABLE Students (
  Student_ID    INT NOT NULL AUTO_INCREMENT,
  Student_Name  VARCHAR(150) NOT NULL,
  Email         VARCHAR(150) NOT NULL,
  Password_Hash VARCHAR(255) NOT NULL,
  PRIMARY KEY (Student_ID),
  UNIQUE KEY Email (Email)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- --------------------------------------------------------
-- Office_Hours: weekly schedule per staff member
-- --------------------------------------------------------
CREATE TABLE Office_Hours (
  OH_ID       INT NOT NULL AUTO_INCREMENT,
  Staff_ID    INT NOT NULL,
  Day_of_Week ENUM('SUNDAY','MONDAY','TUESDAY','WEDNESDAY','THURSDAY') NOT NULL,
  Start_Time  TIME NOT NULL,
  End_Time    TIME NOT NULL,
  Status      ENUM('OH','Class','Unavailable') NOT NULL,
  PRIMARY KEY (OH_ID),
  UNIQUE KEY Staff_ID (Staff_ID, Day_of_Week, Start_Time),
  CONSTRAINT office_hours_ibfk_1 FOREIGN KEY (Staff_ID) REFERENCES Staff (Staff_ID)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- --------------------------------------------------------
-- Appointments
-- --------------------------------------------------------
CREATE TABLE Appointments (
  Appointment_ID        INT NOT NULL AUTO_INCREMENT,
  Staff_ID              INT NOT NULL,
  Student_ID            VARCHAR(20) DEFAULT NULL,
  Student_Name          VARCHAR(150) DEFAULT NULL,
  Student_Email         VARCHAR(150) DEFAULT NULL,
  Appointment_Date      DATE NOT NULL,
  Appointment_Time_Slot VARCHAR(50) NOT NULL,
  Status                ENUM('Pending','Confirmed','Canceled') NOT NULL DEFAULT 'Pending',
  Day_of_Week           ENUM('SUNDAY','MONDAY','TUESDAY','WEDNESDAY','THURSDAY') NOT NULL,
  PRIMARY KEY (Appointment_ID),
  KEY Staff_ID (Staff_ID),
  CONSTRAINT appointments_ibfk_1 FOREIGN KEY (Staff_ID) REFERENCES Staff (Staff_ID)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- --------------------------------------------------------
-- Notification_Subscriptions: students following a staff member
-- --------------------------------------------------------
CREATE TABLE Notification_Subscriptions (
  ID            INT NOT NULL AUTO_INCREMENT,
  Student_Email VARCHAR(150) NOT NULL,
  Staff_ID      INT NOT NULL,
  Status        VARCHAR(20) DEFAULT 'Inactive',
  PRIMARY KEY (ID),
  UNIQUE KEY unique_subscription (Student_Email, Staff_ID),
  KEY Staff_ID (Staff_ID),
  CONSTRAINT notification_subscriptions_ibfk_1 FOREIGN KEY (Student_Email) REFERENCES Students (Email),
  CONSTRAINT notification_subscriptions_ibfk_2 FOREIGN KEY (Staff_ID) REFERENCES Staff (Staff_ID)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- ========================================================
-- Sample data (fictional)
-- ========================================================

INSERT INTO Departments (Dept_ID, Dept_Name) VALUES
(1, 'CSE'), (2, 'Math'), (3, 'Design'), (4, 'English'), (5, 'Student Guidance');

INSERT INTO Staff (Staff_ID, Dept_ID, Staff_Name, Email, Office_No, Password_Hash, Role) VALUES
(1, 1, 'Dr. Sample One',   'staff1@example.com', 'A1-101', 'change_me', 'Staff'),
(2, 2, 'Ms. Sample Two',   'staff2@example.com', 'A1-102', 'change_me', 'Staff'),
(3, 4, 'Ms. Sample Three', 'staff3@example.com', 'B1-201', 'change_me', 'Staff'),
(4, 5, 'Admin User',       'admin@example.com',  'B1-202', 'change_me', 'Admin');

INSERT INTO Students (Student_ID, Student_Name, Email, Password_Hash) VALUES
(1, 'Student A', 'student.a@example.com', 'change_me'),
(2, 'Student B', 'student.b@example.com', 'change_me');

INSERT INTO Office_Hours (Staff_ID, Day_of_Week, Start_Time, End_Time, Status) VALUES
(1, 'SUNDAY',    '08:00:00', '09:00:00', 'Class'),
(1, 'SUNDAY',    '09:00:00', '10:00:00', 'OH'),
(1, 'SUNDAY',    '10:00:00', '11:00:00', 'OH'),
(1, 'MONDAY',    '09:00:00', '10:00:00', 'Class'),
(1, 'MONDAY',    '12:00:00', '13:00:00', 'OH'),
(1, 'TUESDAY',   '09:00:00', '10:00:00', 'OH'),
(1, 'WEDNESDAY', '13:00:00', '14:00:00', 'OH'),
(1, 'THURSDAY',  '08:00:00', '09:00:00', 'OH'),
(2, 'SUNDAY',    '08:00:00', '09:00:00', 'OH'),
(2, 'MONDAY',    '10:00:00', '11:00:00', 'OH'),
(2, 'TUESDAY',   '12:00:00', '13:00:00', 'OH'),
(3, 'WEDNESDAY', '09:00:00', '10:00:00', 'OH'),
(3, 'THURSDAY',  '13:00:00', '14:00:00', 'OH');

INSERT INTO Appointments (Staff_ID, Student_Name, Student_Email, Appointment_Date, Appointment_Time_Slot, Status, Day_of_Week) VALUES
(1, 'Student A', 'student.a@example.com', '2025-11-23', '9-10',  'Confirmed', 'SUNDAY'),
(2, 'Student A', 'student.a@example.com', '2025-11-24', '10-11', 'Pending',   'MONDAY'),
(1, 'Student B', 'student.b@example.com', '2025-11-25', '9-10',  'Canceled',  'TUESDAY');

INSERT INTO Notification_Subscriptions (Student_Email, Staff_ID, Status) VALUES
('student.a@example.com', 1, 'Active'),
('student.b@example.com', 2, 'Active');
