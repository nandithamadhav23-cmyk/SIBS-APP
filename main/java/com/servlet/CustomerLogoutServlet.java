package com.servlet;

import java.io.IOException;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;

@WebServlet("/CustomerLogout")
public class CustomerLogoutServlet extends HttpServlet {
	/**
	 * 
	 */
	private static final long serialVersionUID = 1L;

	@Override
	protected void doGet(HttpServletRequest request, HttpServletResponse response)
			throws ServletException, IOException {

		HttpSession session = request.getSession(false);
		if (session != null) {
			// Capture role before invalidating
			String role = (String) session.getAttribute("role");

			// Remove customer-specific attributes
			session.removeAttribute("customerId");
			session.removeAttribute("username");
			session.removeAttribute("customer");
			session.removeAttribute("loggedIn");

			// Invalidate session
			session.invalidate();
			System.out.println("[LogoutServlet] Session cleared.");

			// Redirect based on role
			if ("customer".equalsIgnoreCase(role)) {
				System.out.println("[LogoutServlet] Redirecting to customer dashboard.");
				response.sendRedirect("customerDashboard.jsp");
				return;
			}
		}

		// Default redirect to homepage
		response.sendRedirect("customerDashboard.jsp");
	}
}
