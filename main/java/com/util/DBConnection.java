package com.util;

import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.SQLException;

public class DBConnection {

	public static Connection getConnection() throws SQLException {
		String URL = "jdbc:mysql://localhost:3306/myapp?tinyInt1isBit=false";
		String USER = "root";
		String PASSWORD = "Nandu23@";
		try {
			Class.forName("com.mysql.cj.jdbc.Driver");

		} catch (ClassNotFoundException e) {
			e.printStackTrace();
		}

		Connection conn = DriverManager.getConnection(URL, USER, PASSWORD);
		System.out.println("✅ Database connection established: " + conn);
		return conn;

	}
}
