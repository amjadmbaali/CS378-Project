package db;

import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.SQLException;

public class DBConnection {

    private static final String JDBC_URL = "jdbc:mysql://localhost:3306/StudentServicesDB";
    private static final String DB_USER = "root"; 
    
    private static final String DB_PASS = "your_password"; 

    
    public static Connection getConnection() {
        Connection conn = null;
        try {

        	Class.forName("com.mysql.cj.jdbc.Driver");
            
            conn = DriverManager.getConnection(JDBC_URL, DB_USER, DB_PASS);
            
        } catch (ClassNotFoundException e) {
            System.err.println("Error: MySQL JDBC Driver not found. Please add the Connector JAR to WEB-INF/lib.");
            e.printStackTrace();
        } catch (SQLException e) {
            System.err.println("Error: Database connection failed! Check if MySQL server is running.");
            e.printStackTrace();
        }
        return conn;
    }


    public static void closeConnection(Connection conn) {
        if (conn != null) {
            try {
                conn.close();
            } catch (SQLException e) {
                e.printStackTrace();
            }
        }
    }
}