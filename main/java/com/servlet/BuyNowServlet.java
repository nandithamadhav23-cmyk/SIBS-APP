
package com.servlet;

import java.io.IOException;
import java.text.DecimalFormat;
import java.util.ArrayList;
import java.util.List;

import com.DAO.AddressDAO;
import com.DAO.CustomerDAO;
import com.DAO.ProductDAO;
import com.util.CartItem;
import com.util.Customer;
import com.util.CustomerAddress;
import com.util.Product;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;

@WebServlet("/BuyNow")
public class BuyNowServlet extends HttpServlet {
	private ProductDAO productDAO;
	private CustomerDAO customerDAO;
	private AddressDAO addressDAO;

	@Override
	public void init() {
		productDAO = new ProductDAO();
		customerDAO = new CustomerDAO();
		addressDAO = new AddressDAO();
	}

	@Override
	protected void doPost(HttpServletRequest req, HttpServletResponse res) throws ServletException, IOException {
		try {
			int customerId = (int) req.getSession().getAttribute("customerId");
			String productIdParam = req.getParameter("productId");
			String quantityParam = req.getParameter("quantity");

			// ✅ Guard against missing params
			if (productIdParam == null || quantityParam == null) {
				res.sendRedirect("error.jsp");
				return;
			}

			int productId = Integer.parseInt(productIdParam);
			int quantity = Integer.parseInt(quantityParam);

			Product product = productDAO.getProductById(productId);
			if (product == null) {
				res.sendRedirect("error.jsp");
				return;
			}

			// Build single CartItem
			CartItem item = new CartItem();
			item.setProductId(productId);
			item.setName(product.getName());
			item.setDescription(product.getDescription());
			item.setImageUrl(product.getImageUrl());
			item.setProductQuantity(product.getQuantity());
			item.setQuantity(quantity);
			item.setFinalPrice(product.getFinalPrice());
			item.setDiscount(product.getDiscount());
			item.setUnit(product.getUnit());
			item.setStock(product.getStock());

			List<CartItem> items = new ArrayList<>();
			items.add(item);

			DecimalFormat df = new DecimalFormat("0.00");
			// Totals — must match PlaceOrderServlet formula exactly
			double subtotal = item.getFinalPrice() * quantity;
			double gst = subtotal * 0.18;
			double tax = subtotal * 0.05;
			double deliveryCharge = (subtotal > 700) ? 0 : 40; // free above ₹700 for buy-now
			// COD charge not known yet (user picks payment on checkout) — show 0 as default
			double grandTotal = subtotal + gst + tax + deliveryCharge;

			Customer customer = customerDAO.getProfile(customerId);
			List<CustomerAddress> addresses = addressDAO.getAddressesByCustomer(customerId);
			CustomerAddress defaultAddress = addressDAO.getDefaultAddressByCustomer(customerId);

			// Attributes for Checkout.jsp
			req.setAttribute("customer", customer);
			req.setAttribute("addresses", addresses);
			req.setAttribute("productId", productId);
			req.setAttribute("quantity", quantity);
			req.setAttribute("buyNow", "true");
			req.setAttribute("defaultAddress", defaultAddress);
			req.setAttribute("cartItems", items);

			req.setAttribute("subtotal", df.format(subtotal));
			req.setAttribute("gst", df.format(gst));
			req.setAttribute("tax", df.format(tax));
			req.setAttribute("deliveryCharge", df.format(deliveryCharge));
			req.setAttribute("grandTotal", df.format(grandTotal));

			// ✅ Forward to checkout page
			req.getRequestDispatcher("Checkout.jsp").forward(req, res);

		} catch (Exception e) {
			throw new ServletException("Buy Now failed", e);
		}
	}
}
