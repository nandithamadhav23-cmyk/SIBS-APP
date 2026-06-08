package com.servlet;

import java.io.IOException;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;

import com.util.DBConnection;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;

@WebServlet("/DeleteUserServlet")
public class DeleteUserServlet extends HttpServlet {
	@Override
	protected void doPost(HttpServletRequest request, HttpServletResponse response)
			throws ServletException, IOException {
		String username = request.getParameter("username");
		String loggedInRole = (String) request.getSession().getAttribute("role");

		try (Connection con = DBConnection.getConnection();
				PreparedStatement psCheck = con.prepareStatement("SELECT role FROM users WHERE username=?")) {
			psCheck.setString(1, username);
			ResultSet rs = psCheck.executeQuery();
			if (rs.next()) {
				String targetRole = rs.getString("role");

				// Rule: only admins can delete admins
				if ("admin".equalsIgnoreCase(targetRole) && !"admin".equalsIgnoreCase(loggedInRole)) {
					response.sendRedirect("userList.jsp?error=Only admins can delete admin accounts");
					return;
				}
			}
		} catch (Exception e) {
			e.printStackTrace();
			response.sendRedirect("userList.jsp?error=Error checking role");
			return;
		}

		try (Connection con = DBConnection.getConnection();
				PreparedStatement ps = con.prepareStatement("DELETE FROM users WHERE username=?")) {
			ps.setString(1, username);
			int deleted = ps.executeUpdate();
			if (deleted > 0) {
				response.sendRedirect("userList.jsp?msg=User deleted successfully");
			} else {
				response.sendRedirect("userList.jsp?error=Delete failed");
			}
		} catch (Exception e) {
			e.printStackTrace();
			response.sendRedirect("userList.jsp?error=Database error");
		}
	}
}
