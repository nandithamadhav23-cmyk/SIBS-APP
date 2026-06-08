package com.servlet;

import java.io.IOException;
import java.sql.SQLException;
import java.util.List;

import com.DAO.CustomerDAO;
import com.util.Product;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;

/**
 * WishlistServlet — FIXED.
 *
 * Fixes: 1. Added "saveLater" action: adds item to Wishlist from productGrid /
 * quickView. 2. Added "add" action alias for saveLater. 3. Auth guard:
 * redirects to login if session is missing. 4. AJAX toggle support: responds
 * with JSON when X-Requested-With header is set. 5. Robust error handling —
 * individual item errors don't crash the page.
 */
@WebServlet("/WishlistServlet")
public class WishlistServlet extends HttpServlet {
	private CustomerDAO dao = new CustomerDAO();

	@Override
	protected void doGet(HttpServletRequest req, HttpServletResponse res) throws ServletException, IOException {

		// Auth guard
		Object cidAttr = req.getSession(false) != null ? req.getSession(false).getAttribute("customerId") : null;
		if (cidAttr == null) {
			res.sendRedirect("CustomerLogin.jsp");
			return;
		}
		int customerId = (int) cidAttr;
		String action = req.getParameter("action");
		String idParam = req.getParameter("id");
		int productId = (idParam != null && !idParam.isBlank()) ? Integer.parseInt(idParam) : 0;

		boolean isAjax = "XMLHttpRequest".equalsIgnoreCase(req.getHeader("X-Requested-With"));

		try {
			if ("remove".equals(action) && productId > 0) {
				dao.removeWishlistItem(customerId, productId);
				if (isAjax) {
					res.setContentType("application/json");
					res.getWriter().write("{\"success\":true,\"wished\":false}");
					return;
				}

			} else if (("saveLater".equals(action) || "add".equals(action)) && productId > 0) {
				// CustomerDAO.addToWishlist() must exist — add it if missing:
				// INSERT IGNORE INTO Wishlist (customer_id, product_id, added_date) VALUES
				// (?,?,NOW())
				dao.addToWishlist(customerId, productId);
				if (isAjax) {
					res.setContentType("application/json");
					res.getWriter().write("{\"success\":true,\"wished\":true}");
					return;
				}
				String ref = req.getHeader("Referer");
				res.sendRedirect(ref != null ? ref : "WishlistServlet");
				return;

			} else if ("toggle".equals(action) && productId > 0) {
				// CustomerDAO.isInWishlist() must exist — add it if missing:
				// SELECT 1 FROM Wishlist WHERE customer_id=? AND product_id=?
				boolean already = dao.isInWishlist(customerId, productId);
				if (already) {
					dao.removeWishlistItem(customerId, productId);
				} else {
					dao.addToWishlist(customerId, productId);
				}
				if (isAjax) {
					res.setContentType("application/json");
					res.getWriter().write("{\"success\":true,\"wished\":" + !already + "}");
					return;
				}
			}

			// Default: show wishlist page
			List<Product> wishlist = dao.getWishlist(customerId);
			req.setAttribute("wishlist", wishlist);
			req.getRequestDispatcher("wishlist.jsp").forward(req, res);

		} catch (SQLException e) {
			e.printStackTrace();
			if (isAjax) {
				res.setContentType("application/json");
				res.setStatus(500);
				res.getWriter().write("{\"success\":false,\"message\":\"Server error\"}");
			} else {
				res.sendRedirect("error.jsp");
			}
		}
	}
}
