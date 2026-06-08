package com.servlet;

import java.io.IOException;
import java.text.DecimalFormat;
import java.util.List;

import com.DAO.CartDAO;
import com.util.CartItem;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;

/**
 * CartServlet — GST RATE FIX applied.
 *
 * WHAT WAS WRONG (3 places): 1. "view" action: gst = subtotal * 0.18 + tax =
 * subtotal * 0.05 (flat 23% on everything) 2. "update" action: same wrong
 * formula in the AJAX JSON response → the live summary panel on the cart page
 * showed wrong totals 3. cart.jsp itself: showed "Platform Tax (5%)" as a
 * separate line — that charge doesn't exist
 *
 * GST FIX EXPLANATION: - computeGst() sums each cart item's own GST:
 * item.finalPrice × item.quantity × (item.gstRate / 100) -
 * CartDAO.getCartProducts() already fetches gst_rate from the products table
 * (fixed in the earlier CartDAO update), so each CartItem now carries the
 * correct rate for its product. - No separate "tax" — in India, GST IS the
 * indirect tax. - The JSON response for the "update" AJAX call now returns a
 * "gst" field with the correct per-item sum, and "tax" is returned as "0.00" so
 * the cart.jsp JS doesn't break (it just shows ₹0 until the JSP is also
 * updated).
 *
 * HOW GST FLOWS WHEN AN ORDER IS PLACED FROM THE CART: Cart page → Checkout
 * page → PlaceOrderServlet Each step reads gstRate from CartItem (loaded by
 * CartDAO from DB), so the GST shown on the cart, on checkout, and billed to
 * the customer are all identical and correct.
 *
 * WHEN A PRODUCT'S GST RATE IS CHANGED BY ADMIN: - The change is saved to the
 * products.gst_rate column (ProductDAO). - The NEXT time a customer loads their
 * cart (CartDAO.getCartProducts joins products table), the new rate is picked
 * up automatically. - Existing orders are NOT affected — they have already been
 * billed.
 */
@WebServlet("/CartServlet")
public class CartServlet extends HttpServlet {
	private static final long serialVersionUID = 1L;
	private CartDAO cartDAO;

	@Override
	public void init() throws ServletException {
		cartDAO = new CartDAO();
	}

	// ── GST helper — the single source of truth for cart-level GST ───────────

	/**
	 * GST FIX: sums per-item GST across all cart items.
	 *
	 * Each CartItem carries its own gstRate (fetched from products.gst_rate by
	 * CartDAO). This means: - A 1 kg rice bag (0% GST) contributes ₹0 GST. - A 500
	 * g snack pack (18% GST) at ₹40 contributes ₹7.20 GST. The cart total therefore
	 * shows the exact GST each customer will pay, reflecting each product's actual
	 * tax category.
	 */
	private double computeGst(List<CartItem> items) {
		return items.stream().mapToDouble(i -> i.getFinalPrice() * i.getQuantity() * (i.getGstRate() / 100.0)).sum();
	}

	// ── Delivery charge rule — consistent with PlaceOrderServlet ─────────────

	private double computeDelivery(double subtotal) {
		return subtotal >= 499 ? 0 : 40;
	}

	@Override
	protected void doGet(HttpServletRequest req, HttpServletResponse res) throws ServletException, IOException {

		String action = req.getParameter("action");
		Object cidObj = req.getSession().getAttribute("customerId");
		if (cidObj == null) {
			res.sendRedirect("CustomerLogin.jsp");
			return;
		}
		int customerId = (Integer) cidObj;

		try {
			switch (action == null ? "view" : action) {

			// ── ADD TO CART ───────────────────────────────────────────────────
			case "add": {
				String idParam = req.getParameter("id");
				if (idParam == null || idParam.isBlank()) {
					boolean isAjax = "XMLHttpRequest".equalsIgnoreCase(req.getHeader("X-Requested-With"));
					if (isAjax) {
						res.setContentType("application/json");
						res.getWriter().write("{\"success\":false,\"message\":\"Invalid product\"}");
					} else {
						res.sendRedirect("CartServlet?action=view");
					}
					return;
				}
				int productId = Integer.parseInt(idParam);
				int addQty = 1;
				String qtyParam = req.getParameter("qty");
				if (qtyParam != null && !qtyParam.isBlank()) {
					try {
						addQty = Math.max(1, Integer.parseInt(qtyParam));
					} catch (NumberFormatException ignored) {
					}
				}
				cartDAO.addToCart(customerId, productId, addQty);

				List<CartItem> updatedItems = cartDAO.getCartProducts(customerId);
				int updatedCount = updatedItems.stream().mapToInt(CartItem::getQuantity).sum();
				req.getSession().setAttribute("cartCount", updatedCount);

				boolean isAjax = "XMLHttpRequest".equalsIgnoreCase(req.getHeader("X-Requested-With"));
				if (isAjax) {
					res.setContentType("application/json");
					res.getWriter().write("{\"success\":true,\"cartCount\":" + updatedCount + "}");
				} else {
					res.sendRedirect("CartServlet?action=view");
				}
				break;
			}

			// ── UPDATE QUANTITY (AJAX) ────────────────────────────────────────
			//
			// GST FIX: was using subtotal * 0.18 and subtotal * 0.05.
			// Now uses computeGst() so the live summary panel on the cart page
			// updates with the same per-item GST that will be charged at checkout.
			//
			// JSON fields returned:
			// subtotal — item total before GST (₹)
			// gst — correct per-item sum GST (₹)
			// tax — always "0.00" (no separate tax; kept so JS doesn't break)
			// grandTotal — subtotal + gst + delivery
			// totalProducts, updatedQuantity — unchanged
			case "update": {
				int cartId = Integer.parseInt(req.getParameter("cartId"));
				int quantity = Integer.parseInt(req.getParameter("quantity"));
				cartDAO.updateQuantity(cartId, quantity);

				List<CartItem> cartItems = cartDAO.getCartProducts(customerId);
				double subtotal = cartItems.stream().mapToDouble(i -> i.getFinalPrice() * i.getQuantity()).sum();
				int totalProducts = cartItems.stream().mapToInt(CartItem::getQuantity).sum();

				// GST FIX: per-item sum, not flat percentage
				double gst = computeGst(cartItems);
				double tax = 0.0; // GST FIX: no separate tax
				double delivery = computeDelivery(subtotal);
				double grandTotal = subtotal + gst + delivery; // GST FIX: tax excluded

				DecimalFormat df = new DecimalFormat("0.00");

				res.setContentType("application/json");
				res.getWriter()
						.write("{\"subtotal\":\"" + df.format(subtotal) + "\"," + "\"gst\":\"" + df.format(gst) + "\","
								+ "\"tax\":\"" + df.format(tax) + "\"," // always 0.00
								+ "\"grandTotal\":\"" + df.format(grandTotal) + "\"," + "\"totalProducts\":\""
								+ totalProducts + "\"," + "\"updatedQuantity\":\"" + quantity + "\"}");
				break;
			}

			// ── REMOVE FROM CART ─────────────────────────────────────────────
			case "remove": {
				int cartId = Integer.parseInt(req.getParameter("cartId"));
				cartDAO.removeFromCart(cartId);
				List<CartItem> updAfterRemove = cartDAO.getCartProducts(customerId);
				int cntAfterRemove = updAfterRemove.stream().mapToInt(CartItem::getQuantity).sum();
				req.getSession().setAttribute("cartCount", cntAfterRemove);
				res.sendRedirect("CartServlet?action=view");
				break;
			}

			// ── SAVE FOR LATER ───────────────────────────────────────────────
			case "saveForLater": {
				int cartId = Integer.parseInt(req.getParameter("cartId"));
				cartDAO.updateStatus(cartId, "SAVED");
				res.sendRedirect("CartServlet?action=view");
				break;
			}

			// ── MOVE SAVED → ACTIVE ──────────────────────────────────────────
			case "moveToCart": {
				int cartId = Integer.parseInt(req.getParameter("cartId"));
				cartDAO.updateStatus(cartId, "ACTIVE");
				res.sendRedirect("CartServlet?action=view");
				break;
			}

			// ── VIEW CART (default) ───────────────────────────────────────────
			//
			// GST FIX: was using subtotal * 0.18 and subtotal * 0.05.
			// Now uses computeGst() so the cart summary shows the correct
			// per-item GST that will also appear on the Checkout page and
			// will be billed in PlaceOrderServlet.
			case "view":
			default: {
				List<CartItem> cartItems = cartDAO.getCartProducts(customerId);
				List<CartItem> savedItems = cartDAO.getSavedItems(customerId);

				double subtotal = cartItems.stream().mapToDouble(i -> i.getFinalPrice() * i.getQuantity()).sum();
				int totalProducts = cartItems.stream().mapToInt(CartItem::getQuantity).sum();

				// GST FIX: per-item sum GST
				double gst = computeGst(cartItems);
				double tax = 0.0; // GST FIX: removed phantom 5% tax
				double delivery = computeDelivery(subtotal);
				double grandTotal = subtotal + gst + delivery; // GST FIX

				DecimalFormat df = new DecimalFormat("0.00");

				req.getSession().setAttribute("cartCount", totalProducts);
				req.getSession().setAttribute("cartItems", cartItems);

				req.setAttribute("cartItems", cartItems);
				req.setAttribute("savedItems", savedItems);
				req.setAttribute("subtotal", df.format(subtotal));
				req.setAttribute("gst", df.format(gst));
				req.setAttribute("tax", df.format(tax)); // "0.00" — kept for JSP compat
				req.setAttribute("grandTotal", df.format(grandTotal));
				req.setAttribute("totalProducts", totalProducts);

				req.getRequestDispatcher("cart.jsp").forward(req, res);
				break;
			}

			} // end switch
		} catch (Exception e) {
			e.printStackTrace();
			res.sendRedirect("error.jsp");
		}
	}
}
