package com.servlet;

import java.io.IOException;
import java.util.List;
import java.util.logging.Logger;

import com.DAO.AgentWalletDAO;
import com.DAO.OrderDAO;
import com.util.Order;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;

@WebServlet("/BillsPage")
public class BillsServlet extends HttpServlet {
	private final OrderDAO orderDAO = new OrderDAO();
	private static final Logger log = Logger.getLogger(BillsServlet.class.getName());
	private final AgentWalletDAO agentWalletDAO = new AgentWalletDAO();

	@Override
	protected void doGet(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {
		try {
			List<Order> orders = orderDAO.getAllOrdersWithAudit(); // fetch all orders
			System.out.println("in do get method");
			int totalBills = orders.size();
			long paidCount = orders.stream().filter(o -> "PAID".equalsIgnoreCase(o.getPaymentStatus())).count();
			long refundedCount = orders.stream().filter(o -> "REFUNDED".equalsIgnoreCase(o.getPaymentStatus())).count();

			req.setAttribute("orders", orders);
			req.setAttribute("totalBills", totalBills);
			req.setAttribute("paidCount", paidCount);
			req.setAttribute("refundedCount", refundedCount);
			req.setAttribute("orders", orders);

			/* ── Agent rejection summary (used by Reject Tasks tab) ── */
			try {
				java.util.List<java.util.Map<String, Object>> rejSummary = orderDAO.getAllAgentRejectionSummary();
				req.setAttribute("rejectionSummary", rejSummary);
			} catch (Exception ex) {
				log.warning("BillsServlet: could not load rejection summary: " + ex.getMessage());
				req.setAttribute("rejectionSummary", new java.util.ArrayList<>());
			}

			/* ── Pending withdrawal requests (used by Withdrawals tab) ── */
			try {
				java.util.List<java.util.Map<String, Object>> pendingWd = agentWalletDAO
						.getWithdrawalRequests("pending");
				req.setAttribute("pendingWithdrawals", pendingWd);
			} catch (Exception ex) {
				log.warning("BillsServlet: could not load pending withdrawals: " + ex.getMessage());
				req.setAttribute("pendingWithdrawals", new java.util.ArrayList<>());
			}
			req.getRequestDispatcher("Bill.jsp").forward(req, resp);
		} catch (Exception e) {
			throw new ServletException(e);
		}
	}
}
