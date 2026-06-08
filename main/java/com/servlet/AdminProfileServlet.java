package com.servlet;

import java.io.IOException;
import java.util.logging.Logger;

import com.DAO.UserDAO;
import com.util.User;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;

/**
 * AdminProfileServlet — serves the admin profile fragment used inside
 * dashboard.jsp. GET /AdminProfile → loads user from DB and forwards to
 * adminProfileFragment.jsp POST /AdminProfile → handles updateProfile and
 * changePassword actions, then redirects back
 */
@WebServlet("/AdminProfile")
public class AdminProfileServlet extends HttpServlet {

	private static final Logger logger = Logger.getLogger(AdminProfileServlet.class.getName());

	@Override
	protected void doGet(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {

		HttpSession session = req.getSession(false);
		if (session == null || !"admin".equalsIgnoreCase((String) session.getAttribute("role"))) {
			resp.sendRedirect(req.getContextPath() + "/index.jsp?error=Access+denied.");
			return;
		}

		String uname = (String) session.getAttribute("username");
		UserDAO dao = new UserDAO();
		User user = dao.getUserByUsername(uname);
		if (user != null) {
			logger.info("user Role: " + user.getRole() + " username: " + user.getUsername());
			req.setAttribute("user", user);
		} else {
			logger.warning("AdminProfileServlet: user not found for username=" + uname);
		}
		logger.info("in admin profile servlet");
		req.getRequestDispatcher("adminProfileFragment.jsp").forward(req, resp);
	}

	@Override
	protected void doPost(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {

		HttpSession session = req.getSession(false);
		if (session == null || !"admin".equalsIgnoreCase((String) session.getAttribute("role"))) {
			resp.sendRedirect(req.getContextPath() + "/index.jsp?error=Access+denied.");
			return;
		}

		String uname = (String) session.getAttribute("username");
		String action = req.getParameter("action");
		UserDAO dao = new UserDAO();

		if ("changePassword".equals(action)) {
			String currentPwd = req.getParameter("currentPassword");
			String newPwd = req.getParameter("newPassword");
			String confirmPwd = req.getParameter("confirmPassword");

			if (newPwd == null || !newPwd.equals(confirmPwd)) {
				req.getSession().setAttribute("success", "Error: Passwords do not match.");
				resp.sendRedirect(req.getContextPath() + "/dashboard.jsp?section=profile");
				return;
			}
			if (newPwd.length() < 8) {
				req.getSession().setAttribute("success", "Error: Password must be at least 8 characters.");
				resp.sendRedirect(req.getContextPath() + "/dashboard.jsp?section=profile");
				return;
			}
			boolean changed = dao.changePassword(uname, currentPwd, newPwd);
			resp.sendRedirect(req.getContextPath() + "/dashboard.jsp?section=profile&pwdMessage="
					+ (changed ? "Password+updated+successfully" : "Current+password+is+incorrect"));
			return;
		}

		/* Default: updateProfile */
		User existing = dao.getUserByUsername(uname);
		if (existing == null) {
			req.getSession().setAttribute("success", "Error: User not found.");
			resp.sendRedirect(req.getContextPath() + "/dashboard.jsp?section=profile");
			return;
		}

		existing.setEmail(req.getParameter("email"));
		existing.setMobileno(req.getParameter("mobile"));
		existing.setAddress(req.getParameter("address"));
		existing.setStatus(req.getParameter("status"));

		boolean updated = dao.updateUser(existing);
		req.getSession().setAttribute("success",
				updated ? "Profile updated successfully." : "Failed to update profile.");
		resp.sendRedirect(req.getContextPath() + "/dashboard.jsp?section=profile");
	}
}