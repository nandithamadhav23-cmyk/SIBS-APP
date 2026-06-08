package com.servlet;

import java.io.IOException;
import java.text.DecimalFormat;
import java.util.List;
import java.util.UUID;

import com.DAO.AddressDAO;
import com.DAO.CartDAO;
import com.DAO.CustomerDAO;
import com.util.CartItem;
import com.util.Customer;
import com.util.CustomerAddress;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;

/**
 * CheckoutServlet — GST RATE FIX applied.
 *
 * WHAT WAS WRONG: Like PlaceOrderServlet, this servlet applied a flat 18% GST
 * and a phantom 5% "tax" on the entire subtotal regardless of product category.
 * This meant the preview total shown on Checkout.jsp was wrong, and for
 * products with 0% or 5% GST the customer was shown an inflated total.
 *
 * FIX SUMMARY: - Uses PlaceOrderServlet.computeGst(cartItems) — the same shared
 * helper that PlaceOrderServlet uses — so checkout preview is always identical
 * to what gets billed. - The "tax" variable is removed entirely (GST is the
 * only indirect tax). - grandTotalBase = subtotal + gst + deliveryCharge (COD
 * charge added dynamically in JS as before).
 */
@WebServlet("/Checkout")
public class CheckoutServlet extends HttpServlet {

	private static final long serialVersionUID = 1L;
	private CartDAO cartDAO;
	private CustomerDAO customerDAO;
	private AddressDAO addressDAO;

	@Override
	public void init() {
		cartDAO = new CartDAO();
		customerDAO = new CustomerDAO();
		addressDAO = new AddressDAO();
	}

	@Override
	protected void doGet(HttpServletRequest req, HttpServletResponse res) throws ServletException, IOException {

		Object cidAttr = req.getSession().getAttribute("customerId");
		if (cidAttr == null) {
			res.sendRedirect("CustomerLogin.jsp");
			return;
		}
		int customerId = (int) cidAttr;

		try {
			Customer customer = customerDAO.getProfile(customerId);
			List<CustomerAddress> addresses = addressDAO.getAddressesByCustomer(customerId);
			CustomerAddress defaultAddr = addressDAO.getDefaultAddressByCustomer(customerId);
			List<CartItem> cartItems = cartDAO.getCartProducts(customerId);

			// ── GST FIX: compute totals correctly ────────────────────────────
			//
			// OLD (wrong):
			// double gst = subtotal * 0.18;
			// double tax = subtotal * 0.05; ← phantom charge
			// double grandTotalBase = subtotal + gst + tax + deliveryCharge;
			//
			// NEW (correct):
			// GST is summed per item using each product's own gst_rate.
			// No separate "tax" — GST is the only indirect tax in India.
			//
			double subtotal = calculateSubtotal(cartItems);
			double gst = PlaceOrderServlet.computeGst(cartItems); // GST FIX
			double deliveryCharge = PlaceOrderServlet.computeDeliveryCharge(subtotal);
			// COD charge shown dynamically in JS when user picks COD
			double grandTotalBase = subtotal + gst + deliveryCharge; // GST FIX: no tax

			DecimalFormat df = new DecimalFormat("0.00");

			// ── Checkout token (duplicate-submission guard) ───────────────────
			String formToken = UUID.randomUUID().toString();
			req.getSession().setAttribute("checkoutToken", formToken);

			req.setAttribute("customer", customer);
			req.setAttribute("addresses", addresses);
			req.setAttribute("defaultAddress", defaultAddr);
			req.setAttribute("cartItems", cartItems);
			req.setAttribute("subtotal", df.format(subtotal));
			req.setAttribute("gst", df.format(gst));
			// "tax" attribute removed — no longer a valid charge
			req.setAttribute("deliveryCharge", df.format(deliveryCharge));
			req.setAttribute("grandTotal", df.format(grandTotalBase));
			req.setAttribute("formToken", formToken);

			req.getRequestDispatcher("Checkout.jsp").forward(req, res);

		} catch (Exception e) {
			e.printStackTrace();
			res.sendRedirect("error.jsp");
		}
	}

	private double calculateSubtotal(List<CartItem> items) {
		double sub = 0.0;
		for (CartItem item : items) {
			sub += item.getFinalPrice() * item.getQuantity();
		}
		return sub;
	}
}
