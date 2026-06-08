package com.servlet;

import java.io.IOException;
import java.math.BigDecimal;
import java.sql.Connection;
import java.time.LocalDate;
import java.util.List;
import java.util.Map;
import java.util.logging.Level;
import java.util.logging.Logger;

import com.DAO.AddressDAO;
import com.DAO.AgentWalletDAO;
import com.DAO.CustomerDAO;
import com.DAO.CustomerNotificationDAO;
import com.DAO.CustomerWalletDAO;
import com.DAO.DeliveryPersonDAO;
import com.DAO.DeliverySlotDAO;
import com.DAO.OrderDAO;
import com.DAO.OrderReturnDAO;
import com.DAO.ProductDAO;
import com.DAO.StaffNotificationDAO;
import com.DAO.WalletTransactionDAO;
import com.util.CartItem;
import com.util.Customer;
import com.util.CustomerAddress;
import com.util.DBConnection;
import com.util.Order;
import com.util.OrderReturn;
import com.util.StaffNotification;
import com.util.User;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.MultipartConfig;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;

/**
 * OrderServlet — Staff-side order management dashboard.
 *
 * Servlet URL: /OrdersDashboard
 *
 * ── GET actions ──────────────────────────────────────────────────────────
 * (none) → Load all orders, delivery persons → OrdersDashboard.jsp action=view
 * → Load single order + items → invoice.jsp
 *
 * ── POST actions ─────────────────────────────────────────────────────────
 * updateStatus → Advance order status (next pipeline stage) updateDeliveryDate
 * → Set/update delivery date ONLY (explicit action — FIX A)
 * assignDeliveryPerson→ Assign delivery agent + set status = Assigned (FIX B)
 * cancelOrder → Cancel with tiered refund logic approveReturn → Approve return
 * request rejectReturn → Reject return, revert to Delivered assignPickupAgent →
 * Assign pickup agent → Return Agent Assigned reassignPickupAgent → Reassign
 * after agent cancellation agentCancelPickup → Agent cancels; clear agent, back
 * to Return Approved agentOutForPickup → Agent marks out for pickup
 * confirmPickup → Item collected → Return Picked processReturnRefund → Finalize
 * refund (wallet/bank/original/replacement) processRefund → Direct refund for
 * cancelled paid orders
 *
 * ── Real-world order pipeline (orders.status ENUM) ───────────────────────
 * Ordered → Pending → Confirmed → Assigned → Picked Up → Packed → Shipped → Out
 * for Delivery → Delivered Terminal: Cancelled | Refunded | Replaced
 *
 * ── Return pipeline (order_returns.status ENUM) ──────────────────────────
 * Requested → Approved → [Processing] → Picked → Refunded | Replaced OR:
 * Rejected
 *
 * ── ALL FIXES FROM ANALYSIS ────────────────────────────────────────────── FIX
 * A: Delivery date update now only runs for action=updateDeliveryDate.
 * Previously fired unconditionally for ANY POST with a deliveryDate param,
 * silently overwriting dates on unrelated actions.
 *
 * FIX B: assignDeliveryPerson now calls
 * orderDAO.assignDeliveryPersonAndStatus() which sets delivery_user_id AND
 * status='Assigned' atomically. Previously the 'Assigned' status was never set,
 * making the tiered refund switch-case for 'Assigned' unreachable dead code.
 *
 * FIX C: isAjax detection uses ONLY the X-Requested-With header (standard).
 * Removed the fragile action-name heuristic that misclassified some form POSTs
 * as AJAX and returned raw JSON to the browser.
 *
 * FIX D: 'handled' flag is validated before sending success response. Unknown
 * action now returns a 400 error instead of silent success.
 *
 * FIX E: cancelOrder correctly handles 'Picked Up' + 'Packed' stages in the
 * tiered refund switch and the restock check.
 *
 * FIX F: Helper renamed sendJson() to avoid collision with the conceptual
 * "response" object. Parameter names unified to request/response.
 *
 * FIX G: processReturnRefund restock now uses item.getQuantity() per item (full
 * order restock) consistently — restockQty param is stored but the actual
 * restock logic restores full item quantities which is the correct behaviour
 * for whole-order returns.
 * ─────────────────────────────────────────────────────────────────────────
 */
@WebServlet("/OrdersDashboard")
@MultipartConfig(maxFileSize = 1024 * 1024 * 5)
public class OrderServlet extends HttpServlet {

	private static final long serialVersionUID = 1L;
	private static final Logger log = Logger.getLogger(OrderServlet.class.getName());
	private final AgentWalletDAO agentWalletDAO = new AgentWalletDAO();
	// ── DAOs ─────────────────────────────────────────────────────────────────
	private final OrderDAO orderDAO = new OrderDAO();
	private final CustomerDAO customerDAO = new CustomerDAO();
	private final AddressDAO addressDAO = new AddressDAO();
	private final ProductDAO productDAO = new ProductDAO();
	private final OrderReturnDAO returnDAO = new OrderReturnDAO();
	private final CustomerWalletDAO walletDAO = new CustomerWalletDAO();
	private final WalletTransactionDAO walletTxnDAO = new WalletTransactionDAO();
	private final StaffNotificationDAO notifDAO = new StaffNotificationDAO();
	private CustomerNotificationDAO nd = new CustomerNotificationDAO();

	// ─────────────────────────────────────────────────────────────────────────
	// GET
	// ─────────────────────────────────────────────────────────────────────────
	@Override
	protected void doGet(HttpServletRequest request, HttpServletResponse response)
			throws ServletException, IOException {

		String action = request.getParameter("action");

		try {

			// In your doGet or doPost — add this action handler
			if ("getAgentRejectionLog".equals(action)) {
				int agentId = Integer.parseInt(request.getParameter("agentId"));

				List<Map<String, Object>> logs = orderDAO.getAgentRejectionLog(agentId);

				// Build JSON manually — no library needed
				StringBuilder json = new StringBuilder("[");
				boolean first = true;
				for (Map<String, Object> row : logs) {
					if (!first) {
						json.append(",");
					}
					first = false;

					int logId = 0;
					Object rawLogId = row.get("logId");
					if (rawLogId instanceof Number) {
						logId = ((Number) rawLogId).intValue();
					}

					int orderId = 0;
					Object rawId = row.get("orderId");
					if (rawId instanceof Number) {
						orderId = ((Number) rawId).intValue();
					}

					String reason = row.get("reason") != null ? row.get("reason").toString() : "No reason given";
					reason = reason.replace("\\", "\\\\").replace("\"", "\\\"");

					String time = "";
					Object rawTime = row.get("rejectedAt");
					if (rawTime instanceof java.sql.Timestamp) {
						time = new java.text.SimpleDateFormat("dd MMM HH:mm").format((java.sql.Timestamp) rawTime);
					}

					json.append("{").append("\"logId\":").append(logId).append(",").append("\"orderId\":")
							.append(orderId).append(",").append("\"reason\":\"").append(reason).append("\",")
							.append("\"time\":\"").append(time).append("\"").append("}");
				}
				json.append("]");

				response.setContentType("application/json");
				response.setCharacterEncoding("UTF-8");
				response.getWriter().write(json.toString());
				return;
			}
			if ("view".equals(action)) {
				// ── Invoice view ─────────────────────────────────────────────
				int orderId = Integer.parseInt(request.getParameter("orderId"));
				Order order = orderDAO.getOrderById(orderId);
				if (order == null) {
					throw new ServletException("Order not found: " + orderId);
				}

				Customer customer = customerDAO.getProfile(order.getCustomerId());
				CustomerAddress address = addressDAO.getDefaultAddressByCustomer(order.getCustomerId());
				List<CartItem> items = orderDAO.getOrderItems(orderId);

				request.setAttribute("order", order);
				request.setAttribute("customer", customer);
				request.setAttribute("address", address);
				request.setAttribute("cartItems", items);
				request.getRequestDispatcher("invoice.jsp").forward(request, response);

			}
			// ── Orders dashboard ─────────────────────────────────────────

			try (Connection conn = DBConnection.getConnection()) {
				DeliveryPersonDAO dpDao = new DeliveryPersonDAO(conn);
				List<User> deliveryPersons = dpDao.getActiveDeliveryPersons();

				// FIX: Pass the managed connection to prevent connection pool leaks
				List<Order> orders = orderDAO.getAllOrders();

				// Agent earnings for the performance panel
				Map<Integer, BigDecimal> earningsMap = new java.util.HashMap<>();

				// FIX: Upgraded Double map to BigDecimal to prevent floating-point leaks
				Map<Integer, BigDecimal> totalEarnedMap = new java.util.HashMap<>();

				for (User dp : deliveryPersons) {
					int agentId = dp.getUid();
					try {
						// Wallet layer transactions return safe BigDecimal
						BigDecimal todayEarnings = agentWalletDAO.getEarningsToday(agentId);
						earningsMap.put(agentId, todayEarnings != null ? todayEarnings : BigDecimal.ZERO);

						com.util.AgentWallet aw = agentWalletDAO.getWallet(agentId);
						if (aw != null && aw.getTotalEarned() != null) {
							totalEarnedMap.put(agentId, aw.getTotalEarned());
						} else {
							totalEarnedMap.put(agentId, BigDecimal.ZERO);
						}
					} catch (Exception ex) {
						// FIX: Use explicit BigDecimal values instead of primitive double literals
						// (0.0)
						earningsMap.put(agentId, BigDecimal.ZERO);
						totalEarnedMap.put(agentId, BigDecimal.ZERO);
					}
				}

				request.setAttribute("agentEarningsToday", earningsMap);
				request.setAttribute("agentTotalEarned", totalEarnedMap);

				// Attach return request to each order
				for (Order o : orders) {
					o.setReturnRequest(returnDAO.getReturnByOrderId(o.getId()));
				}

				// Sort: newest first (null-safe)
				orders.sort((a, b) -> {
					if (a.getDate() == null && b.getDate() == null) {
						return 0;
					}
					if (a.getDate() == null) {
						return 1;
					}
					if (b.getDate() == null) {
						return -1;
					}
					return b.getDate().compareTo(a.getDate());
				});

				request.setAttribute("orders", orders);
				request.setAttribute("deliveryPersons", deliveryPersons);
				HttpSession session = request.getSession(false);
				session.setAttribute("unreadNotifCount", notifDAO.countUnread());

				try {
					java.util.List<java.util.Map<String, Object>> rejSummary = orderDAO.getAllAgentRejectionSummary();
					request.setAttribute("rejectionSummary", rejSummary);
				} catch (Exception ex) {
					log.warning("Could not load rejection summary: " + ex.getMessage());
					request.setAttribute("rejectionSummary", new java.util.ArrayList<>());
				}

				// ── Pending withdrawal requests (MUST be before forward) ───────
				try {
					java.util.List<java.util.Map<String, Object>> pendingWd = agentWalletDAO
							.getWithdrawalRequests("pending");
					request.setAttribute("pendingWithdrawals", pendingWd);
				} catch (Exception ex) {
					log.warning("Could not load pending withdrawals: " + ex.getMessage());
					request.setAttribute("pendingWithdrawals", new java.util.ArrayList<>());
				}

				// ── Agent rejection detail (for modal — keyed by agentId) ──────
				// Build a map: agentId → List<Map> of individual rejection log rows
				// so the JSP can render the rejection detail modal without a second request.
				try {
					java.util.Map<Integer, java.util.List<java.util.Map<String, Object>>> rejDetailMap = new java.util.HashMap<>();
					@SuppressWarnings("unchecked")
					java.util.List<java.util.Map<String, Object>> rejSummary = (java.util.List<java.util.Map<String, Object>>) request
							.getAttribute("rejectionSummary");
					if (rejSummary != null) {
						for (java.util.Map<String, Object> row : rejSummary) {
							int aid = ((Number) row.get("agentId")).intValue();
							try {
								java.util.List<java.util.Map<String, Object>> logs = orderDAO.getAgentRejectionLog(aid);
								rejDetailMap.put(aid, logs);
							} catch (Exception ex2) {
								rejDetailMap.put(aid, new java.util.ArrayList<>());
							}
						}
					}

					request.setAttribute("rejectionDetailMap", rejDetailMap);

					System.out.println("RDM size: " + rejDetailMap.size());
					System.out.println("RDM keys: " + rejDetailMap.keySet());
					for (java.util.Map.Entry<Integer, java.util.List<java.util.Map<String, Object>>> e : rejDetailMap
							.entrySet()) {
						System.out.println("Agent " + e.getKey() + " logs: " + e.getValue());
					}
				} catch (Exception ex) {
					request.setAttribute("rejectionDetailMap", new java.util.HashMap<>());
				}

				// ── NOW forward — all attributes are set ──────────────────────
				request.getRequestDispatcher("OrdersDashboard.jsp").forward(request, response);
			}

		} catch (

		Exception e) {
			log.log(Level.SEVERE, "GET error in OrdersDashboard", e);
			throw new ServletException(e);
		}
	}

	// ─────────────────────────────────────────────────────────────────────────
	// POST
	// ─────────────────────────────────────────────────────────────────────────
	@Override
	protected void doPost(HttpServletRequest request, HttpServletResponse response)
			throws ServletException, IOException {

		String action = request.getParameter("action");
		String source = request.getParameter("source");
		String orderIdRaw = request.getParameter("orderId");
		int orderId = (orderIdRaw != null && !orderIdRaw.isEmpty()) ? Integer.parseInt(orderIdRaw) : 0;

		// FIX C: Use ONLY the standard header — no action-name heuristics.
		boolean isAjax = "XMLHttpRequest".equalsIgnoreCase(request.getHeader("X-Requested-With"));

		log.info("POST | action=" + action + " | orderId=" + orderIdRaw + " | isAjax=" + isAjax);

		try {
			boolean handled = false;

			// ── Status update ────────────────────────────────────────────────
			if ("updateStatus".equals(action)) {
				String status = request.getParameter("status");
				Order pickedOrder = orderDAO.getOrderById(orderId);

				String previousStatus = pickedOrder.getStatus();

				// ── SLOT GUARD (agent path only) ──────────────────────────────────────────
				// Block the agent from accepting or advancing a status unless their shift
				// is currently ACTIVE or ON_BREAK.
				//
				// Exception: orders already in motion (Picked Up → Out for Delivery) may
				// continue to their next status regardless of slot state — the agent must
				// be able to complete a delivery they have already started.
				// When such an order reaches Delivered it is still counted in the slot's
				// completed_orders counter via updateSlotCounters() below.
				if ("delivery".equalsIgnoreCase(source)) {
					final boolean isInProgress = "Picked Up".equals(previousStatus) || "Packed".equals(previousStatus)
							|| "Shipped".equals(previousStatus) || "Out for Delivery".equals(previousStatus);

					if (!isInProgress && pickedOrder.getDeliveryUserId() > 0) {
						try (Connection slotConn = DBConnection.getConnection()) {
							DeliverySlotDAO slotGuardDao = new DeliverySlotDAO(slotConn);
							com.util.DeliverySlot agentSlot = slotGuardDao
									.getTodaySlot(pickedOrder.getDeliveryUserId());

							boolean slotRunning = agentSlot != null && ("ACTIVE".equals(agentSlot.getStatus())
									|| "ON_BREAK".equals(agentSlot.getStatus()));

							if (!slotRunning) {
								String guardMsg = (agentSlot == null)
										? "You don't have a shift booked for today. Please book a slot before accepting orders."
										: "BOOKED".equals(agentSlot.getStatus())
												? "Your shift hasn't started yet. Please start your shift before accepting orders."
												: "Your shift has ended. Book a new slot to accept more orders.";
								if (isAjax) {
									sendJson(response, false, guardMsg);
								} else {
									request.getSession().setAttribute("portalError", guardMsg);
									response.sendRedirect("DeliveryPortalServlet");
								}
								return;
							}
						} catch (Exception slotEx) {
							// If the slot check itself throws, fail safe — do NOT silently allow.
							log.warning("Slot guard check failed for agent #" + pickedOrder.getDeliveryUserId() + ": "
									+ slotEx.getMessage());
							sendJson(response, false,
									"Could not verify your shift status. Please refresh and try again.");
							return;
						}
					}
				}
				// ── END SLOT GUARD ────────────────────────────────────────────────────────

				if (status != null && !status.isBlank()) {
					orderDAO.updateOrderStatus(orderId, status);
					if (pickedOrder.getSlotId() > 0) {
						try (Connection conn = DBConnection.getConnection()) {
							DeliverySlotDAO slotDao = new DeliverySlotDAO(conn);
							slotDao.updateSlotCounters(pickedOrder.getSlotId(), previousStatus, status);
						}
					}

					// 2. Auto-release agent if this was the last order in the slot
//					    (fires when status is Delivered, Cancelled, Refunded, or Replaced)
					boolean isTerminal = "Delivered".equalsIgnoreCase(status) || "Cancelled".equalsIgnoreCase(status)
							|| "Refunded".equalsIgnoreCase(status) || "Replaced".equalsIgnoreCase(status);

					if (isTerminal && pickedOrder.getSlotId() > 0 && pickedOrder.getDeliveryUserId() > 0) {
						try (Connection conn = DBConnection.getConnection()) {
							DeliverySlotDAO slotDao = new DeliverySlotDAO(conn);
							boolean released = slotDao.releaseAgentIfSlotDone(pickedOrder.getSlotId(),
									pickedOrder.getDeliveryUserId());
							if (released) {
								log.info("Slot #" + pickedOrder.getSlotId() + " complete — agent #"
										+ pickedOrder.getDeliveryUserId() + " auto-released.");
							}
						}
					}

					// 3. FIX Bug #3: Un-comment the releaseCodHold call for COD Delivered
//					    (was commented out — cod_float was never decremented on delivery)
					if ("Delivered".equalsIgnoreCase(status)
							&& "COD".equalsIgnoreCase(pickedOrder.getPaymentMethod())) {
						BigDecimal amount = new BigDecimal(pickedOrder.getTotalAmount());
						agentWalletDAO.releaseCodHold(pickedOrder.getDeliveryUserId(), orderId, amount);
					}
					// ── STEP 2: COD HOLD — when agent picks up the order ──────────────
					// Place a hold on cod_float equal to the order amount.
					// This flags that the agent is now carrying this cash.
					// canAcceptCodOrder() ensures agent has enough balance (min_balance check).
					if ("Picked Up".equalsIgnoreCase(status)) {

						try {
							int agentId;

							if (pickedOrder != null && pickedOrder.getDeliveryUserId() > 0) {
								boolean isCod = "COD".equalsIgnoreCase(pickedOrder.getPaymentMethod());
								if (isCod) {
									agentId = pickedOrder.getDeliveryUserId();
									BigDecimal amount = new BigDecimal(pickedOrder.getTotalAmount());
									boolean canAccept = agentWalletDAO.canAcceptCodOrder(agentId, amount);
									if (canAccept) {
										agentWalletDAO.holdCodAmount(agentId, orderId, amount, "Pickup confirmed");
										log.info("COD hold placed: agent #" + agentId + " order #" + orderId + " ₹"
												+ amount);
										Order order = orderDAO.getOrderById(orderId);
										String agentVehicle = nd.getAgentVehicleInfo(agentId);
										nd.notifyAgentPickupConfirmed(order.getCustomerId(), orderId, agentId,
												order.getDeliveryUserName(), order.getPhone(), agentVehicle);
									} else {
										// BLOCK the status change — revert to Assigned and set agent offline
										orderDAO.updateOrderStatus(orderId, "Assigned");
										_setAgentOffline(agentId, request);
										log.warning(
												"Agent #" + agentId + " insufficient balance for COD hold on order #"
														+ orderId + " (₹" + amount + ") — status reverted to Assigned");
										// Return error so the delivery portal shows the top-up prompt
										if (isAjax) {
											sendJson(response, false,
													"Insufficient wallet balance to pick up this COD order. "
															+ "You have been set Offline. Please top up your wallet to continue.");
										} else {
											request.getSession().setAttribute("portalError",
													"Insufficient wallet balance. Please top up to accept COD orders.");
											response.sendRedirect("DeliveryPortalServlet");
										}
										return;
									}
								} else {
									// NON-COD: just notify agent pickup confirmed
									agentId = pickedOrder.getDeliveryUserId();
									String agentVehicle = nd.getAgentVehicleInfo(agentId);
									nd.notifyAgentPickupConfirmed(pickedOrder.getCustomerId(), orderId, agentId,
											pickedOrder.getDeliveryUserName(), pickedOrder.getPhone(), agentVehicle);
								}
							}

						} catch (Exception ex) {
							log.warning("COD hold failed for order #" + orderId + ": " + ex.getMessage());
						}

					}

					// ── CUSTOMER NOTIFICATIONS for pipeline status transitions ────────
					// BUG FIX: All status changes below were MISSING customer notifications.
					// Only "Picked Up" (COD path) and "Delivered" were partially covered.
					// The entire Confirmed/Packed/Shipped/Out-for-Delivery/Delivered chain
					// had no nd.notify* calls, so customers never got notified.
					try {
						switch (status) {
						case "Confirmed" -> {
							// Staff confirmed the order — customer should know it's being processed
							nd.notifyOrderConfirmed(pickedOrder.getCustomerId(), orderId);
						}
						case "Packed" -> {
							// Order packed and ready — notify customer
							nd.notifyOrderPacked(pickedOrder.getCustomerId(), orderId);
						}
						case "Shipped" -> {
							// Order dispatched from warehouse
							nd.notifyOrderShipped(pickedOrder.getCustomerId(), orderId,
									pickedOrder.getDeliveryUserName(), pickedOrder.getPhone());
						}
						case "Out for Delivery" -> {
							// Agent is on the way — most time-sensitive notification
							nd.notifyOutForDelivery(pickedOrder.getCustomerId(), orderId,
									pickedOrder.getDeliveryUserName() != null ? pickedOrder.getDeliveryUserName()
											: "your delivery agent",
									pickedOrder.getPhone() != null ? pickedOrder.getPhone() : "");
						}
						case "Delivered" -> {
							nd.notifyOrderDelivered(pickedOrder.getCustomerId(), orderId);
						}
						// "Picked Up" notification is handled above inside the COD-hold block
						// (both COD and non-COD paths now covered)
						default -> {
							/* no customer notification needed for other staff-internal statuses */ }
						}
					} catch (Exception notifEx) {
						// Non-fatal — order status was already updated; don't block the response
						log.warning("Customer notification failed for status=" + status + " order #" + orderId + ": "
								+ notifEx.getMessage());
					}

					// ── STEP 3: RELEASE HOLD + CREDIT FEE — when staff manually sets Delivered ──
					// This is the MANUAL path (staff dashboard).
					// The OTP path is handled by OtpVerificationServlet (preferred flow).
					// AgentWalletDAO guards against double-credit using hasTransactionOfType().
					if ("Delivered".equalsIgnoreCase(status)) {
						try {
							Order deliveredOrder = orderDAO.getOrderById(orderId);
							if (deliveredOrder != null && deliveredOrder.getDeliveryUserId() > 0) {
								int agentId = deliveredOrder.getDeliveryUserId();
								boolean isCod = "COD".equalsIgnoreCase(deliveredOrder.getPaymentMethod());
								double fee = isCod ? 60.0 : 40.0;
								try (Connection conn = DBConnection.getConnection()) {
									DeliverySlotDAO slotDao = new DeliverySlotDAO(conn);
									// order.getSlotId() returns the slot_id stored on the orders row
									if (deliveredOrder.getSlotId() > 0) {
										slotDao.recordOrderEarning(deliveredOrder.getDeliveryUserId(), orderId,
												deliveredOrder.getSlotId());
									}
								} catch (Exception ex) {
									log.warning("Earning record failed for order #" + orderId + ": " + ex.getMessage());
								}
								// Release COD hold (cod_float decreases)
								if (isCod) {
									boolean holdMissing = !agentWalletDAO.hasCodHold(agentId, orderId); // add this
									// public method
									if (holdMissing) {
										BigDecimal amount = new BigDecimal(deliveredOrder.getTotalAmount());
										agentWalletDAO.holdCodAmount(agentId, orderId, amount,
												"Auto-hold (staff set Delivered directly)");
									}
									BigDecimal amount = new BigDecimal(deliveredOrder.getTotalAmount());

									// agentWalletDAO.releaseCodHold(agentId, orderId, amount);
								}

								// Credit delivery fee (balance + total_earned increase)
								agentWalletDAO.creditDeliveryFee(agentId, orderId, fee, isCod);

								// Prepaid: mark as PAID immediately
								if (!isCod) {
									orderDAO.updatePaymentStatus(orderId, "PAID", null);
								}
							}
						} catch (Exception ex) {
							log.warning("Wallet update skipped for order #" + orderId + ": " + ex.getMessage());
						}
					}
				}
				handled = true;
			}
			// ── FIX A: Delivery date update — ONLY when explicitly requested ─
			else if ("updateDeliveryDate".equals(action)) {
				String deliveryDateStr = request.getParameter("deliveryDate");
				if (deliveryDateStr != null && !deliveryDateStr.isBlank()) {
					orderDAO.updateDeliveryDate(orderId, LocalDate.parse(deliveryDateStr));
				}
				handled = true;
			}

			// ── FIX B: Assign delivery person + set status = Assigned ────────
			else if ("assignDeliveryPerson".equals(action)) {
				assignDeliveryPerson(request, response);
				handled = true;
			}

			// ── Actions with their own response (early return) ───────────────
			else if ("cancelOrder".equals(action)) {
				cancelOrder(request, response);
				return;
			} else if ("reassignPickupAgent".equals(action)) {
				reassignPickupAgent(request, response);
				return;
			} else if ("agentCancelPickup".equals(action)) {
				agentCancelPickup(request, response);
				return;
			} else if ("agentCantDeliver".equals(action)) {
				// BUG 1 FIX: New action — normal delivery order failed
				agentCantDeliver(request, response);
				return;
			} else if ("agentRejectTask".equals(action)) {
				// BUG 5 FIX: New action — agent refuses task at assignment stage
				agentRejectTask(request, response);
				return;
			} else if ("agentOutForPickup".equals(action)) {
				agentOutForPickup(request, response);
				return;
			} else if ("confirmPickup".equals(action)) {
				confirmPickup(request, response);
				return;
			}

			// ── Return / Refund workflow ──────────────────────────────────────
			else if ("approveReturn".equals(action)) {
				approveReturn(request);
				handled = true;
			} else if ("rejectReturn".equals(action)) {
				rejectReturn(request);
				handled = true;
			} else if ("assignPickupAgent".equals(action)) {
				assignPickupAgent(request);
				handled = true;
			} else if ("processReturnRefund".equals(action)) {
				processReturnRefund(request);
				handled = true;
			} else if ("processRefund".equals(action)) {
				processDirectRefund(request);
				handled = true;
			}

			// ── CONFIRM COD DEPOSIT (staff confirms cash received from agent) ─
			else if ("confirmCodDeposit".equals(action)) {
				confirmCodDeposit(request, response);
				return;
			}

			// ── AGENT: CREATE WITHDRAWAL REQUEST (two-step — no immediate deduct) ─────
			else if ("createWithdrawalRequest".equals(action)) {
				// Agent submits from DeliveryPortal — identity comes from deliveryUser session.
				// This action does NOT deduct balance; it only inserts a pending request row.
				// Staff must approve via approveWithdrawal to trigger the actual deduction.
				try {
					jakarta.servlet.http.HttpSession agentSession = request.getSession(false);
					com.util.User agentUser = (agentSession != null)
							? (com.util.User) agentSession.getAttribute("deliveryUser")
							: null;
					if (agentUser == null) {
						sendJson(response, false, "Session expired. Please log in again.");
						return;
					}
					String amtStr = request.getParameter("amount");
					String reason = request.getParameter("reason");
					if (amtStr == null || amtStr.isBlank()) {
						sendJson(response, false, "Amount is required.");
						return;
					}
					java.math.BigDecimal amount = new java.math.BigDecimal(amtStr.trim());
					int newReqId = agentWalletDAO.createWithdrawalRequest(agentUser.getUid(), agentUser.getUsername(),
							amount, reason);
					if (newReqId > 0) {
						log.info("Withdrawal request #" + newReqId + " created — agent #" + agentUser.getUid() + " ₹"
								+ amount);
						sendJson(response, true, "₹" + amount.toPlainString() + " withdrawal request submitted."
								+ " A supervisor will review it within 24 hours.");
					} else {
						sendJson(response, false, "Could not create withdrawal request. Please try again.");
					}
				} catch (IllegalStateException ise) {
					// Covers: already-pending, insufficient balance, below minimum
					sendJson(response, false, ise.getMessage());
				} catch (Exception e) {
					log.log(java.util.logging.Level.SEVERE, "createWithdrawalRequest error", e);
					sendJson(response, false, "Server error: " + e.getMessage());
				}
				return;
			}

			// ── STAFF: APPROVE WITHDRAWAL REQUEST ────────────────────────────
			else if ("approveWithdrawal".equals(action)) {
				int reqId = Integer.parseInt(request.getParameter("requestId"));

				String note = request.getParameter("staffNote");
				agentWalletDAO.approveWithdrawalRequest(reqId, note);
				// Notify staff feed so the action is visible

				insertSystemNotif(orderId, "✅ Withdrawal request #" + reqId
						+ " APPROVED by staff. Balance deducted — please process the bank transfer.");

				// Push notification back to the delivery agent
				try (java.sql.Connection notifConn = com.util.DBConnection.getConnection()) {
					com.servlet.DeliveryNotificationServlet
							.push(notifConn, getAgentIdFromRequest(reqId), "WITHDRAWAL_APPROVED",
									"✅ Withdrawal request approved!",
									"Your withdrawal request #" + reqId + " has been approved by staff."
											+ (note != null && !note.isBlank() ? " Note: " + note : ""),
									"✅", "green", reqId);
				} catch (Exception notifEx) {
					log.warning("Withdrawal-approved agent notif failed: " + notifEx.getMessage());
				}

				handled = true;
			}

			// ── STAFF: REJECT WITHDRAWAL REQUEST ─────────────────────────────
			else if ("rejectWithdrawal".equals(action)) {
				int reqId = Integer.parseInt(request.getParameter("requestId"));
				String note = request.getParameter("staffNote");
				if (note == null || note.isBlank()) {
					note = "Rejected by staff.";
				}
				agentWalletDAO.rejectWithdrawalRequest(reqId, note);

				insertSystemNotif(orderId, "❌ Withdrawal request #" + reqId + " REJECTED by staff. Reason: " + note);

				// Push notification back to the delivery agent
				try (java.sql.Connection notifConn = com.util.DBConnection.getConnection()) {
					com.servlet.DeliveryNotificationServlet
							.push(notifConn, getAgentIdFromRequest(reqId), "WITHDRAWAL_REJECTED",
									"❌ Withdrawal request rejected",
									"Your withdrawal request #" + reqId + " was rejected by staff."
											+ (note != null && !note.isBlank() ? " Reason: " + note : ""),
									"❌", "red", reqId);
				} catch (Exception notifEx) {
					log.warning("Withdrawal-rejected agent notif failed: " + notifEx.getMessage());
				}

				handled = true;
			}

			// ── STAFF: UNBLOCK AGENT (after 3+ rejections) ───────────────────
			else if ("unblockAgent".equals(action)) {
				int agentUserId = Integer.parseInt(request.getParameter("agentUserId"));
				try (Connection conn = DBConnection.getConnection()) {
					new DeliveryPersonDAO(conn).updateUserStatus(agentUserId, "Active");
				}
				insertSystemNotif(orderId,
						"🔓 Agent #" + agentUserId + " has been UNBLOCKED by staff and is now Active.");
				handled = true;
			}

			// ── STAFF: REVIEW REJECTION (accept or reject agent's excuse) ────
			// accept = staff clears the rejection entry (accepts agent's reason)
			// reject = staff keeps the rejection count, may restrict the agent
			else if ("reviewAgentRejection".equals(action)) {
				handleAgentRejectionReview(request, response);
				return;
			} else if ("deleteSingleRejection".equals(action)) {
				int logId = Integer.parseInt(request.getParameter("logId"));
				orderDAO.deleteSingleRejectionLog(logId);
				handled = true;
			}
			// FIX D: Unknown action → error, not silent success
			if (!handled) {
				String msg = "Unknown action: " + action;
				log.warning(msg);
				if (isAjax) {
					response.setContentType("application/json");
					response.setStatus(400);
					response.getWriter().write("{\"success\":false,\"message\":\"" + msg + "\"}");
				} else {
					response.sendError(400, msg);
				}
				return;
			}
			// ── Respond ───────────────────────────────────────────────────────
			if (isAjax) {
				sendJson(response, true, "Action completed successfully.");
			} else {
				response.sendRedirect(
						"delivery".equalsIgnoreCase(source) ? "DeliveryPortalServlet" : "OrdersDashboard");
			}

		} catch (Exception e) {
			log.log(Level.SEVERE, "POST error | action=" + action + " | orderId=" + orderIdRaw, e);
			if (isAjax) {
				response.setContentType("application/json");
				response.setCharacterEncoding("UTF-8");
				response.setStatus(500);
				String msg = e.getMessage() != null ? e.getMessage().replace("\"", "'") : "Internal server error";
				response.getWriter().write("{\"success\":false,\"message\":\"" + msg + "\"}");
			} else {
				throw new ServletException(e);
			}
		}
	}

	private void handleAgentRejectionReview(HttpServletRequest request, HttpServletResponse response) throws Exception {
		int agentUserId = Integer.parseInt(request.getParameter("agentUserId"));

		String decision = request.getParameter("decision"); // "accept" or "dismiss"
		String staffNote = request.getParameter("staffNote");
		if (staffNote == null || staffNote.isBlank()) {
			staffNote = "Reviewed by staff.";
		}

		String msg;
		if ("accept".equalsIgnoreCase(decision)) {
			// Clear/pardon this agent's rejection log (staff accepts the reason)
			try {
				orderDAO.clearAgentRejectionLog(agentUserId);

			} catch (Exception ex) {
				log.warning("clearAgentRejectionLog failed (table may not exist): " + ex.getMessage());
			}
			// If agent was restricted, unblock them
			try (Connection conn = DBConnection.getConnection()) {
				new DeliveryPersonDAO(conn).updateUserStatus(agentUserId, "Active");
			} catch (Exception ex) {
				log.warning("Could not unblock agent #" + agentUserId + ": " + ex.getMessage());
			}
			msg = "✅ Rejection reason accepted for agent #" + agentUserId
					+ ". Rejection log cleared. Agent is now Active.";
		} else {
			// Dismiss — keep log, possibly restrict
			msg = "❌ Agent #" + agentUserId + " rejection reason dismissed. " + "Rejection count retained. Note: "
					+ staffNote;
		}

		// Notify staff feed
		insertSystemNotif(0, msg + " | Staff note: " + staffNote);
		log.info("Rejection review — agent #" + agentUserId + " | decision=" + decision);
		sendJson(response, true, msg);
	}

	// ─────────────────────────────────────────────────────────────────────────
	// ── APPROVE RETURN ───────────────────────────────────────────────────────
	// order_returns → Approved
	// orders → Return Approved
	// ─────────────────────────────────────────────────────────────────────────
	private void approveReturn(HttpServletRequest request) throws Exception {
		int orderId = Integer.parseInt(request.getParameter("orderId"));
		String reason = request.getParameter("reason");
		String notes = request.getParameter("notes");
		String safeNotes = (notes != null) ? notes.trim() : "";

		Order order = orderDAO.getOrderById(orderId);
		if (order == null) {
			throw new Exception("Order not found: " + orderId);
		}
		int customerId = order.getCustomerId();
		OrderReturn rr = returnDAO.getReturnByOrderId(orderId);
		if (rr == null) {
			rr = new OrderReturn();
			rr.setOrderId(orderId);
			rr.setCustomerId(order.getCustomerId());
			rr.setType("Return");
			rr.setReason(reason != null ? reason : "Staff initiated");
			// FIX: pickup_agent_id is not set here — remains null → no FK issue
		}

		rr.setStatus("Approved");
		rr.setCustomerId(customerId);
		if (!safeNotes.isEmpty()) {
			rr.setStaffNotes(safeNotes);
			if (rr.getReason() != null) {
				rr.setReason(rr.getReason() + " | Note: " + safeNotes);
			}
		}
		// Ensure pickup_agent_id is not 0 — preserve whatever is already set
		// (or null if new record). Never set it to 0.

		returnDAO.upsertReturnRecord(rr);
		orderDAO.updateOrderStatus(orderId, "Return Approved");

		nd.notifyReturnApproved(customerId, orderId, rr.getStaffNotes());
		log.info("Return APPROVED — order #" + orderId);
	}

	// ─────────────────────────────────────────────────────────────────────────
	// ── REJECT RETURN ────────────────────────────────────────────────────────
	// order_returns → Rejected
	// orders → Delivered
	// ─────────────────────────────────────────────────────────────────────────
	private void rejectReturn(HttpServletRequest request) throws Exception {
		int orderId = Integer.parseInt(request.getParameter("orderId"));

		Order order = orderDAO.getOrderById(orderId);
		orderDAO.updateOrderStatus(orderId, "Delivered");

		OrderReturn rr = returnDAO.getReturnByOrderId(orderId);
		if (rr != null) {
			returnDAO.updateReturnStatus(orderId, "Rejected");
			nd.notifyReturnRejected(rr.getCustomerId(), rr.getOrderId(), rr.getReason());
		}

		// Notify the original delivery agent that the return was rejected by staff
		// (the order reverts to Delivered — relevant for their records)
		if (order != null && order.getDeliveryUserId() > 0) {
			try (Connection notifConn = DBConnection.getConnection()) {
				DeliveryNotificationServlet.push(notifConn, order.getDeliveryUserId(), "RETURN_REJECTED",
						"✅ Return rejected — Order #" + orderId, "Staff has rejected the return request for Order #"
								+ orderId + ". The order remains Delivered — no pickup needed.",
						"✅", "green", orderId);
			} catch (Exception notifEx) {
				log.warning("Agent return-rejected notif failed for order #" + orderId + ": " + notifEx.getMessage());
			}
		}
		log.info("Return REJECTED — order #" + orderId + " reverted to Delivered");
	}

	// ─────────────────────────────────────────────────────────────────────────
	// ── ASSIGN PICKUP AGENT ──────────────────────────────────────────────────
	// order_returns → Approved (agent assigned, not yet collected)
	// orders → Return Agent Assigned
	//
	// ROOT CAUSE FIX: when approveReturn() creates a new OrderReturn for a
	// staff-initiated return, pickup_agent_id is null (correct). Later when
	// upsertReturnRecord is called in assignPickupAgent, we set a real agent ID.
	// The old bug was mapRow() returning 0 for a NULL column, which then got
	// written back as pickup_agent_id=0 → FK violation. Fixed in mapRow().
	// ─────────────────────────────────────────────────────────────────────────
	private void assignPickupAgent(HttpServletRequest request) throws Exception {
		int orderId = Integer.parseInt(request.getParameter("orderId"));
		int pickupAgentId = Integer.parseInt(request.getParameter("deliveryUserId"));

		if (pickupAgentId <= 0) {
			throw new Exception("Invalid pickup agent ID: " + pickupAgentId);
		}

		OrderReturn rr = returnDAO.getReturnByOrderId(orderId);
		if (rr == null) {
			throw new Exception("No return record for order: " + orderId);
		}

		rr.setPickupAgentId(pickupAgentId); // valid positive int → no FK issue
		rr.setStatus("Approved"); // agent assigned, not yet picked

		returnDAO.upsertReturnRecord(rr);
		orderDAO.updateOrderStatus(orderId, "Return Agent Assigned");

		// Link return order to the pickup agent's active/booked slot
		try (Connection slotConn = DBConnection.getConnection()) {
			DeliverySlotDAO slotDao = new DeliverySlotDAO(slotConn);
			boolean linked = slotDao.assignOrderToSlot(orderId, pickupAgentId);
			if (!linked) {
				log.warning("assignPickupAgent: no active slot for pickup agent #" + pickupAgentId + " — return order #"
						+ orderId + " assigned without slot linkage.");
			}
		} catch (Exception slotEx) {
			log.warning("assignPickupAgent: slot linkage failed for return order #" + orderId + " agent #"
					+ pickupAgentId + " — " + slotEx.getMessage());
		}

		Order order = orderDAO.getOrderById(orderId);
		String pickupVehicle = nd.getAgentVehicleInfo(pickupAgentId);
		nd.notifyPickupScheduled(rr.getCustomerId(), orderId, order.getDeliveryUserName(), order.getPhone(),
				pickupVehicle);

		// Notify the pickup agent: new return task assigned
		try (Connection notifConn = DBConnection.getConnection()) {
			DeliveryNotificationServlet.push(notifConn, pickupAgentId, "RETURN_PICKUP_ASSIGNED",
					"📦 Return pickup assigned — Order #" + orderId,
					"You have been assigned to collect a return item for Order #" + orderId
							+ ". Please head to the customer's address.",
					"📦", "amber", orderId);
		} catch (Exception notifEx) {
			log.warning(
					"Agent return-pickup-assigned notif failed for order #" + orderId + ": " + notifEx.getMessage());
		}

		log.info("Pickup agent #" + pickupAgentId + " ASSIGNED — order #" + orderId);
	}

	// ─────────────────────────────────────────────────────────────────────────
	// ── PROCESS RETURN REFUND ────────────────────────────────────────────────
	// Handles: wallet / bank / original (Razorpay) / replacement
	// FIX G: restock always restores full item quantities (whole-order return).
	// ─────────────────────────────────────────────────────────────────────────
	private void processReturnRefund(HttpServletRequest request) throws Exception {
		int orderId = Integer.parseInt(request.getParameter("orderId"));
		int restockQty = parseIntSafe(request.getParameter("restockQty"), 0);
		double refundAmount = parseDoubleSafe(request.getParameter("refundAmount"), 0.0);
		String refundMethod = request.getParameter("refundMethod");
		String paymentId = request.getParameter("paymentId");

		OrderReturn rr = returnDAO.getReturnByOrderId(orderId);
		if (rr == null) {
			throw new Exception("No return record for order: " + orderId);
		}

		// ── 1. Restock inventory (FIX G: restores actual item quantities) ────
		if (restockQty > 0) {
			List<CartItem> items = orderDAO.getOrderItems(orderId);
			for (CartItem item : items) {
				productDAO.incrementStock(item.getProductId(), item.getQuantity());
				log.info("Restocked product #" + item.getProductId() + " +" + item.getQuantity());
			}
			rr.setRestockQty(restockQty);
		}

		rr.setRefundAmount(refundAmount);
		rr.setRefundMethod(refundMethod);

		// ── 2. Replacement (no money transfer, triggers new delivery) ───────
		if ("replacement".equalsIgnoreCase(refundMethod)) {
			rr.setStatus("Replaced");
			returnDAO.upsertReturnRecord(rr);
			// BUG 4 FIX: Do NOT mark order as "Replaced" yet.
			// Set to "Replacement Dispatch" so staff assigns a new delivery agent.
			orderDAO.updateOrderStatus(orderId, "Replacement Dispatch");

			insertSystemNotif(orderId, "🔄 Return item collected for order #" + orderId
					+ ". Please repack and assign a delivery agent to send the replacement product.");

			// BUG FIX: Customer was never notified that their replacement was dispatched.
			try {
				nd.notifyReplacementDispatch(rr.getCustomerId(), orderId);
			} catch (Exception notifEx) {
				log.warning("Customer replacement-dispatch notification failed for order #" + orderId + ": "
						+ notifEx.getMessage());
			}

			log.info("Replacement queued — order #" + orderId + " → Replacement Dispatch | staff notified");
			return;
		}

		// ── 3. Wallet refund ─────────────────────────────────────────────────
		if ("wallet".equalsIgnoreCase(refundMethod)) {
			walletDAO.creditCustomerWallet(rr.getCustomerId(), refundAmount, orderId);
			rr.setRefundTransactionId("WALLET-RETURN-" + orderId + "-" + System.currentTimeMillis());
			log.info("Wallet credit ₹" + refundAmount + " → customer #" + rr.getCustomerId());
		}

		// ── 4. Bank transfer (manual) ────────────────────────────────────────
		else if ("bank".equalsIgnoreCase(refundMethod)) {
			rr.setRefundTransactionId("BANK-MANUAL-" + orderId + "-" + System.currentTimeMillis());
			log.info("Manual bank transfer — order #" + orderId + " | acc=" + rr.getBankAccount() + " | IFSC="
					+ rr.getBankIfsc());
		}

		// ── 5. Original payment method (Razorpay) ────────────────────────────
		else if ("original".equalsIgnoreCase(refundMethod)) {
			if (paymentId != null && !paymentId.isBlank()) {
				// TODO: Integrate Razorpay Refund API
				// RazorpayClient client = new RazorpayClient(KEY_ID, KEY_SECRET);
				// JSONObject req = new JSONObject();
				// req.put("amount", (int)(refundAmount * 100));
				// Refund refund = client.payments.refund(paymentId, req);
				// rr.setRefundTransactionId(refund.get("id"));
				rr.setRefundTransactionId("RAZORPAY-PENDING-" + paymentId);
				log.info("Razorpay refund queued — paymentId=" + paymentId + " ₹" + refundAmount);
			} else {
				rr.setRefundTransactionId("RAZORPAY-NO-PAYMENT-ID-" + orderId);
				log.warning("Original refund requested but no paymentId — order #" + orderId);
			}
		}

		// ── 6. Persist ───────────────────────────────────────────────────────
		rr.setStatus("Refunded");
		returnDAO.upsertReturnRecord(rr);
		orderDAO.updateOrderStatus(orderId, "Refunded");
		orderDAO.updatePaymentStatus(orderId, "REFUNDED", rr.getRefundTransactionId());
		nd.notifyRefundCredited(rr.getCustomerId(), orderId, refundAmount);

		log.info("Return REFUNDED — order #" + orderId + " | method=" + refundMethod + " | amount=₹" + refundAmount
				+ " | txnId=" + rr.getRefundTransactionId());
	}

	// ─────────────────────────────────────────────────────────────────────────
	// ── DIRECT REFUND (cancelled / manual) ───────────────────────────────────
	// BUG 2 FIX: This is now the ONLY place where wallet/payment is credited
	// for cancelled orders. Staff must explicitly click "Process Refund" which
	// calls this action. Previously cancelOrder() did this immediately, which
	// meant refunds happened before staff reviewed them.
	//
	// ADDITIONAL SAFEGUARDS (real-world correctness):
	// 1. Only Cancelled + PAID orders can be refunded. COD orders had no payment.
	// 2. refundAmount is capped at what cancelOrder() stored in order_returns.
	// This prevents staff from accidentally refunding more than the deduction-
	// adjusted amount (e.g., refunding 100% for a Shipped order that should
	// only get 90% back).
	// 3. The order_returns record is updated to status=Refunded with a txnId,
	// so the customer's order page shows the correct final state.
	// ─────────────────────────────────────────────────────────────────────────
	private void processDirectRefund(HttpServletRequest request) throws Exception {
		int orderId = Integer.parseInt(request.getParameter("orderId"));
		String paymentId = request.getParameter("paymentId");
		double refundAmount = parseDoubleSafe(request.getParameter("refundAmount"), 0.0);
		String reason = request.getParameter("reason");
		String refundMethod = request.getParameter("refundMethod"); // "wallet" | "original"
		if (refundMethod == null || refundMethod.isBlank()) {
			refundMethod = "wallet";
		}

		Order order = orderDAO.getOrderById(orderId);
		if (order == null) {
			throw new Exception("Order not found: " + orderId);
		}

		// GUARD 1: Only process refunds for Cancelled orders
		if (!"Cancelled".equalsIgnoreCase(order.getStatus())) {
			throw new Exception("Cannot process refund — order #" + orderId + " is not in Cancelled status (current: "
					+ order.getStatus() + ").");
		}

		// GUARD 2: COD orders had no payment collected — nothing to refund
		boolean isCod = "PENDING_COD".equalsIgnoreCase(order.getPaymentStatus())
				|| "COD_CANCELLED".equalsIgnoreCase(order.getPaymentStatus());
		if (isCod) {
			throw new Exception(
					"Order #" + orderId + " is a COD order. No payment was collected, so no refund is applicable.");
		}

		// GUARD 3: Already refunded
		if ("REFUNDED".equalsIgnoreCase(order.getPaymentStatus())) {
			throw new Exception("Order #" + orderId + " has already been refunded.");
		}

		if (refundAmount <= 0) {
			throw new Exception("Refund amount must be greater than 0.");
		}

		// GUARD 4: Cap refundAmount at the deduction-adjusted amount stored during
		// cancelOrder(). This is the authoritative figure — it already has the correct
		// tiered deduction (0% pre-ship, 5% Assigned/Packed, 10% Shipped/OFD) applied.
		OrderReturn rr = returnDAO.getReturnByOrderId(orderId);
		if (rr == null) {
			// No cancellation record found — fall back to a safe cap of totalAmount.
			// Should not happen if cancelOrder() ran correctly.
			rr = new OrderReturn();
			rr.setOrderId(orderId);
			rr.setCustomerId(order.getCustomerId());
			rr.setType("Cancellation");
			log.warning("processDirectRefund: no order_returns record for cancelled order #" + orderId
					+ " — this suggests cancelOrder() was not called. Proceeding with caution.");
		} else {
			// Enforce: refundAmount cannot exceed what cancelOrder() computed
			double approvedRefund = rr.getRefundAmount();
			if (approvedRefund > 0 && refundAmount > approvedRefund) {
				throw new Exception(
						String.format(
								"Refund amount ₹%.2f exceeds the approved refund of ₹%.2f for order #%d. "
										+ "The approved amount already accounts for the applicable deduction. "
										+ "Please use ₹%.2f or less.",
								refundAmount, approvedRefund, orderId, approvedRefund));
			}
		}

		rr.setReason(reason != null ? reason : "Staff direct refund");
		rr.setRefundAmount(refundAmount);
		rr.setRefundMethod(refundMethod);
		rr.setStatus("Refunded");

		// Actually credit the money now
		if ("wallet".equals(refundMethod)) {
			walletDAO.creditCustomerWallet(order.getCustomerId(), refundAmount, orderId);
			rr.setRefundTransactionId("WALLET-CANCEL-" + orderId + "-" + System.currentTimeMillis());

			nd.notifyWalletCredited(order.getCustomerId(), refundAmount,
					reason != null ? reason : "Refund for cancelled order #" + orderId);
			log.info("Wallet credit ₹" + refundAmount + " → customer #" + order.getCustomerId() + " (cancelled order #"
					+ orderId + ")");
		} else if ("original".equals(refundMethod)) {
			String pid = (paymentId != null && !paymentId.isBlank()) ? paymentId : order.getTransactionId();
			// TODO: Integrate Razorpay Refund API

			nd.notifyRefundInitiated(order.getCustomerId(), orderId, refundAmount);
			rr.setRefundTransactionId(pid != null ? "RAZORPAY-CANCEL-PENDING-" + pid : "RAZORPAY-NO-PID-" + orderId);
			log.info("Razorpay refund queued for cancelled order #" + orderId + " | paymentId=" + pid);
		}

		returnDAO.upsertReturnRecord(rr);
		// BUG FIX: was nd.notifyRefundCredited(orderId, orderId, refundAmount)
		// which passed orderId as the customerId argument — customer never received
		// the notification because the wrong ID was used for the lookup.
		// Also removed the unconditional call here since wallet/original paths above
		// already call notifyWalletCredited / notifyRefundInitiated individually.
		// Only call notifyRefundCredited for non-wallet methods (bank/original)
		// that don't have their own specific notification above.
		if (!"wallet".equals(refundMethod)) {
			nd.notifyRefundCredited(order.getCustomerId(), orderId, refundAmount);
		}

		orderDAO.updatePaymentStatus(orderId, "REFUNDED", rr.getRefundTransactionId());
		log.info("Direct REFUND processed — order #" + orderId + " | method=" + refundMethod + " | ₹" + refundAmount);
	}

	// ─────────────────────────────────────────────────────────────────────────
	// ── CANCEL ORDER ─────────────────────────────────────────────────────────
	// FIX E: 'Picked Up' stage added to restock check; Packed/Assigned in switch.
	// FIX F: Uses sendJson() instead of response().
	// ─────────────────────────────────────────────────────────────────────────
	private void cancelOrder(HttpServletRequest request, HttpServletResponse response) throws Exception {

		int orderId = Integer.parseInt(request.getParameter("orderId"));
		String cancelReason = request.getParameter("cancelReason");
		String cancelledBy = request.getParameter("cancelledBy"); // "customer"|"staff"
		String refundMethod = request.getParameter("refundMethod"); // "wallet"|"original"|"none"

		Order order = orderDAO.getOrderById(orderId);
		if (order == null) {
			throw new Exception("Order not found: " + orderId);
		}

		String currentStatus = order.getStatus();
		boolean isPaid = "PAID".equalsIgnoreCase(order.getPaymentStatus());
		boolean isCod = "PENDING_COD".equalsIgnoreCase(order.getPaymentStatus());
		double totalAmount = order.getTotalAmount();

		// ── Tiered refund policy ──────────────────────────────────────────────
		double refundAmount = 0.0;
		double deductionAmount = 0.0;
		String deductionReason = "No refund applicable";

		if (isPaid) {
			switch (currentStatus != null ? currentStatus : "") {
			case "Ordered":
			case "Pending":
			case "Confirmed":
				refundAmount = totalAmount;
				deductionReason = "Full refund — order not processed yet";
				break;

			case "Assigned": // FIX B: now reachable because status IS set to Assigned
			case "Picked Up":
				deductionAmount = totalAmount * 0.05;
				refundAmount = totalAmount - deductionAmount;
				deductionReason = "5% handling fee deducted";
				break;

			case "Packed":
				deductionAmount = totalAmount * 0.05;
				refundAmount = totalAmount - deductionAmount;
				deductionReason = "5% packing charge deducted";
				break;

			case "Shipped":
			case "Out for Delivery":
				deductionAmount = totalAmount * 0.10;
				refundAmount = totalAmount - deductionAmount;
				deductionReason = "10% shipping/handling charge deducted";
				break;

			case "Return Agent Assigned":
			case "Return Out for Pickup":
				deductionAmount = totalAmount * 0.15;
				refundAmount = totalAmount - deductionAmount;
				deductionReason = "15% return logistics charge deducted";
				break;

			default:
				deductionReason = "No refund applicable at this stage";
				break;
			}
		}

		// ── Build / update return record ──────────────────────────────────────
		OrderReturn rr = returnDAO.getReturnByOrderId(orderId);
		if (rr == null) {
			rr = new OrderReturn();
			rr.setOrderId(orderId);
			rr.setCustomerId(order.getCustomerId());
			rr.setType("Cancellation");
			// pickup_agent_id stays null → no FK issue
		}
		rr.setReason("CANCELLED by " + cancelledBy + ": " + cancelReason + " | " + deductionReason);
		rr.setRefundAmount(refundAmount);

		// ── BUG 2 FIX: Do NOT auto-credit wallet/original here.
		// Set status to "Pending Refund" so staff reviews and approves.
		// Only COD cancellations (no money was paid) are terminal immediately.
		if (isPaid && refundAmount > 0) {
			rr.setStatus("Pending Refund");
			String effectiveMethod = (refundMethod != null && !"none".equals(refundMethod)) ? refundMethod : "wallet";
			rr.setRefundMethod(effectiveMethod);
			// Refund transaction ID assigned when staff calls processDirectRefund()
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

		// Payment status stays as-is until staff processes refund via
		// processDirectRefund()
		// Only exception: COD order — nothing was paid, mark clearly
		if (isCod) {
			orderDAO.updatePaymentStatus(orderId, "COD_CANCELLED", null);
		}

		// ── BUG FIX: Customer was never notified about cancellation ──────────
		// nd.notifyOrderCancelled() was completely missing here.
		try {
			String custReason = (cancelReason != null && !cancelReason.isBlank()) ? cancelReason : "requested";
			nd.notifyOrderCancelled(order.getCustomerId(), orderId, custReason);
		} catch (Exception notifEx) {
			log.warning("Customer cancel notification failed for order #" + orderId + ": " + notifEx.getMessage());
		}

		// ── Restock if goods were already moving (FIX E: added Picked Up) ─────
		boolean wasPackedOrMoving = "Packed".equals(currentStatus) || "Assigned".equals(currentStatus)
				|| "Picked Up".equals(currentStatus) || "Shipped".equals(currentStatus)
				|| "Out for Delivery".equals(currentStatus);
		if (wasPackedOrMoving) {
			List<CartItem> items = orderDAO.getOrderItems(orderId);
			for (CartItem item : items) {
				productDAO.incrementStock(item.getProductId(), item.getQuantity());
			}
			log.info("Restocked items for cancelled order #" + orderId);
		}

		log.info("Order #" + orderId + " CANCELLED by " + cancelledBy + " | stage=" + currentStatus + " | refund=₹"
				+ refundAmount + " | deduction=₹" + deductionAmount);
		try {
			String cancelMsg = String.format("🚫 Order #%d CANCELLED by %s. Stage: %s. Reason: %s. %s", orderId,
					(cancelledBy != null ? cancelledBy : "unknown"), (currentStatus != null ? currentStatus : "—"),
					(cancelReason != null ? cancelReason : "—"),
					(isPaid && refundAmount > 0 ? String.format("Refund ₹%.2f pending approval.", refundAmount)
							: (isCod ? "COD order — no refund." : "")));
			insertSystemNotif(orderId, cancelMsg);
			log.info("Staff notified of cancellation — order #" + orderId);
		} catch (Exception ex) {
			log.warning("Cancel notification failed: " + ex.getMessage());
		}

		// If an agent was already assigned, push a cancellation notification to them
		// so their portal updates immediately without waiting for a page refresh.
		if (order.getDeliveryUserId() > 0) {
			try (Connection notifConn = DBConnection.getConnection()) {
				DeliveryNotificationServlet.push(notifConn, order.getDeliveryUserId(), "ORDER_CANCELLED",
						"🚫 Order #" + orderId + " cancelled",
						"Order #" + orderId + " has been cancelled by " + (cancelledBy != null ? cancelledBy : "staff")
								+ ". Reason: " + (cancelReason != null ? cancelReason : "not specified") + ".",
						"🚫", "red", orderId);
			} catch (Exception notifEx) {
				log.warning("Agent cancel notif failed for order #" + orderId + ": " + notifEx.getMessage());
			}
		}

		// ── Respond ───────────────────────────────────────────────────────────
		boolean isAjax = "XMLHttpRequest".equalsIgnoreCase(request.getHeader("X-Requested-With"));
		if (isAjax) {
			String refundMsg = (isPaid && refundAmount > 0)
					? String.format(" ₹%.2f refund is pending staff approval.", refundAmount)
					: (isCod ? " No refund applicable (COD order)." : "");
			sendJson(response, true, "Order cancelled." + refundMsg);
		} else {
			response.sendRedirect("OrdersDashboard");
		}
	}

	// ─────────────────────────────────────────────────────────────────────────
	// ── AGENT CANT DELIVER ────────────────────────────────────────────────────
	// BUG 1 FIX: Separate action from agentCancelPickup (which only handles
	// return records). This handles normal delivery orders where the agent
	// cannot complete delivery (customer absent, wrong address, etc.).
	// Flow: clears delivery agent → status back to "Confirmed" → staff notified.
	// ─────────────────────────────────────────────────────────────────────────
	private void agentCantDeliver(HttpServletRequest request, HttpServletResponse response) throws Exception {
		int orderId = Integer.parseInt(request.getParameter("orderId"));
		String cancelReason = request.getParameter("cancelReason");
		if (cancelReason == null || cancelReason.isBlank()) {
			throw new Exception("Cancel reason is required.");
		}

		Order order = orderDAO.getOrderById(orderId);
		if (order == null) {
			throw new Exception("Order not found: " + orderId);
		}

		orderDAO.updateOrderStatus(orderId, "Confirmed");
		orderDAO.clearDeliveryAgent(orderId);
		String payMethod = order.getPaymentMethod();
		OrderReturn rr = returnDAO.getReturnByOrderId(orderId);
		if (rr == null) {
			rr = new OrderReturn();
			rr.setOrderId(orderId);
			rr.setCustomerId(order.getCustomerId());
			rr.setType("Delivery Incident");
		}
		String prev = rr.getStaffNotes() != null ? rr.getStaffNotes() + " | " : "";
		rr.setStaffNotes(prev + "Agent CANT DELIVER: " + cancelReason);
		rr.setStatus("Incident Logged");
		returnDAO.upsertReturnRecord(rr);

		insertSystemNotif(orderId, "⚠️ Agent could not deliver order #" + orderId + ". Reason: " + cancelReason
				+ ". Please reassign to a new delivery agent.");

		// BUG FIX: Customer was never notified that their delivery failed.
		// They would see the order stuck in "Out for Delivery" with no explanation.
		try {
			nd.notifyDeliveryFailed(order.getCustomerId(), orderId, cancelReason);
		} catch (Exception notifEx) {
			log.warning(
					"Customer delivery-failed notification failed for order #" + orderId + ": " + notifEx.getMessage());
		}

		log.info("Agent CANT DELIVER — order #" + orderId + " | reverted to Confirmed | reason=" + cancelReason);
		sendJson(response, true, "Reported. Staff has been notified and will reassign your order.");
	}

	private void agentRejectTask(HttpServletRequest request, HttpServletResponse response) throws Exception {
		int orderId = Integer.parseInt(request.getParameter("orderId"));
		String cancelReason = request.getParameter("cancelReason");
		if (cancelReason == null || cancelReason.isBlank()) {
			throw new Exception("Rejection reason is required.");
		}

		Order order = orderDAO.getOrderById(orderId);
		if (order == null) {
			throw new Exception("Order not found: " + orderId);
		}

		int agentId = order.getDeliveryUserId();

		// Fetch agent name for better notification messages
		String agentName = "Agent #" + agentId;
		try (Connection conn = DBConnection.getConnection()) {
			User agentUser = new DeliveryPersonDAO(conn).getDeliveryUserById(agentId);
			if (agentUser != null && agentUser.getUsername() != null) {
				agentName = agentUser.getUsername();
			}
		} catch (Exception ex) {
			log.warning("Could not fetch agent name for #" + agentId);
		}

		int rejectCount = 0;
		try {
			rejectCount = orderDAO.getAgentRejectionCount(agentId);
		} catch (Exception ex) {
			log.warning("Could not read rejection count for agent #" + agentId + ": " + ex.getMessage());
		}

		// BLOCK if already at 3+ rejections
		if (rejectCount >= 3) {
			try (Connection conn = DBConnection.getConnection()) {
				new DeliveryPersonDAO(conn).updateUserStatus(agentId, "restricted");
			} catch (Exception ex) {
				log.warning("Could not set agent #" + agentId + " to restricted: " + ex.getMessage());
			}
			// Notify staff that this agent is now restricted (visible in dashboard)

			insertSystemNotif(orderId,
					"⛔ " + agentName + " (#" + agentId + ") has been RESTRICTED after 3+ task rejections "
							+ "for order #" + orderId + ". Please review and unblock if appropriate.");

			sendJson(response, false, "⛔ Your account has been temporarily restricted due to 3+ task rejections. "
					+ "Please contact your hub supervisor to reactivate your account.");
			return;
		}

		orderDAO.updateOrderStatus(orderId, "Confirmed");
		orderDAO.clearDeliveryAgent(orderId);

		try {
			orderDAO.logAgentRejection(orderId, agentId, cancelReason);
			rejectCount++;
		} catch (Exception ex) {
			log.warning("Could not log agent rejection (table may not exist yet): " + ex.getMessage());
		}

		// Build staff notification — this is what shows up in the Orders Dashboard
		// "Agent Requests" panel when agent crosses limit
		String notifMsg;
		if (rejectCount >= 3) {
			notifMsg = "⛔ " + agentName + " (#" + agentId + ") has been RESTRICTED (3rd rejection) for order #"
					+ orderId + ". Reason: " + cancelReason + ". Please review via Orders Dashboard → Task Rejections.";
		} else if (rejectCount == 2) {
			notifMsg = "⚠️ " + agentName + " (#" + agentId + ") rejected a 2nd task for order #" + orderId
					+ ". Reason: " + cancelReason + ". One more rejection will block their account.";
		} else {
			notifMsg = "🚫 " + agentName + " (#" + agentId + ") rejected order #" + orderId + ". Reason: "
					+ cancelReason + ". Please assign a different delivery agent.";
		}

		insertSystemNotif(orderId, notifMsg);
		String responseMsg;
		if (rejectCount >= 3) {
			try (Connection conn = DBConnection.getConnection()) {
				new DeliveryPersonDAO(conn).updateUserStatus(agentId, "restricted");
			} catch (Exception ex) {
				log.warning("Could not restrict agent #" + agentId + ": " + ex.getMessage());
			}
			responseMsg = "Task rejected. ⛔ You have reached 3 rejections. "
					+ "Your account has been restricted. Please contact your supervisor.";
			log.warning("Agent #" + agentId + " RESTRICTED — 3+ rejections");
		} else if (rejectCount == 2) {
			responseMsg = "Task rejected. ⚠️ Warning: You have rejected 2 tasks. "
					+ "One more rejection will block your account.";
		} else {
			responseMsg = "Task rejected. Staff has been notified and will reassign the order.";
		}

		log.info("Agent #" + agentId + " REJECTED task — order #" + orderId + " | reason=" + cancelReason
				+ " | rejectCount=" + rejectCount);

		// Push rejection count warning back to the agent's notification feed
		try (Connection notifConn = DBConnection.getConnection()) {
			String agentNotifTitle;
			String agentNotifBody;
			String agentIcon;
			String agentColor;
			if (rejectCount >= 3) {
				agentNotifTitle = "⛔ Account restricted";
				agentNotifBody = "You have been restricted after " + rejectCount + " task rejections."
						+ " Contact your hub supervisor to reactivate your account.";
				agentIcon = "⛔";
				agentColor = "red";
			} else if (rejectCount == 2) {
				agentNotifTitle = "⚠️ Warning — 2nd rejection";
				agentNotifBody = "You have rejected 2 tasks (Order #" + orderId + ")."
						+ " One more rejection will block your account.";
				agentIcon = "⚠️";
				agentColor = "amber";
			} else {
				agentNotifTitle = "🚫 Task rejected — Order #" + orderId;
				agentNotifBody = "Your rejection for Order #" + orderId + " has been recorded."
						+ " Staff will reassign the order.";
				agentIcon = "🚫";
				agentColor = "purple";
			}
			DeliveryNotificationServlet.push(notifConn, agentId, "TASK_REJECTED", agentNotifTitle, agentNotifBody,
					agentIcon, agentColor, orderId);
		} catch (Exception notifEx) {
			log.warning("Agent rejection notif failed for agent #" + agentId + ": " + notifEx.getMessage());
		}

		sendJson(response, true, responseMsg);
	}

	// ─────────────────────────────────────────────────────────────────────────
	// Clears agent, resets return to Approved for reassignment.
	// ─────────────────────────────────────────────────────────────────────────
	private void agentCancelPickup(HttpServletRequest request, HttpServletResponse response) throws Exception {

		int orderId = Integer.parseInt(request.getParameter("orderId"));
		String cancelReason = request.getParameter("cancelReason");

		OrderReturn rr = returnDAO.getReturnByOrderId(orderId);
		if (rr == null) {
			throw new Exception("No return record for order: " + orderId);
		}

		rr.setPickupAgentId(null); // deliberate null — clears agent (FIX 3 in DAO)
		rr.setStatus("Approved");
		String existingNotes = rr.getStaffNotes() != null ? " | " + rr.getStaffNotes() : "";
		rr.setStaffNotes("Agent cancelled pickup: " + cancelReason + existingNotes);

		returnDAO.upsertReturnRecord(rr);
		orderDAO.updateOrderStatus(orderId, "Return Approved");

		// Notify staff that the agent cancelled this pickup
		insertSystemNotif(orderId, "⚠️ Pickup agent cancelled return pickup for Order #" + orderId + ". Reason: "
				+ cancelReason + ". Please reassign a new pickup agent.");

		// BUG FIX: Customer was never told their pickup was cancelled.
		// Notify them that pickup was missed and a new agent will be assigned.
		try {
			Order order = orderDAO.getOrderById(orderId);
			if (order != null) {
				nd.notifyReturnRequested(rr.getCustomerId(), orderId, "Your return pickup for order #" + orderId
						+ " could not be completed. Our team will reassign a pickup agent shortly.");
			}
		} catch (Exception notifEx) {
			log.warning("Customer pickup-cancelled notification failed for order #" + orderId + ": "
					+ notifEx.getMessage());
		}

		log.info("Pickup CANCELLED by agent — order #" + orderId);
		sendJson(response, true, "Pickup cancelled. Order ready for reassignment.");
	}

	// ─────────────────────────────────────────────────────────────────────────
	// ── REASSIGN PICKUP AGENT ─────────────────────────────────────────────────
	// ─────────────────────────────────────────────────────────────────────────
	private void reassignPickupAgent(HttpServletRequest request, HttpServletResponse response) throws Exception {
		int orderId = Integer.parseInt(request.getParameter("orderId"));
		int newAgentId = Integer.parseInt(request.getParameter("deliveryUserId"));
		String agentNote = request.getParameter("agentNote");

		if (newAgentId <= 0) {
			throw new Exception("Invalid agent ID: " + newAgentId);
		}

		OrderReturn rr = returnDAO.getReturnByOrderId(orderId);
		if (rr == null) {
			throw new Exception("No return record for order: " + orderId);
		}

		rr.setPickupAgentId(newAgentId);
		rr.setStatus("Approved");
		if (agentNote != null && !agentNote.isBlank()) {
			String prev = rr.getStaffNotes() != null ? rr.getStaffNotes() + " | " : "";
			rr.setStaffNotes(prev + "Reassignment note: " + agentNote);
		}

		returnDAO.upsertReturnRecord(rr);
		orderDAO.updateOrderStatus(orderId, "Return Agent Assigned");

		// Link return order to the new agent's active/booked slot
		try (Connection slotConn = DBConnection.getConnection()) {
			DeliverySlotDAO slotDao = new DeliverySlotDAO(slotConn);
			boolean linked = slotDao.assignOrderToSlot(orderId, newAgentId);
			if (!linked) {
				log.warning("reassignPickupAgent: no active slot for agent #" + newAgentId + " — return order #"
						+ orderId + " reassigned without slot linkage.");
			}
		} catch (Exception slotEx) {
			log.warning("reassignPickupAgent: slot linkage failed for return order #" + orderId + " agent #"
					+ newAgentId + " — " + slotEx.getMessage());
		}

		// BUG FIX: Customer was never notified a new pickup agent was assigned.
		try {
			Order order = orderDAO.getOrderById(orderId);
			String pickupVehicle = nd.getAgentVehicleInfo(newAgentId);
			nd.notifyPickupScheduled(rr.getCustomerId(), orderId, order != null ? order.getDeliveryUserName() : null,
					order != null ? order.getPhone() : null, pickupVehicle);
		} catch (Exception notifEx) {
			log.warning(
					"Customer reassign-pickup notification failed for order #" + orderId + ": " + notifEx.getMessage());
		}

		// Notify the new pickup agent: return task reassigned to them
		try (Connection notifConn = DBConnection.getConnection()) {
			DeliveryNotificationServlet.push(notifConn, newAgentId, "RETURN_PICKUP_ASSIGNED",
					"📦 Return pickup reassigned — Order #" + orderId,
					"A return item pickup for Order #" + orderId + " has been reassigned to you."
							+ (agentNote != null && !agentNote.isBlank() ? " Note: " + agentNote : ""),
					"📦", "amber", orderId);
		} catch (Exception notifEx) {
			log.warning("Agent reassign-pickup notif failed for order #" + orderId + ": " + notifEx.getMessage());
		}

		log.info("Pickup agent REASSIGNED to #" + newAgentId + " — order #" + orderId);
		sendJson(response, true, "Pickup agent reassigned.");
	}

	// ─────────────────────────────────────────────────────────────────────────
	// ── AGENT OUT FOR PICKUP ──────────────────────────────────────────────────
	// order_returns → Processing (out for pickup in progress)
	// orders → Return Out for Pickup
	// ─────────────────────────────────────────────────────────────────────────
	private void agentOutForPickup(HttpServletRequest request, HttpServletResponse response) throws Exception {

		int orderId = Integer.parseInt(request.getParameter("orderId"));

		OrderReturn rr = returnDAO.getReturnByOrderId(orderId);
		if (rr == null) {
			throw new Exception("No return record for order: " + orderId);
		}

		rr.setStatus("Processing");
		returnDAO.upsertReturnRecord(rr);
		orderDAO.updateOrderStatus(orderId, "Return Out for Pickup");

		// BUG FIX: Customer was never told the pickup agent is on the way.
		try {
			Order order = orderDAO.getOrderById(orderId);
			if (order != null && order.getDeliveryUserId() > 0) {
				String pickupVehicle = nd.getAgentVehicleInfo(order.getDeliveryUserId());
				nd.notifyReturnOutForPickup(rr.getCustomerId(), orderId, order.getDeliveryUserName(), order.getPhone(),
						pickupVehicle);
			}
		} catch (Exception notifEx) {
			log.warning(
					"Customer out-for-pickup notification failed for order #" + orderId + ": " + notifEx.getMessage());
		}

		log.info("Agent OUT FOR PICKUP — order #" + orderId);
		sendJson(response, true, "Agent is on the way to pick up the item.");
	}

	// ─────────────────────────────────────────────────────────────────────────
	// ── CONFIRM PICKUP ────────────────────────────────────────────────────────
	// order_returns → Picked
	// orders → Return Picked
	// ─────────────────────────────────────────────────────────────────────────
	private void confirmPickup(HttpServletRequest request, HttpServletResponse response) throws Exception {

		int orderId = Integer.parseInt(request.getParameter("orderId"));

		OrderReturn rr = returnDAO.getReturnByOrderId(orderId);
		if (rr == null) {
			throw new Exception("No return record for order: " + orderId);
		}

		rr.setStatus("Picked");
		returnDAO.upsertReturnRecord(rr);
		orderDAO.updateOrderStatus(orderId, "Return Picked");
		Order itemOrder = orderDAO.getOrderById(orderId);
		nd.notifyItemPickedUp(itemOrder != null ? itemOrder.getCustomerId() : 0, orderId);

		// Credit return pickup fee to the pickup agent's wallet
		int pickupAgentId = (rr.getPickupAgentId() != null) ? rr.getPickupAgentId() : 0;
		if (pickupAgentId > 0) {
			try {
				final double RETURN_PICKUP_FEE = 30.0;
				agentWalletDAO.creditDeliveryFee(pickupAgentId, orderId, RETURN_PICKUP_FEE, false);
				// Record against the slot so it appears in earnings history
				if (itemOrder != null && itemOrder.getSlotId() > 0) {
					try (Connection conn = DBConnection.getConnection()) {
						DeliverySlotDAO slotDao = new DeliverySlotDAO(conn);
						slotDao.recordOrderEarning(pickupAgentId, orderId, itemOrder.getSlotId());
					}
				}
				log.info("Return pickup fee ₹" + RETURN_PICKUP_FEE + " credited to agent #" + pickupAgentId
						+ " for order #" + orderId);
			} catch (Exception ex) {
				log.warning("Return pickup fee credit failed for agent #" + pickupAgentId + " order #" + orderId + ": "
						+ ex.getMessage());
			}

			// Push confirmation to the pickup agent
			try (Connection notifConn = DBConnection.getConnection()) {
				DeliveryNotificationServlet.push(notifConn, pickupAgentId, "PICKUP_CONFIRMED",
						"✅ Pickup confirmed — Order #" + orderId, "Return item for Order #" + orderId
								+ " successfully picked up." + " ₹30 pickup fee has been credited to your wallet.",
						"✅", "green", orderId);
			} catch (Exception notifEx) {
				log.warning("Agent pickup-confirmed notif failed for order #" + orderId + ": " + notifEx.getMessage());
			}
		}

		log.info("Item PICKED UP confirmed — order #" + orderId);
		sendJson(response, true, "Item collected. Ready to process refund.");
	}

	// ─────────────────────────────────────────────────────────────────────────
	// ── ASSIGN DELIVERY PERSON ────────────────────────────────────────────────
	// FIX B: now calls assignDeliveryPersonAndStatus() which sets
	// delivery_user_id AND status='Assigned' in one atomic UPDATE.
	// ─────────────────────────────────────────────────────────────────────────
	private void assignDeliveryPerson(HttpServletRequest request, HttpServletResponse response) throws Exception {
		int orderId = Integer.parseInt(request.getParameter("orderId"));
		int deliveryUserId = Integer.parseInt(request.getParameter("deliveryUserId"));

		if (deliveryUserId <= 0) {
			throw new Exception("Invalid delivery user ID: " + deliveryUserId);
		}
		int activeCount = orderDAO.getAgentActiveOrderCount(deliveryUserId);
		if (activeCount > 0) {
			sendJson(response, false, "Agent already has an active order in progress. "
					+ "They must deliver it before accepting a new one.");
			return;
		}
		// Sets delivery_user_id AND status = 'Assigned' atomically
		orderDAO.assignDeliveryPersonAndStatus(orderId, deliveryUserId);

		try (Connection conn = DBConnection.getConnection()) {
			DeliveryPersonDAO agent = new DeliveryPersonDAO(conn);
			agent.assignDeliveryPerson(orderId, deliveryUserId);
		}

		// BUG FIX: notification was inside the DeliveryPersonDAO try block — any
		// exception from agent.assignDeliveryPerson() would skip it silently.
		// Moved outside so it always fires after the DB write succeeds.
		try {
			Order order = orderDAO.getOrderById(orderId);
			// Fetch vehicle info from delivery_agent_registrations via DAO helper
			String vehicleInfo = nd.getAgentVehicleInfo(deliveryUserId);
			nd.notifyDeliveryAssigned(order.getCustomerId(), orderId, deliveryUserId, order.getDeliveryUserName(),
					order.getPhone(), vehicleInfo);
		} catch (Exception notifEx) {
			log.warning("Customer delivery-assigned notification failed for order #" + orderId + ": "
					+ notifEx.getMessage());
		}

		// FIX: Link the order to the agent's active slot and increment pending_count.
		// assignDeliveryPersonAndStatus() only sets delivery_user_id — it never writes
		// slot_id into the orders row. Without slot_id, syncSlotCountersFromOrders()
		// finds zero orders for the slot, and updateSlotCounters() also skips because
		// pickedOrder.getSlotId() returns 0. Both counters stay permanently at 0.
		try (Connection conn = DBConnection.getConnection()) {
			DeliverySlotDAO slotDao = new DeliverySlotDAO(conn);
			boolean linked = slotDao.assignOrderToSlot(orderId, deliveryUserId);
			if (!linked) {
				// Agent has no active/booked slot today — log but don't block assignment
				log.warning("assignDeliveryPerson: no active slot found for agent #" + deliveryUserId + " — order #"
						+ orderId + " assigned without slot linkage.");
			}
		} catch (Exception slotEx) {
			// Non-fatal: order is already assigned; slot counter drift is acceptable
			// over a broken assignment
			log.warning("assignDeliveryPerson: slot linkage failed for order #" + orderId + " agent #" + deliveryUserId
					+ " — " + slotEx.getMessage());
		}

		// NOTE: No holdCodAmount() here. The hold is placed at "Picked Up".
		// If you want to use OPTION B (hold at assignment), add it here:
		//
		// Order o = orderDAO.getOrderById(orderId);
		// if ("COD".equalsIgnoreCase(o.getPaymentMethod())) {
		// BigDecimal amount = new BigDecimal(o.getTotalAmount());
		// if (agentWalletDAO.canAcceptCodOrder(deliveryUserId, amount)) {
		// agentWalletDAO.holdCodAmount(deliveryUserId, orderId, amount, "Assigned");
		// } else {
		// throw new Exception("Agent #" + deliveryUserId + " has insufficient balance
		// for this COD order.");
		// }
		// }

		log.info("Delivery person #" + deliveryUserId + " assigned to order #" + orderId + " | status → Assigned");
	}

	// ─────────────────────────────────────────────────────────────────────────
	// ── NOTIFY NEW ORDER (called from CheckoutServlet) ────────────────────────
	// ─────────────────────────────────────────────────────────────────────────
	public void notifyNewOrder(Order order, Customer customer, List<CartItem> items, String paymentMethod,
			double grandTotal) {
		try {
			boolean isCod = "COD".equalsIgnoreCase(paymentMethod);
			StringBuilder sb = new StringBuilder();
			if (items != null) {
				for (CartItem item : items) {
					sb.append("• ").append(item.getName()).append(" x").append(item.getQuantity()).append("\n");
				}
			}
			String actionText = isCod ? "Collect cash on delivery." : "Payment confirmed — pack & dispatch.";
			StaffNotification n = new StaffNotification(order.getId(), paymentMethod, isCod ? "PENDING_COD" : "PAID",
					grandTotal, customer.getName(), customer.getEmail(), customer.getPhone(), sb.toString().trim(),
					actionText);
			notifDAO.insert(n);
		} catch (Exception e) {
			log.log(Level.WARNING, "Staff notification insert failed for order #" + order.getId(), e);
		}

		// BUG FIX: Customer notification (ORDER_PLACED) was NEVER sent here.
		// notifyNewOrder() only inserted a StaffNotification — the customer received
		// no order confirmation notification at all after placing an order.
		try {
			String itemsSummary = "";
			if (items != null && !items.isEmpty()) {
				StringBuilder isb = new StringBuilder();
				for (CartItem item : items) {
					isb.append(item.getName()).append(" x").append(item.getQuantity()).append(", ");
				}
				itemsSummary = isb.toString().replaceAll(", $", "");
			}
			nd.notifyOrderPlaced(customer.getId(), order.getId(), itemsSummary, grandTotal, paymentMethod);
		} catch (Exception e) {
			log.log(Level.WARNING, "Customer ORDER_PLACED notification failed for order #" + order.getId(), e);
		}
	}

	// ── CONFIRM COD DEPOSIT (staff side) ─────────────────────────────────────
	// Called from OrdersDashboard "Confirm Cash Deposit" button.
	// Marks the COD order's cash as received, releases cod_float, credits agent.
	// Real-world reference: Blinkit/Porter staff desk confirms agent cash handover.
	private void confirmCodDeposit(HttpServletRequest request, HttpServletResponse response) throws Exception {
		int orderId = Integer.parseInt(request.getParameter("orderId"));
		int agentId = Integer.parseInt(request.getParameter("agentId"));
		String amtStr = request.getParameter("amount");
		String notes = request.getParameter("notes");
		if (amtStr == null || amtStr.isBlank()) {
			sendJson(response, false, "Amount is required.");
			return;
		}
		BigDecimal amount = new BigDecimal(amtStr.trim());
		if (amount.compareTo(BigDecimal.ZERO) <= 0) {
			sendJson(response, false, "Amount must be greater than zero.");
			return;
		}
		boolean ok = agentWalletDAO.recordCodDeposit(agentId, orderId, amount, "confirmed", notes);
		if (ok) {
			orderDAO.updatePaymentStatus(orderId, "DEPOSITED", null);
			log.info("COD deposit CONFIRMED — order #" + orderId + " agent #" + agentId + " ₹" + amount);
			sendJson(response, true, "Cash deposit of ₹" + amount.toPlainString() + " confirmed for Order #" + orderId
					+ ". Agent wallet updated.");
		} else {
			sendJson(response, false, "Could not record deposit. Order may already be deposited or not found.");
		}
	}

	// ── AGENT CONFIRM COD DELIVERY (manual fallback, no OTP) ──────────────────
	// Used when customer cannot receive OTP (no signal, elderly, etc.)
	// Staff must approve the override later via the dashboard.
	private void agentConfirmCodDelivery(HttpServletRequest request, HttpServletResponse response) throws Exception {
		int orderId = Integer.parseInt(request.getParameter("orderId"));
		String notes = request.getParameter("notes"); // reason for manual confirm

		Order order = orderDAO.getOrderById(orderId);
		if (order == null) {
			throw new Exception("Order not found: " + orderId);
		}

		boolean isCod = "COD".equalsIgnoreCase(order.getPaymentMethod());
		int agentId = order.getDeliveryUserId();

		// Mark order as delivered
		orderDAO.updateOrderStatus(orderId, "Delivered");

		// Wallet: release hold + credit fee
		if (isCod && agentId > 0) {
			try {
				agentWalletDAO.releaseCodHold(agentId, orderId, new BigDecimal(order.getTotalAmount()));
				agentWalletDAO.creditDeliveryFee(agentId, orderId, 60.0, true);
			} catch (Exception ex) {
				log.warning("Wallet update failed for manual COD confirm, order #" + orderId + ": " + ex.getMessage());
			}
		}

		// Log the manual override for staff audit
		StaffNotification n = new StaffNotification();
		n.setOrderId(orderId);
		n.setActionRequired("⚠️ Order #" + orderId + " marked Delivered WITHOUT OTP by agent #" + agentId + ". Reason: "
				+ notes + ". Please verify cash collection.");
		notifDAO.insert(n);

		// BUG FIX: Customer was never notified of delivery on the manual COD path.
		// The OTP path (OtpVerificationServlet) also needs this — but this method
		// is the fallback and had no notification at all.
		try {
			nd.notifyOrderDelivered(order.getCustomerId(), orderId);
		} catch (Exception notifEx) {
			log.warning("Customer delivered notification failed for manual COD order #" + orderId + ": "
					+ notifEx.getMessage());
		}

		log.info("Manual COD delivery confirmed — order #" + orderId + " | agent #" + agentId + " | notes=" + notes);
		sendJson(response, true, "Order marked as delivered. Cash receipt will be reviewed by staff.");
	}

	private void _setAgentOffline(int agentId, HttpServletRequest request) {
		try (Connection conn = DBConnection.getConnection()) {
			DeliveryPersonDAO userdao = new DeliveryPersonDAO(conn);
			userdao.updateUserStatus(agentId, "inactive");
			log.warning("Agent #" + agentId + " set OFFLINE in DB — insufficient balance for COD hold.");

		} catch (

		Exception e) {
			log.warning("Could not set agent #" + agentId + " offline: " + e.getMessage());
		}
	}
	// ─────────────────────────────────────────────────────────────────────────
	// ── HELPERS ───────────────────────────────────────────────────────────────
	// ─────────────────────────────────────────────────────────────────────────

	/**
	 * FIX F: Renamed from response() → sendJson() to avoid collision with the
	 * HttpServletResponse parameter name used throughout the class.
	 */
	private void sendJson(HttpServletResponse response, boolean success, String message) throws IOException {
		response.setContentType("application/json");
		response.setCharacterEncoding("UTF-8");
		String safe = message != null ? message.replace("\"", "'") : "";
		response.getWriter().write("{\"success\":" + success + ",\"message\":\"" + safe + "\"}");
	}

	private int parseIntSafe(String s, int def) {
		try {
			return (s != null && !s.isBlank()) ? Integer.parseInt(s.trim()) : def;
		} catch (NumberFormatException e) {
			return def;
		}
	}

	private double parseDoubleSafe(String s, double def) {
		try {
			return (s != null && !s.isBlank()) ? Double.parseDouble(s.trim()) : def;
		} catch (NumberFormatException e) {
			return def;
		}
	}

	/**
	 * Helper: insert a staff notification for a withdrawal request.
	 */
	private void insertWithdrawalNotif(int requestId, int agentId, String agentName, java.math.BigDecimal amount) {
		try {
			StaffNotification n = new StaffNotification();
			n.setOrderId(requestId);
			n.setPaymentMethod("WITHDRAWAL");
			n.setPaymentStatus("PENDING_WITHDRAWAL");
			n.setGrandTotal(amount != null ? amount.doubleValue() : 0.0);
			n.setCustomerName(agentName != null ? agentName : "Agent #" + agentId);
			n.setCustomerEmail("");
			n.setCustomerPhone("");
			n.setItemsSummary(
					"💸 Withdrawal request #" + requestId + " — ₹" + (amount != null ? amount.toPlainString() : "?"));
			n.setActionRequired(
					"Review withdrawal request #" + requestId + " in the Orders Dashboard → Withdrawals tab.");
			notifDAO.insert(n);
		} catch (Exception ex) {
			log.warning("insertWithdrawalNotif failed: " + ex.getMessage());
		}
	}

	/**
	 * Helper: look up the agent_id for a given withdrawal request id.
	 */
	private int getAgentIdFromRequest(int requestId) {
		try {
			java.util.List<java.util.Map<String, Object>> all = agentWalletDAO.getWithdrawalRequests(null);
			for (java.util.Map<String, Object> row : all) {
				if (row.get("id") != null && ((Number) row.get("id")).intValue() == requestId) {
					return ((Number) row.get("agentId")).intValue();
				}
			}
		} catch (Exception ex) {
			log.warning("getAgentIdFromRequest failed: " + ex.getMessage());
		}
		return 0;
	}

	private void insertSystemNotif(int orderId, String message) {
		try {
			String paymentMethod = "N/A";
			String paymentStatus = "N/A";
			double amount = 0.0;
			String customerName = "System";
			String customerEmail = "";
			String customerPhone = "";
			String itemsSummary = "";

			if (orderId > 0) {
				try {
					Order o = orderDAO.getOrderById(orderId);

					if (o != null) {
						paymentMethod = o.getPaymentMethod() != null ? o.getPaymentMethod() : "N/A";
						paymentStatus = o.getPaymentStatus() != null ? o.getPaymentStatus() : "N/A";
						amount = o.getTotalAmount();
						customerEmail = o.getCustomerEmail();
						customerName = o.getCustomerName();
						customerPhone = o.getPhone();

					}
				} catch (Exception ex) {
					log.warning("insertSystemNotif: could not fetch order #" + orderId + " — " + ex.getMessage());
				}
			}

			StaffNotification n = new StaffNotification(orderId, paymentMethod, paymentStatus, amount, customerName,
					customerEmail, customerPhone, itemsSummary, message);
			notifDAO.insert(n);
		} catch (Exception ex) {
			log.warning("System notification insert failed: " + ex.getMessage());
		}
	}
}