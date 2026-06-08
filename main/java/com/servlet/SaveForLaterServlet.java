package com.servlet;

import java.io.IOException;

import com.DAO.CartDAO;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;

/**
 * SaveForLaterServlet — FIXED.
 *
 * Original bug: used productId to call moveToSavedItems(customerId, productId)
 * which was safe for product-based lookups, but CartServlet uses cartId.
 *
 * FIX: - doPost() now accepts both "productId" (move by product) AND "cartId"
 * (move by cart row) so both cart.jsp buttons work correctly. - Added doGet()
 * redirect for safety (cartId via GET from cart.jsp links). - Added auth guard.
 * - CartDAO.moveToSavedItems() now correctly filters by AND status='ACTIVE' so
 * re-saving an already-saved item is a no-op.
 */
@WebServlet("/SaveForLater")
public class SaveForLaterServlet extends HttpServlet {
	private static final long serialVersionUID = 1L;

	@Override
	protected void doGet(HttpServletRequest request, HttpServletResponse response)
			throws ServletException, IOException {
		// cart.jsp uses GET links for saveForLater — handle via CartServlet instead
		response.sendRedirect("CartServlet?action=view");
	}

	@Override
	protected void doPost(HttpServletRequest request, HttpServletResponse response) throws IOException {

		HttpSession session = request.getSession(false);
		if (session == null || session.getAttribute("customerId") == null) {
			response.sendRedirect("CustomerLogin.jsp");
			return;
		}

		int customerId = (int) session.getAttribute("customerId");
		CartDAO cartDAO = new CartDAO();

		try {
			String cartIdParam = request.getParameter("cartId");
			String productIdParam = request.getParameter("productId");

			if (cartIdParam != null && !cartIdParam.isBlank()) {
				// Preferred: move by cartId (atomic, no ambiguity)
				int cartId = Integer.parseInt(cartIdParam);
				cartDAO.updateStatus(cartId, "SAVED");

			} else if (productIdParam != null && !productIdParam.isBlank()) {
				// Fallback: move by productId + customerId
				int productId = Integer.parseInt(productIdParam);
				cartDAO.moveToSavedItems(customerId, productId);

			} else {
				// Missing params — just go back to cart
				response.sendRedirect("CartServlet?action=view");
				return;
			}

			response.sendRedirect("CartServlet?action=view");

		} catch (Exception e) {
			e.printStackTrace();
			response.sendRedirect("error.jsp");
		}
	}
}
