package com.servlet;

import java.io.IOException;
import java.sql.SQLException;
import java.util.List;
import java.util.logging.Logger;

import com.DAO.CartDAO;
import com.DAO.CustomerDAO;
import com.DAO.CustomerNotificationDAO;
import com.DAO.CustomerWalletDAO;
import com.DAO.ProductDAO;
import com.util.CartItem;
import com.util.Customer;
import com.util.CustomerWallet;
import com.util.Product;

import jakarta.servlet.RequestDispatcher;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;

@WebServlet("/Customer")
public class CustomerDashboardServlet extends HttpServlet {

	private static final Logger log = Logger.getLogger(CustomerDashboardServlet.class.getName());

	private CustomerDAO customerDAO;
	private ProductDAO productDAO;
	private CustomerWalletDAO walletDAO;
	private CustomerNotificationDAO notifDAO;
	private CartDAO cartDAO;

	@Override
	public void init() throws ServletException {
		try {
			customerDAO = new CustomerDAO();
			productDAO = new ProductDAO();
			walletDAO = new CustomerWalletDAO();
			cartDAO = new CartDAO();

			notifDAO = new CustomerNotificationDAO();
			notifDAO.ensureTable();
		} catch (Exception e) {
			throw new ServletException(e);
		}
	}

	@Override
	protected void doGet(HttpServletRequest request, HttpServletResponse response)
			throws ServletException, IOException {

		HttpSession session = request.getSession(false);

		// ── Auth guard ────────────────────────────────────────────────
		// BUG FIX: original code cast session.getAttribute("customerId") without
		// checking for null first — throws NPE when session has expired.
		if (session == null || session.getAttribute("customerId") == null) {
			response.sendRedirect("CustomerLogin.jsp");
			return;
		}

		// BUG FIX: original code read "customer" from session AFTER using
		// customerId, and returned early without checking customerId validity.
		Customer customer = (Customer) session.getAttribute("customer");
		if (customer == null) {
			response.sendRedirect("CustomerLogin.jsp");
			return;
		}

		int customerId = (int) session.getAttribute("customerId");

		try {
			// ── Customer stats ────────────────────────────────────────
			int totalOrders = customerDAO.getTotalOrders(customerId);
			double totalSpent = customerDAO.getTotalSpent(customerId);
			int wishlistCount = customerDAO.getWishlistCount(customerId);

			request.setAttribute("totalOrders", totalOrders);
			request.setAttribute("totalSpent", totalSpent);
			request.setAttribute("wishlistCount", wishlistCount);

			// ── Wallet balance ────────────────────────────────────────
			// BUG FIX: original code read walletBalance from session which is
			// never set by this servlet, so the wallet widget always showed ₹0.
			// We now fetch it live from the DB on every dashboard load.
			double walletBalance = 0.0;
			try {
				CustomerWallet wallet = walletDAO.getWalletByCustomerId(customerId);
				if (wallet != null) {
					walletBalance = wallet.getBalance();
				}
			} catch (Exception walletEx) {
				// Non-fatal: dashboard still loads even if wallet DB call fails
				log.warning(
						"Could not fetch wallet balance for customer #" + customerId + ": " + walletEx.getMessage());
			}
			// Store as BOTH request attribute (for JSP render) AND session
			// attribute (so other pages that read session.walletBalance get
			// a fresh value after top-up without a full page reload).
			request.setAttribute("walletBalance", walletBalance);
			session.setAttribute("walletBalance", walletBalance);

			// ── Product pagination ────────────────────────────────────
			int page = 1;
			int recordsPerPage = 9;
			if (request.getParameter("page") != null) {
				try {
					page = Integer.parseInt(request.getParameter("page"));
				} catch (NumberFormatException ignored) {
				}
			}

			List<Product> products = productDAO.getProductsByPage((page - 1) * recordsPerPage, recordsPerPage);
			int totalRecords = productDAO.getProductCount();
			int totalPages = (int) Math.ceil(totalRecords * 1.0 / recordsPerPage);

			request.setAttribute("customer", customer);
			request.setAttribute("products", products);
			request.setAttribute("currentPage", page);
			request.setAttribute("totalPages", totalPages);
			List<CartItem> updatedItems = cartDAO.getCartProducts(customerId);
			int updatedCount = updatedItems.stream().mapToInt(CartItem::getQuantity).sum();
			session.setAttribute("cartCount", updatedCount);
			// Notification badge count
			int unreadNotifCount = 0;
			try {
				unreadNotifCount = notifDAO.countUnread(customerId);
			} catch (Exception nex) {
				log.warning("Could not fetch notification count: " + nex.getMessage());
			}
			request.setAttribute("unreadNotifCount", unreadNotifCount);
			session.setAttribute("unreadNotifCount", unreadNotifCount);

			RequestDispatcher dispatcher = request.getRequestDispatcher("customerDashboard.jsp");
			dispatcher.forward(request, response);

		} catch (SQLException e) {
			log.severe("CustomerDashboardServlet error for customer #" + customerId + ": " + e.getMessage());
			request.setAttribute("errorMessage", e.getMessage());
			response.sendRedirect("error.jsp");
		}
	}
}
