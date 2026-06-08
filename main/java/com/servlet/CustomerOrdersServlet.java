package com.servlet;

import java.io.IOException;
import java.util.List;

import com.DAO.CustomerDAO;
import com.DAO.CustomerWalletDAO;
import com.DAO.OrderDAO;
import com.DAO.OrderReturnDAO;
import com.DAO.ProductDAO;
import com.DAO.StaffNotificationDAO;
import com.util.CartItem;
import com.util.Customer;
import com.util.Order;
import com.util.OrderReturn;
import com.util.StaffNotification;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;

@WebServlet("/CustomerOrdersServlet")
public class CustomerOrdersServlet extends HttpServlet {
	private static final long serialVersionUID = 1L;
	private OrderDAO orderDAO = new OrderDAO();
	private CustomerDAO customerDAO = new CustomerDAO();
	private OrderReturnDAO returnDAO = new OrderReturnDAO();
	private ProductDAO productDAO = new ProductDAO();
	private CustomerWalletDAO walletDAO = new CustomerWalletDAO();
	private StaffNotificationDAO notifDAO = new StaffNotificationDAO();

	@Override
	protected void doGet(HttpServletRequest request, HttpServletResponse response)
			throws ServletException, IOException {
		try {
			Object customerIdAttr = request.getSession().getAttribute("customerId");
			if (customerIdAttr == null) {
				response.sendRedirect("CustomerLogin.jsp");
				return;
			}
			int customerId = (int) customerIdAttr;
			List<Order> orders = orderDAO.getOrdersByCustomer(customerId);
			for (Order order : orders) {
				try {
					Customer customer = customerDAO.getProfile(order.getCustomerId());
					List<CartItem> cartItems = orderDAO.getOrderItems(order.getId());
					OrderReturn rr = returnDAO.getReturnByOrderId(order.getId());
					order.setReturnRequest(rr);
					int otp = orderDAO.getOrderOtp(order.getId());
					if (customer != null) {
						order.setCustomerName(customer.getName());
						order.setCustomerEmail(customer.getEmail());
					} else {
						order.setCustomerName("Unknown");
						order.setCustomerEmail("");
					}
					order.setOtp(otp);
					order.setItems(cartItems);
				} catch (Exception e) {
					System.err.println("Skipping order #" + order.getId() + ": " + e.getMessage());
				}
			}
			request.setAttribute("orders", orders);
			request.getRequestDispatcher("CustomerOrders.jsp").forward(request, response);
		} catch (Exception e) {
			throw new ServletException("Failed to load customer orders", e);
		}
	}

	@Override
	protected void doPost(HttpServletRequest request, HttpServletResponse response)
			throws ServletException, IOException {
		String action = request.getParameter("action");
		String orderIdRaw = request.getParameter("orderId");
		if (orderIdRaw == null) {
			response.sendError(HttpServletResponse.SC_BAD_REQUEST, "Missing orderId");
			return;
		}
		int orderId = Integer.parseInt(orderIdRaw);

		if (action == null) {
			response.sendError(HttpServletResponse.SC_BAD_REQUEST, "Missing action");
			return;
		}

		boolean isAjax = "XMLHttpRequest".equalsIgnoreCase(request.getHeader("X-Requested-With"));

		try {
			if ("updateStatus".equals(action)) {
				String status = request.getParameter("status");
				orderDAO.updateOrderStatus(orderId, status);
				response.sendRedirect("CustomerOrdersServlet");

			} else if ("cancelOrder".equals(action)) {
				// ── CUSTOMER-INITIATED CANCELLATION ──────────────────────────
				// Full tiered refund logic mirrors AIChatServlet.handleCancelOrder()
				// and OrderServlet.cancelOrder(). Refund is staged as "Pending Refund"
				// and requires staff to process via the Orders Dashboard.
				cancelCustomerOrder(request, response, orderId, isAjax);

			} else {
				response.sendError(HttpServletResponse.SC_BAD_REQUEST, "Unknown action: " + action);
			}
		} catch (Exception e) {
			if (isAjax) {
				response.setContentType("application/json");
				response.setCharacterEncoding("UTF-8");
				response.setStatus(500);
				String msg = e.getMessage() != null ? e.getMessage().replace("\"", "'") : "Server error";
				try {
					response.getWriter().write("{\"success\":false,\"message\":\"" + msg + "\"}");
				} catch (IOException ignored) {
				}
			} else {
				throw new ServletException(e);
			}
		}
	}

	// ─────────────────────────────────────────────────────────────────────────
	// ── CUSTOMER CANCEL ORDER ────────────────────────────────────────────────
	//
	// Tiered refund policy (matches OrderServlet and AIChatServlet exactly):
	//
	// Stage Online PAID refund COD refund
	// ─────────────────────────────────────────────────────────
	// Ordered/Pending/Confirmed 100% N/A (nothing collected)
	// Assigned/Packed 95% (5% fee) N/A
	// Shipped/Out for Delivery 90% (10% fee) N/A
	// Delivered / terminal ❌ Not cancellable → suggest return
	//
	// For online PAID orders the refund is NOT credited immediately.
	// order_returns.status is set to "Pending Refund" and staff must
	// manually click "Process Refund" in the Orders Dashboard.
	// This mirrors how real e-commerce platforms (Swiggy, Amazon) work —
	// refunds are queued and processed within 3–5 business days.
	//
	// For COD orders: order is cancelled but no money is moved because
	// cash-on-delivery means payment was never collected upfront.
	// ─────────────────────────────────────────────────────────────────────────
	private void cancelCustomerOrder(HttpServletRequest request, HttpServletResponse response, int orderId,
			boolean isAjax) throws Exception {

		// Verify ownership — customer can only cancel their own orders
		Object customerIdAttr = request.getSession().getAttribute("customerId");
		if (customerIdAttr == null) {
			sendJson(response, false, "Session expired. Please log in again.");
			return;
		}
		int customerId = (int) customerIdAttr;

		Order order = orderDAO.getOrderById(orderId);
		if (order == null) {
			sendJson(response, false, "Order not found.");
			return;
		}
		if (order.getCustomerId() != customerId) {
			response.sendError(HttpServletResponse.SC_FORBIDDEN, "Not your order.");
			return;
		}

		String currentStatus = order.getStatus();
		boolean isPaid = "PAID".equalsIgnoreCase(order.getPaymentStatus());
		boolean isCod = "PENDING_COD".equalsIgnoreCase(order.getPaymentStatus());
		double totalAmount = order.getTotalAmount();

		// ── GATE: terminal and in-return states cannot be cancelled ──────────
		if ("Delivered".equalsIgnoreCase(currentStatus) || "Completed".equalsIgnoreCase(currentStatus)) {
			sendJson(response, false,
					"This order has already been delivered. To get a refund, please raise a Return request within 10 days.");
			return;
		}
		if ("Cancelled".equalsIgnoreCase(currentStatus) || "Refunded".equalsIgnoreCase(currentStatus)
				|| "Replaced".equalsIgnoreCase(currentStatus)) {
			sendJson(response, false, "This order is already " + currentStatus.toLowerCase() + ".");
			return;
		}
		if (currentStatus != null && currentStatus.startsWith("Return")) {
			sendJson(response, false, "This order is already in the return pipeline and cannot be cancelled.");
			return;
		}

		String cancelReason = request.getParameter("cancelReason");
		if (cancelReason == null || cancelReason.isBlank()) {
			cancelReason = "Customer requested cancellation";
		}

		// ── Tiered refund calculation ─────────────────────────────────────────
		double refundAmount = 0.0;
		double deductionAmount = 0.0;
		String deductionReason = "No refund applicable";

		if (isPaid) {
			switch (currentStatus != null ? currentStatus : "") {
			case "Ordered":
			case "Pending":
			case "Confirmed":
				// Pre-shipment: full refund — order hasn't been processed yet.
				// This is the only stage where 100% is refunded.
				refundAmount = totalAmount;
				deductionReason = "Full refund — order not yet processed";
				break;

			case "Assigned":
			case "Picked Up":
				// Order assigned to agent or picked from warehouse:
				// 5% handling fee retained (warehouse processing cost).
				deductionAmount = totalAmount * 0.05;
				refundAmount = totalAmount - deductionAmount;
				deductionReason = "5% handling fee deducted (order was assigned to delivery agent)";
				break;

			case "Packed":
				// Packed and ready for dispatch: 5% packing charge retained.
				deductionAmount = totalAmount * 0.05;
				refundAmount = totalAmount - deductionAmount;
				deductionReason = "5% packing charge deducted (order was packed)";
				break;

			case "Shipped":
			case "Out for Delivery":
				// In transit or out for delivery: 10% shipping charge retained.
				// Mirrors real-world policy (Flipkart/Meesho charge ~10% for
				// in-transit cancellations because the courier is already engaged).
				deductionAmount = totalAmount * 0.10;
				refundAmount = totalAmount - deductionAmount;
				deductionReason = "10% shipping/handling charge deducted (order was already in transit)";
				break;

			default:
				deductionReason = "No refund applicable at this stage";
				break;
			}
		}
		// COD: refundAmount stays 0 — nothing was paid upfront.

		// ── Build / update order_returns record ──────────────────────────────
		OrderReturn rr = returnDAO.getReturnByOrderId(orderId);
		if (rr == null) {
			rr = new OrderReturn();
			rr.setOrderId(orderId);
			rr.setCustomerId(customerId);
			rr.setType("Cancellation");
		}
		rr.setReason("CANCELLED by customer: " + cancelReason + " | " + deductionReason);
		rr.setRefundAmount(refundAmount);

		if (isPaid && refundAmount > 0) {
			// DO NOT credit wallet here. Set to Pending Refund so staff reviews
			// and explicitly processes via processDirectRefund() on the dashboard.
			// This is correct real-world behaviour: refunds are reviewed before
			// being credited, not automatic.
			rr.setStatus("Pending Refund");
			rr.setRefundMethod("wallet"); // default; staff can change on dashboard
			rr.setRefundTransactionId(null);
		} else if (isCod) {
			rr.setStatus("No Refund - COD");
			rr.setRefundMethod(null);
			rr.setRefundTransactionId(null);
		} else {
			rr.setStatus("No Refund Applicable");
		}

		returnDAO.upsertReturnRecord(rr);
		orderDAO.updateOrderStatus(orderId, "Cancelled");

		if (isCod) {
			orderDAO.updatePaymentStatus(orderId, "COD_CANCELLED", null);
		}

		// ── Restock if goods were in motion ──────────────────────────────────
		boolean wasMoving = "Packed".equals(currentStatus) || "Assigned".equals(currentStatus)
				|| "Picked Up".equals(currentStatus) || "Shipped".equals(currentStatus)
				|| "Out for Delivery".equals(currentStatus);
		if (wasMoving) {
			List<CartItem> items = orderDAO.getOrderItems(orderId);
			for (CartItem item : items) {
				productDAO.incrementStock(item.getProductId(), item.getQuantity());
			}
		}

		// ── Notify staff ──────────────────────────────────────────────────────
		try {
			String notifMsg = String.format("🚫 Order #%d CANCELLED by customer #%d. Stage: %s. Reason: %s. %s",
					orderId, customerId, currentStatus, cancelReason,
					(isPaid && refundAmount > 0) ? String.format("Refund ₹%.2f pending approval.", refundAmount)
							: (isCod ? "COD order — no refund." : ""));
			StaffNotification n = new StaffNotification();
			n.setOrderId(orderId);
			n.setActionRequired(notifMsg);
			notifDAO.insert(n);
		} catch (Exception ex) {
			System.err.println("Cancel notification failed: " + ex.getMessage());
		}

		// ── Build response message ────────────────────────────────────────────
		String refundMsg;
		if (isCod) {
			refundMsg = "Your order has been cancelled. This was a Cash on Delivery order — no payment was collected, so no refund is needed.";
		} else if (isPaid && refundAmount > 0 && deductionAmount > 0) {
			refundMsg = String.format(
					"Order cancelled. Refund of ₹%.2f is pending staff approval (₹%.2f deducted as %s). "
							+ "You will receive the refund within 3–5 business days once approved.",
					refundAmount, deductionAmount, deductionReason);
		} else if (isPaid && refundAmount > 0) {
			refundMsg = String.format("Order cancelled. Full refund of ₹%.2f is pending staff approval. "
					+ "You will receive it within 3–5 business days.", refundAmount);
		} else {
			refundMsg = "Order cancelled. No refund is applicable for this order's stage.";
		}

		if (isAjax) {
			sendJson(response, true, refundMsg);
		} else {
			response.sendRedirect("CustomerOrdersServlet");
		}
	}

	private void sendJson(HttpServletResponse response, boolean success, String message) throws IOException {
		response.setContentType("application/json");
		response.setCharacterEncoding("UTF-8");
		String safe = message != null ? message.replace("\"", "'") : "";
		response.getWriter().write("{\"success\":" + success + ",\"message\":\"" + safe + "\"}");
	}
}
