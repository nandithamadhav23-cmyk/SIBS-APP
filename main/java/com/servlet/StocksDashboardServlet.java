package com.servlet;

import java.io.IOException;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;

/**
 * StocksDashboardServlet
 *
 * Handles GET /StocksDashboard — entry point for the Stock Analytics page.
 * Role-gates to admin/staff then forwards to stocksDashboard.jsp.
 * All data is loaded client-side via AJAX calls to StockApiServlet.
 */
@WebServlet("/StocksDashboard")
public class StocksDashboardServlet extends HttpServlet {

    private static final long serialVersionUID = 1L;

    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse res)
            throws ServletException, IOException {

        HttpSession session = req.getSession(false);
        String role = (session != null) ? (String) session.getAttribute("role") : null;

        if (role == null || !("admin".equalsIgnoreCase(role) || "staff".equalsIgnoreCase(role))) {
            res.sendRedirect(req.getContextPath() + "/index.jsp?error=Access+denied.+Please+login.");
            return;
        }

        req.getRequestDispatcher("/stocksDashboard.jsp").forward(req, res);
    }
}
