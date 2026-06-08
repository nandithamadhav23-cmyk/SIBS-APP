package com.servlet;

import java.io.IOException;
import java.util.List;

import com.DAO.AddressDAO;
import com.DAO.CustomerDAO;
import com.DAO.OrderDAO;
import com.util.CartItem;
import com.util.Customer;
import com.util.CustomerAddress;
import com.util.Order;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;

@WebServlet("/InvoiceServlet")
public class InvoiceServlet extends HttpServlet {
	/**
	 * 
	 */
	private static final long serialVersionUID = 1L;
	private OrderDAO orderDAO = new OrderDAO();
	private CustomerDAO customerDAO = new CustomerDAO();
	private AddressDAO addressDAO = new AddressDAO();

	@Override
	protected void doGet(HttpServletRequest request, HttpServletResponse response)
			throws ServletException, IOException {
		try {
			int orderId = Integer.parseInt(request.getParameter("orderId"));
			Order order = orderDAO.getOrderById(orderId);

			Customer customer = customerDAO.getProfile(order.getCustomerId());
			CustomerAddress address = addressDAO.getDefaultAddressByCustomer(order.getCustomerId());
			List<CartItem> cartItems = orderDAO.getOrderItems(orderId); // ✅ always fetch from DB

			request.setAttribute("order", order);
			request.setAttribute("customer", customer);
			request.setAttribute("address", address);
			request.setAttribute("cartItems", cartItems);

			request.getRequestDispatcher("invoice.jsp").forward(request, response);
		} catch (Exception e) {
			throw new ServletException("Failed to load invoice", e);
		}
	}
}
