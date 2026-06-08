package com.servlet;

import java.io.IOException;

import com.DAO.UserDAO;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;

@WebServlet("/home")
public class HomeServlet extends HttpServlet {
	@Override
	protected void doGet(HttpServletRequest request, HttpServletResponse response)
			throws ServletException, IOException {

		System.out.println("=== HomeServlet called ===");

		HttpSession session = request.getSession(false);
		String role = (session != null) ? (String) session.getAttribute("role") : null;

		UserDAO dao = new UserDAO();
		boolean adminExists = dao.checkIfAdminExists();

		System.out.println("Role from session: " + role);
		System.out.println("Admin exists in admin table? " + adminExists);

		request.setAttribute("role", role);
		request.setAttribute("adminExists", adminExists);

		request.getRequestDispatcher("index.jsp").forward(request, response);
	}
}
