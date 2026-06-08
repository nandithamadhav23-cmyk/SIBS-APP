package com.servlet;

import java.io.IOException;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;

/**
 * ReportsDashboardServlet
 *
 * Handles GET /ReportsDashboard — the entry point for the Analytics Reports
 * page. Performs a role-gate (admin or staff) then forwards to
 * reportsDashboard.jsp.
 *
 * The JSP renders the full dashboard shell; all chart data is loaded
 * client-side via AJAX calls to ReportServlet (/ReportServlet?action=...).
 *
 * URL mapped in the existing dashboard sidebar as:
 * <a href="ReportsDashboard" class="sidebar-nav-link ajax-link">
 * <i class="bi bi-bar-chart-line"></i> Reports </a>
 */
@WebServlet("/ReportsDashboard")
public class ReportsDashboardServlet extends HttpServlet {

	private static final long serialVersionUID = 1L;

	@Override
	protected void doGet(HttpServletRequest req, HttpServletResponse res) throws ServletException, IOException {

		HttpSession session = req.getSession(false);
		String role = (session != null) ? (String) session.getAttribute("role") : null;

		if (role == null || !("admin".equalsIgnoreCase(role) || "staff".equalsIgnoreCase(role))) {
			res.sendRedirect(req.getContextPath() + "/index.jsp?error=Access+denied.+Please+login.");
			return;
		}

		// Forward to the JSP — no additional request attributes needed;
		// the JSP bootstraps data entirely via client-side AJAX calls.
		req.getRequestDispatcher("/reportsDashboard.jsp").forward(req, res);
	}
}
