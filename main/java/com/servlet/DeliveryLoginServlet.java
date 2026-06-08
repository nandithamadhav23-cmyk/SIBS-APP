package com.servlet;

import java.io.IOException;
import java.sql.Connection;
import java.util.logging.Level;
import java.util.logging.Logger;

import com.DAO.AgentWalletDAO;
import com.DAO.DeliveryPersonDAO;
import com.DAO.DeliveryRegistrationDAO;
import com.util.DBConnection;
import com.util.DeliveryRegistration;
import com.util.User;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;

@WebServlet("/DeliveryLoginServlet")
public class DeliveryLoginServlet extends HttpServlet {

	private static final long serialVersionUID = 1L;
	private static final Logger log = Logger.getLogger(DeliveryLoginServlet.class.getName());

	@Override
	protected void doGet(HttpServletRequest request, HttpServletResponse response)
			throws ServletException, IOException {

		// If already logged in, skip login page and go straight to portal
		HttpSession existing = request.getSession(false);
		if (existing != null && existing.getAttribute("deliveryUser") != null) {
			response.sendRedirect(request.getContextPath() + "/DeliveryPortalServlet");
			return;
		}

		// Pass registration outcome param to JSP for success/info banners
		// ?registered=1 → show "Registration submitted, pending admin review"
		String registered = request.getParameter("registered");
		if ("1".equals(registered)) {
			request.setAttribute("registrationMsg",
					"Registration submitted successfully! Your application is now pending admin review. "
							+ "You will be able to log in once your account is approved.");
		}

		request.getRequestDispatcher("deliveryLogin.jsp").forward(request, response);
	}

	@Override
	protected void doPost(HttpServletRequest request, HttpServletResponse response)
			throws ServletException, IOException {

		String username = request.getParameter("username");
		String password = request.getParameter("password");

		if (username == null || username.isBlank() || password == null || password.isBlank()) {
			request.setAttribute("errorMsg", "Username and password are required.");
			request.setAttribute("errorType", "EMPTY");
			request.getRequestDispatcher("deliveryLogin.jsp").forward(request, response);
			return;
		}

		try (Connection conn = DBConnection.getConnection()) {
			DeliveryPersonDAO dao = new DeliveryPersonDAO(conn);
			DeliveryRegistrationDAO regDao = new DeliveryRegistrationDAO(conn);

			// ── Step 1: Check if the username exists in the registration table at all ──
			// This lets us give a precise message rather than a generic "wrong
			// credentials".
			DeliveryRegistration reg = regDao.getByUsername(username.trim());

			if (reg != null) {
				String status = reg.getStatus(); // PENDING | APPROVED | REJECTED

				if ("PENDING".equalsIgnoreCase(status)) {
					// Account exists but admin hasn't reviewed it yet
					request.setAttribute("errorType", "PENDING");
					request.setAttribute("errorMsg", "Your registration is currently under review. "
							+ "Please wait for admin approval before logging in.");
					request.getRequestDispatcher("deliveryLogin.jsp").forward(request, response);
					return;
				}

				if ("REJECTED".equalsIgnoreCase(status)) {
					// Account was explicitly rejected by admin
					String remarks = reg.getAdminRemarks();
					String rejectMsg = "Your registration application has been rejected by the administrator.";
					if (remarks != null && !remarks.isBlank()) {
						rejectMsg += " Reason: " + remarks;
					}
					rejectMsg += " Please contact support or register again with correct information.";
					request.setAttribute("errorType", "REJECTED");
					request.setAttribute("errorMsg", rejectMsg);
					request.getRequestDispatcher("deliveryLogin.jsp").forward(request, response);
					return;
				}

				// Status is APPROVED — attempt actual credential check
				if ("APPROVED".equalsIgnoreCase(status)) {
					User user = dao.validateDeliveryUser(username.trim(), password);

					if (user != null) {
						// ── Successful login ────────────────────────────────────────
						// Fix: Invalidate old session before creating new one
						HttpSession oldSession = request.getSession(false);
						if (oldSession != null) {
							oldSession.invalidate();
						}

						HttpSession session = request.getSession(true);
						session.setAttribute("deliveryUser", user);
						// Delivery agents work shifts up to 16hrs (FULL_DAY).
						// Global web.xml session-timeout=60min would expire mid-shift.
						// Override to 10 hours per session so the slot is never orphaned.
						session.setMaxInactiveInterval(36000);

						// Pre-init wallet so portal doesn't 500 on missing wallet row
						try {
							new AgentWalletDAO().getWallet(user.getUid());
						} catch (Exception walletEx) {
							log.warning("Could not pre-init wallet for agent #" + user.getUid() + ": "
									+ walletEx.getMessage());
						}

						log.info("Login success: agent #" + user.getUid() + " (" + user.getUsername() + ")");
						response.sendRedirect(request.getContextPath() + "/DeliveryPortalServlet");
						return;

					} else {
						// APPROVED account but wrong password
						request.setAttribute("errorType", "WRONG_PASSWORD");
						request.setAttribute("errorMsg",
								"Incorrect password. Please try again or contact support if you've forgotten it.");
						request.getRequestDispatcher("deliveryLogin.jsp").forward(request, response);
						return;
					}
				}
			} else {
				// ── No entry in delivery_registration table ──────────────────────
				// This happens when the admin adds a delivery agent directly through
				// the admin panel — those agents are inserted straight into the users
				// table and have no registration record. We must still validate their
				// credentials via validateDeliveryUser() before allowing login.
				User directUser = dao.validateDeliveryUser(username.trim(), password);

				if (directUser != null) {
					// ── Successful login (admin-added agent) ─────────────────────
					HttpSession oldSession = request.getSession(false);
					if (oldSession != null) {
						oldSession.invalidate();
					}
					HttpSession session = request.getSession(true);
					session.setAttribute("deliveryUser", directUser);
					session.setMaxInactiveInterval(36000);
					try {
						new AgentWalletDAO().getWallet(directUser.getUid());
					} catch (Exception walletEx) {
						log.warning("Could not pre-init wallet for agent #" + directUser.getUid() + ": "
								+ walletEx.getMessage());
					}
					log.info("Login success (admin-added): agent #" + directUser.getUid() + " ("
							+ directUser.getUsername() + ")");
					response.sendRedirect(request.getContextPath() + "/DeliveryPortalServlet");
					return;

				} else {
					// username not in users table either → truly unknown
					// BUT: validateDeliveryUser returns null for both "username not found"
					// and "wrong password". To show the right message we check whether
					// the username exists in users at all (regardless of password).
					boolean usernameExistsInUsers = dao.deliveryUsernameExists(username.trim());
					if (usernameExistsInUsers) {
						// Username found in users table but password was wrong
						request.setAttribute("errorType", "WRONG_PASSWORD");
						request.setAttribute("errorMsg",
								"Incorrect password. Please try again or contact support if you've forgotten it.");
					} else {
						// Username exists in neither table → truly not registered
						log.warning("Login attempt for unknown username: " + username);
						request.setAttribute("errorType", "NOT_FOUND");
						request.setAttribute("errorMsg", "No account found with that username. "
								+ "If you are a new delivery agent, please register first.");
					}
					request.getRequestDispatcher("deliveryLogin.jsp").forward(request, response);
				}
			}

		} catch (Exception e) {
			log.log(Level.SEVERE, "Login error for username: " + username, e);
			request.setAttribute("errorType", "SERVER_ERROR");
			request.setAttribute("errorMsg", "A server error occurred. Please try again.");
			request.getRequestDispatcher("deliveryLogin.jsp").forward(request, response);
		}
	}
}