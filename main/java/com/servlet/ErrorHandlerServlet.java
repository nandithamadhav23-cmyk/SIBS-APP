package com.servlet;

import java.io.IOException;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;

/**
 * Smart error redirect servlet. Redirects to the correct section based on
 * session role + requested URI. Customers are NEVER sent to index.jsp — always
 * to /Customer.
 */
@WebServlet("/ErrorHandlerServlet")
public class ErrorHandlerServlet extends HttpServlet {

	private static final long serialVersionUID = 1L;

	@Override
	protected void service(HttpServletRequest request, HttpServletResponse response)
			throws ServletException, IOException {

		String uri = (String) request.getAttribute("jakarta.servlet.error.request_uri");
		if (uri == null) {
			uri = "";
		}
		String lowerUri = uri.toLowerCase();
		String ctx = request.getContextPath();

		HttpSession session = request.getSession(false);
		boolean isCustomer = false;
		boolean isStaff = false;
		boolean isDelivery = false;

		if (session != null) {
			Boolean loggedIn = (Boolean) session.getAttribute("loggedIn");
			Object customer = session.getAttribute("customer");
			String role = (String) session.getAttribute("role");
			Object user = session.getAttribute("user");

			isCustomer = Boolean.TRUE.equals(loggedIn) && customer != null;
			isStaff = user != null && ("staff".equalsIgnoreCase(role) || "admin".equalsIgnoreCase(role))
					&& !("customer".equalsIgnoreCase(role));
			isDelivery = session.getAttribute("deliveryPerson") != null;
		}

		// Smart redirect: never drop a customer at homepage
		if (isCustomer || lowerUri.contains("customer") || lowerUri.contains("cartservlet")
				|| lowerUri.contains("trackorderservlet") || lowerUri.contains("wishlist")
				|| lowerUri.contains("invoiceservlet") || lowerUri.contains("checkout")
				|| lowerUri.contains("placeorderervlet") || lowerUri.contains("payment")) {

			response.sendRedirect(ctx + "/Customer");

		} else if (isDelivery || lowerUri.contains("delivery")) {
			response.sendRedirect(ctx + "/deliveryLogin.jsp");

		} else if (isStaff || lowerUri.contains("admin") || lowerUri.contains("staff")) {
			response.sendRedirect(ctx + "/dashboard.jsp");

		} else {
			// Final fallback — still prefer customer dashboard if logged in
			if (session != null && Boolean.TRUE.equals(session.getAttribute("loggedIn"))) {
				response.sendRedirect(ctx + "/Customer");
			} else {
				response.sendRedirect(ctx + "/index.jsp");
			}
		}
	}
}
