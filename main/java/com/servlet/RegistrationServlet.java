package com.servlet;

import java.io.IOException;

import com.DAO.UserDAO;
import com.util.User;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;

@WebServlet("/register")
public class RegistrationServlet extends HttpServlet {
	/**
	 * 
	 */
	private static final long serialVersionUID = -9015380634446831696L;

	@Override
	protected void doPost(HttpServletRequest request, HttpServletResponse response)
			throws ServletException, IOException {

		UserDAO dao = new UserDAO();

		// Prevent multiple admins
		if (dao.checkIfAdminExists()) {
			request.setAttribute("status", "error");
			request.setAttribute("message", "Admin already exists. You cannot register another admin.");
			request.getRequestDispatcher("index.jsp").forward(request, response);
			return;
		}

		// Collect form data
		String username = request.getParameter("username");
		String password = request.getParameter("password");
		String email = request.getParameter("email");
		String gender = request.getParameter("gender");
		String adminLevel = request.getParameter("adminLevel"); // new field
		String privileges = request.getParameter("privileges"); // new field

		User admin = new User();
		admin.setUsername(username);
		admin.setPassword(password);
		admin.setEmail(email);
		admin.setRole("admin");
		admin.setStatus("active");
		admin.setGender(gender);
		admin.setAdminLevel(adminLevel);
		admin.setPrivileges(privileges);

		boolean success = dao.registerAdmin(admin);

		if (success) {
			request.setAttribute("status", "success");
			request.setAttribute("message", "Admin registered successfully!");
		} else {
			request.setAttribute("status", "error");
			request.setAttribute("message", "Admin registration failed.");
		}
		request.getRequestDispatcher("index.jsp").forward(request, response);
	}

}
