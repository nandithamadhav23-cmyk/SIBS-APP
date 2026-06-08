package com.servlet;

import java.io.IOException;
import java.io.PrintWriter;
import java.sql.Date;
import java.text.SimpleDateFormat;
import java.util.List;
import java.util.Map;
import java.util.logging.Logger;

import com.DAO.CustomerDAO;
import com.DAO.CustomerWalletDAO;
import com.DAO.WalletTransactionDAO;
import com.util.Customer;
import com.util.CustomerWallet;
import com.util.WalletTransaction;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;

/**
 * CustomerWalletServlet — handles all wallet views and actions.
 *
 * GET /CustomerWallet → customer wallet page (own wallet) GET
 * /CustomerWallet?export=csv → CSV download of transaction history GET
 * /CustomerWallet?customerId=X → staff view of a specific customer wallet
 *
 * POST /CustomerWallet action=debit → debit wallet (checkout integration) POST
 * /CustomerWallet action=credit → manual credit (staff/admin only)
 *
 * FIXES vs original: ────────────────── 1. totalWithdrawn attribute added —
 * consumed by JSP stats strip. 2. session.walletBalance updated after every
 * successful debit/credit so the dashboard widget stays in sync without a full
 * reload. 3. withdraw filter option forwarded to JSP (filterTxnType already
 * handles it generically; just needed in the select options in the JSP).
 */
@WebServlet("/CustomerWallet")
public class CustomerWalletServlet extends HttpServlet {

	private static final Logger log = Logger.getLogger(CustomerWalletServlet.class.getName());

	private final CustomerWalletDAO walletDAO = new CustomerWalletDAO();
	private final WalletTransactionDAO txnDAO = new WalletTransactionDAO();
	private final CustomerDAO customerDAO = new CustomerDAO();

	// ─────────────────────────────────────────────────────────────────
	// GET — wallet page or CSV export
	// ─────────────────────────────────────────────────────────────────

	@Override
	protected void doGet(HttpServletRequest request, HttpServletResponse response)
			throws ServletException, IOException {

		HttpSession session = request.getSession(false);
		if (session == null || session.getAttribute("customerId") == null) {
			response.sendRedirect("CustomerLogin.jsp");
			return;
		}

		try {
			int customerId = resolveCustomerId(request, session);
			if (customerId <= 0) {
				response.sendRedirect("CustomerLogin.jsp");
				return;
			}

			// ── CSV export ─────────────────────────────────────────────
			if ("csv".equals(request.getParameter("export"))) {
				exportCsv(customerId, request, response);
				return;
			}

			// ── Build filter params ────────────────────────────────────
			String txnType = request.getParameter("txnType"); // null = all
			String status = request.getParameter("status"); // null = all
			String dateFrom = request.getParameter("dateFrom"); // "yyyy-MM-dd" or null

			Date sqlDateFrom = null;
			if (dateFrom != null && !dateFrom.isBlank()) {
				try {
					sqlDateFrom = Date.valueOf(dateFrom);
				} catch (Exception ignored) {
				}
			}

			// ── Fetch data ─────────────────────────────────────────────
			Customer customer = customerDAO.getProfile(customerId);
			CustomerWallet wallet = walletDAO.getWalletByCustomerId(customerId);
			if (wallet == null) {
				wallet = new CustomerWallet();
			}

			List<WalletTransaction> transactions = txnDAO.getTransactionsByCustomerId(customerId, txnType, status,
					sqlDateFrom);
			Map<String, Object> stats = txnDAO.getSummaryStats(customerId);
			List<Map<String, Object>> monthlySpending = txnDAO.getMonthlySpending(customerId);

			// ── Keep session balance in sync ───────────────────────────
			session.setAttribute("walletBalance", wallet.getBalance());

			// ── Set attributes ─────────────────────────────────────────
			request.setAttribute("customer", customer);
			request.setAttribute("customerName", customer != null ? customer.getName() : "");
			request.setAttribute("customerEmail", customer != null ? customer.getEmail() : "");
			request.setAttribute("wallet", wallet);
			request.setAttribute("walletBalance", wallet.getBalance());
			request.setAttribute("transactions", transactions);
			request.setAttribute("monthlySpending", monthlySpending);

			// Stats
			request.setAttribute("totalTxns", stats.getOrDefault("totalTxns", 0));
			request.setAttribute("totalSpent", stats.getOrDefault("totalSpent", 0.0));
			request.setAttribute("totalRefunds", stats.getOrDefault("totalRefunds", 0.0));
			request.setAttribute("totalCashback", stats.getOrDefault("totalCashback", 0.0));
			request.setAttribute("totalCredited", stats.getOrDefault("totalCredited", 0.0));
			request.setAttribute("totalWithdrawn", stats.getOrDefault("totalWithdrawn", 0.0)); // NEW
			request.setAttribute("spentThisMonth", stats.getOrDefault("spentThisMonth", 0.0));
			request.setAttribute("ordersPaidByWallet", stats.getOrDefault("ordersPaidByWallet", 0));

			// Active filters
			request.setAttribute("filterTxnType", txnType != null ? txnType : "");
			request.setAttribute("filterStatus", status != null ? status : "");
			request.setAttribute("filterDateFrom", dateFrom != null ? dateFrom : "");

			request.getRequestDispatcher("CustomerWallet.jsp").forward(request, response);

		} catch (Exception e) {
			log.severe("CustomerWalletServlet GET failed: " + e.getMessage());
			throw new ServletException("Failed to load wallet page", e);
		}
	}

	// ─────────────────────────────────────────────────────────────────
	// POST — debit (checkout) or manual staff credit
	// ─────────────────────────────────────────────────────────────────

	@Override
	protected void doPost(HttpServletRequest request, HttpServletResponse response)
			throws ServletException, IOException {

		HttpSession session = request.getSession(false);
		boolean isAjax = "XMLHttpRequest".equalsIgnoreCase(request.getHeader("X-Requested-With"));

		if (session == null || session.getAttribute("customerId") == null) {
			if (isAjax) {
				sendJson(response, false, "Session expired. Please log in.");
			} else {
				response.sendRedirect("CustomerLogin.jsp");
			}
			return;
		}

		String action = request.getParameter("action");

		try {
			if ("debit".equals(action)) {
				handleDebit(request, response, session, isAjax);
			} else if ("credit".equals(action)) {
				handleManualCredit(request, response, session, isAjax);
			} else {
				if (isAjax) {
					sendJson(response, false, "Unknown action: " + action);
				} else {
					response.sendError(HttpServletResponse.SC_BAD_REQUEST, "Unknown action");
				}
			}
		} catch (IllegalStateException e) {
			if (isAjax) {
				sendJson(response, false, e.getMessage());
			} else {
				request.setAttribute("error", e.getMessage());
				request.getRequestDispatcher("CustomerWallet.jsp").forward(request, response);
			}
		} catch (Exception e) {
			log.severe("CustomerWalletServlet POST failed: " + e.getMessage());
			if (isAjax) {
				sendJson(response, false, "Server error: " + e.getMessage());
			} else {
				throw new ServletException(e);
			}
		}
	}

	// ─────────────────────────────────────────────────────────────────
	// Action handlers
	// ─────────────────────────────────────────────────────────────────

	private void handleDebit(HttpServletRequest request, HttpServletResponse response, HttpSession session,
			boolean isAjax) throws Exception {

		int customerId = (int) session.getAttribute("customerId");
		double amount = parseDouble(request.getParameter("amount"), 0);
		int orderId = parseInt(request.getParameter("orderId"), 0);
		String desc = request.getParameter("description");
		if (desc == null || desc.isBlank()) {
			desc = "Wallet payment for order #" + orderId;
		}

		if (amount <= 0) {
			throw new IllegalStateException("Debit amount must be greater than ₹0.");
		}

		walletDAO.debitCustomerWallet(customerId, amount, orderId, "Wallet", desc);
		log.info("Wallet DEBIT ₹" + amount + " — customer #" + customerId + " order #" + orderId);

		CustomerWallet updated = walletDAO.getWalletByCustomerId(customerId);
		session.setAttribute("walletBalance", updated.getBalance()); // keep dashboard in sync

		if (isAjax) {
			response.setContentType("application/json");
			response.getWriter()
					.write(String.format("{\"success\":true,\"message\":\"₹%.2f debited.\",\"newBalance\":%.2f}",
							amount, updated.getBalance()));
		} else {
			response.sendRedirect("CustomerWallet");
		}
	}

	private void handleManualCredit(HttpServletRequest request, HttpServletResponse response, HttpSession session,
			boolean isAjax) throws Exception {

		String role = (String) session.getAttribute("role");
		if (!"staff".equalsIgnoreCase(role) && !"admin".equalsIgnoreCase(role)) {
			throw new IllegalStateException("Not authorised to manually credit wallets.");
		}

		int targetCustomerId = parseInt(request.getParameter("customerId"), 0);
		double amount = parseDouble(request.getParameter("amount"), 0);
		String desc = request.getParameter("description");
		String txnType = request.getParameter("txnType"); // cashback | topup | credit
		if (desc == null || desc.isBlank()) {
			desc = "Manual staff credit";
		}
		if (txnType == null || txnType.isBlank()) {
			txnType = "credit";
		}

		if (targetCustomerId <= 0) {
			throw new IllegalStateException("Invalid customer ID.");
		}
		if (amount <= 0) {
			throw new IllegalStateException("Credit amount must be > ₹0.");
		}

		walletDAO.creditCustomerWallet(targetCustomerId, amount, 0, txnType, desc, null);
		log.info("Manual CREDIT ₹" + amount + " → customer #" + targetCustomerId + " by staff="
				+ session.getAttribute("username"));

		CustomerWallet updated = walletDAO.getWalletByCustomerId(targetCustomerId);

		if (isAjax) {
			response.setContentType("application/json");
			response.getWriter()
					.write(String.format("{\"success\":true,\"message\":\"₹%.2f credited.\",\"newBalance\":%.2f}",
							amount, updated.getBalance()));
		} else {
			response.sendRedirect("CustomerWallet?customerId=" + targetCustomerId);
		}
	}

	// ─────────────────────────────────────────────────────────────────
	// CSV export
	// ─────────────────────────────────────────────────────────────────

	private void exportCsv(int customerId, HttpServletRequest request, HttpServletResponse response) throws Exception {

		List<WalletTransaction> all = txnDAO.getTransactionsByCustomerId(customerId);

		response.setContentType("text/csv; charset=UTF-8");
		response.setHeader("Content-Disposition",
				"attachment; filename=\"wallet_transactions_" + customerId + ".csv\"");

		PrintWriter pw = response.getWriter();
		pw.println("ID,Date,Transaction ID,Order ID,Type,Description,Payment Method,Amount,Balance After,Status");

		SimpleDateFormat sdf = new SimpleDateFormat("dd MMM yyyy HH:mm");
		for (WalletTransaction t : all) {
			pw.printf("%d,%s,%s,%s,%s,\"%s\",%s,%.2f,%.2f,%s%n", t.getId(),
					t.getDate() != null ? sdf.format(t.getDate()) : "", nvl(t.getTransactionId()),
					t.getOrderId() > 0 ? "#" + t.getOrderId() : "", nvl(t.getTxnType()),
					nvl(t.getDescription()).replace("\"", "\"\""), nvl(t.getPaymentMethod()), t.getAmount(),
					t.getBalanceAfter(), nvl(t.getStatus()));
		}
		pw.flush();
	}

	// ─────────────────────────────────────────────────────────────────
	// Helpers
	// ─────────────────────────────────────────────────────────────────

	private int resolveCustomerId(HttpServletRequest request, HttpSession session) {
		String role = (String) session.getAttribute("role");
		boolean isStaff = "staff".equalsIgnoreCase(role) || "admin".equalsIgnoreCase(role);
		if (isStaff) {
			String cid = request.getParameter("customerId");
			if (cid != null && !cid.isBlank()) {
				try {
					return Integer.parseInt(cid);
				} catch (NumberFormatException ignored) {
				}
			}
		}
		Object cid = session.getAttribute("customerId");
		return cid instanceof Integer ? (Integer) cid : -1;
	}

	private void sendJson(HttpServletResponse response, boolean success, String message) throws IOException {
		response.setContentType("application/json");
		response.setCharacterEncoding("UTF-8");
		String safe = message != null ? message.replace("\"", "'") : "";
		response.getWriter().write("{\"success\":" + success + ",\"message\":\"" + safe + "\"}");
	}

	private static double parseDouble(String s, double fallback) {
		if (s == null || s.isBlank()) {
			return fallback;
		}
		try {
			return Double.parseDouble(s);
		} catch (NumberFormatException e) {
			return fallback;
		}
	}

	private static int parseInt(String s, int fallback) {
		if (s == null || s.isBlank()) {
			return fallback;
		}
		try {
			return Integer.parseInt(s);
		} catch (NumberFormatException e) {
			return fallback;
		}
	}

	private static String nvl(String s) {
		return s != null ? s : "";
	}
}
