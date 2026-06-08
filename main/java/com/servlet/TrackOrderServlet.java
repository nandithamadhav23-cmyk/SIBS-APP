package com.servlet;

import java.io.IOException;
import java.util.List;

import com.DAO.AddressDAO;
import com.DAO.OrderDAO;
import com.util.CartItem;
import com.util.Customer;
import com.util.CustomerAddress;
import com.util.Order;

import jakarta.servlet.RequestDispatcher;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;

@WebServlet("/TrackOrderServlet")
public class TrackOrderServlet extends HttpServlet {
	/**
	 * 
	 */
	private static final long serialVersionUID = 1L;
	private OrderDAO orderDAO = new OrderDAO();
	private AddressDAO addressDAO = new AddressDAO();

	@Override
	protected void doGet(HttpServletRequest request, HttpServletResponse response)
			throws ServletException, IOException {
		// If no orderId supplied, just show the TrackOrder search page
		String orderIdParam = request.getParameter("orderId");

		if (orderIdParam == null || orderIdParam.trim().isEmpty()) {
			request.getRequestDispatcher("TrackOrder.jsp").forward(request, response);
			return;
		}
		try {
			int orderId = Integer.parseInt(orderIdParam.trim());
			Order order = orderDAO.getOrderById(orderId);

			// Security: ensure order belongs to this customer
			Customer customer = (Customer) request.getSession().getAttribute("customer");

			if (order == null || (customer != null && order.getCustomerId() != customer.getId())) {
				// Show page with null order - will display search form
				request.getRequestDispatcher("TrackOrder.jsp").forward(request, response);
				return;
			}

			CustomerAddress address = addressDAO.getDefaultAddressByCustomer(order.getCustomerId());
			List<CartItem> items = orderDAO.getOrderItems(orderId);

			request.setAttribute("order", order);
			request.setAttribute("address", address);
			request.setAttribute("items", items);

			RequestDispatcher rd = request.getRequestDispatcher("TrackOrder.jsp");
			rd.forward(request, response);
		} catch (NumberFormatException e) {
			// Bad orderId param - show search page
			request.getRequestDispatcher("TrackOrder.jsp").forward(request, response);
		} catch (Exception e) {
			throw new ServletException(e);
		}
	}
}
