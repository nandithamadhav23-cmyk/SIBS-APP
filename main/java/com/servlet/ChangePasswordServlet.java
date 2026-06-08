package com.servlet;

import java.io.IOException;

import com.DAO.CustomerDAO;
import com.util.Customer;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;

@WebServlet("/ChangePasswordServlet")
public class ChangePasswordServlet extends HttpServlet {

	private static final long serialVersionUID = 1L;
	private CustomerDAO customerDAO;

	@Override
	public void init() {
		customerDAO = new CustomerDAO();
	}

	@Override
	protected void doPost(HttpServletRequest req, HttpServletResponse res) throws ServletException, IOException {
		int customerId = Integer.parseInt(req.getParameter("customerId"));
		String oldPassword = req.getParameter("oldPassword");
		String newPassword = req.getParameter("newPassword");
		String confirmPassword = req.getParameter("confirmPassword");

		// ── Validation ──────────────────────────────────────────────────────
		if (newPassword == null || newPassword.isBlank()) {
			req.getSession().setAttribute("pwdMessage", "New password cannot be empty.");
			req.getSession().setAttribute("pwdSuccess", false);
			res.sendRedirect("CustomerProfile?section=settings");
			return;
		}
		if (!newPassword.equals(confirmPassword)) {
			req.getSession().setAttribute("pwdMessage", "New passwords do not match.");
			req.getSession().setAttribute("pwdSuccess", false);
			res.sendRedirect("CustomerProfile?section=settings");
			return;
		}
		if (newPassword.length() < 8) {
			req.getSession().setAttribute("pwdMessage", "Password must be at least 8 characters.");
			req.getSession().setAttribute("pwdSuccess", false);
			res.sendRedirect("CustomerProfile?section=settings");
			return;
		}

		try {
			// Validate old password via login check
			Customer c = customerDAO.getProfile(customerId);
			int validId = customerDAO.validateLogin(c.getEmail(), oldPassword);

			if (validId == customerId) {
				// Update password (pass new password; other fields kept)
				customerDAO.updateProfile(customerId, c.getName(), c.getEmail(), c.getPhone(), c.getLandmark_street(),
						c.getCity(), c.getDistrict(), c.getState(), c.getCountry(), c.getPincode(), newPassword,
						c.getGender());
				req.getSession().setAttribute("pwdMessage", "Password updated successfully!");
				req.getSession().setAttribute("pwdSuccess", true);
			} else {
				req.getSession().setAttribute("pwdMessage", "Current password is incorrect.");
				req.getSession().setAttribute("pwdSuccess", false);
			}
			// BUG FIX: redirect to customer profile, not staff profile.jsp
			res.sendRedirect("CustomerProfile?section=settings");

		} catch (Exception e) {
			e.printStackTrace();
			req.getSession().setAttribute("pwdMessage", "An error occurred: " + e.getMessage());
			req.getSession().setAttribute("pwdSuccess", false);
			res.sendRedirect("CustomerProfile?section=settings");
		}
	}
}
