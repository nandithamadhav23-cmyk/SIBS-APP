package com.servlet;

import java.io.IOException;
import java.math.BigDecimal;
import java.sql.Connection;
import java.time.LocalDate;
import java.time.LocalTime;
import java.time.ZoneId;
import java.time.format.DateTimeFormatter;
import java.util.List;
import java.util.logging.Level;
import java.util.logging.Logger;

import com.DAO.AgentWalletDAO;
import com.DAO.DeliveryPersonDAO;
import com.DAO.DeliveryRegistrationDAO;
import com.DAO.DeliverySlotDAO;
import com.DAO.OrderDAO;
import com.DAO.OrderReturnDAO;
import com.util.AgentWallet;
import com.util.DBConnection;
import com.util.DeliveryRegistration;
import com.util.DeliverySlot;
import com.util.Order;
import com.util.OrderReturn;
import com.util.User;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;

/**
 * DeliveryPortalServlet — Serves the delivery agent portal
 * (DeliveryPortal.jsp).
 * ════════════════════════════════════════════════════════════════════════════
 * UPDATED: Cleaned up legacy manual window calculations and
 * ShiftWindowValidator usage. Timeline bounds and countdown epochs are fetched
 * directly from the database's absolute coordinates via DeliverySlot entities.
 */
@WebServlet("/DeliveryPortalServlet")
public class DeliveryPortalServlet extends HttpServlet {

	private static final long serialVersionUID = 1L;
	private static final Logger log = Logger.getLogger(DeliveryPortalServlet.class.getName());

	private final OrderDAO orderDAO = new OrderDAO();
	private final AgentWalletDAO walletDAO = new AgentWalletDAO();
	private final OrderReturnDAO returnDAO = new OrderReturnDAO();

	// ─────────────────────────────────────────────────────────────────────────
	// GET — load portal
	// ─────────────────────────────────────────────────────────────────────────
	@Override
	protected void doGet(HttpServletRequest request, HttpServletResponse response)
			throws ServletException, IOException {

		// HEARTBEAT PING: lightweight endpoint to keep the session alive.
		// Called every 15 min by delivery-portal.js _sendHeartbeat().
		// Returns immediately without loading any data.
		String action = request.getParameter("action");
		if ("ping".equals(action)) {
			HttpSession pingSession = request.getSession(false);
			if (pingSession == null || pingSession.getAttribute("deliveryUser") == null) {
				response.setStatus(401);
				response.setContentType("application/json");
				response.getWriter().write("{\"status\":\"expired\"}");
			} else {
				response.setStatus(200);
				response.setContentType("application/json");
				response.getWriter().write("{\"status\":\"ok\"}");
			}
			return;
		}

		HttpSession session = request.getSession(false);
		User user = (session != null) ? (User) session.getAttribute("deliveryUser") : null;

		log.info("DeliveryPortalServlet GET | user="
				+ (user != null ? user.getUsername() + " #" + user.getUid() : "null"));

		if (user == null) {
			log.warning("No deliveryUser in session → redirecting to login");
			response.sendRedirect(request.getContextPath() + "/deliveryLogin.jsp");
			return;
		}

		try {
			// ── Re-sync agent status from DB on every GET ─────────────────────────────
			try (Connection conn = DBConnection.getConnection()) {
				DeliveryPersonDAO syncDao = new DeliveryPersonDAO(conn);
				String dbStatus = syncDao.getDeliveryUserStatus(user.getUid());
				if (dbStatus != null && !dbStatus.equals(user.getStatus())) {
					user.setStatus(dbStatus);
					session.setAttribute("deliveryUser", user);
					log.info("Session status synced from DB: agent #" + user.getUid() + " → " + dbStatus);
				}
			} catch (Exception syncEx) {
				log.warning("Status sync skipped for agent #" + user.getUid() + ": " + syncEx.getMessage());
			}

			int agentId = user.getUid();

			// ── Orders ────────────────────────────────────────────────────────────────
			List<Order> orders = orderDAO.getOrdersByDeliveryAgent(agentId);
			for (Order o : orders) {
				try {
					OrderReturn rr = returnDAO.getReturnByOrderId(o.getId());
					o.setReturnRequest(rr);
				} catch (Exception ex) {
					log.warning("Return info unavailable for order #" + o.getId() + ": " + ex.getMessage());
				}
			}
			log.info("Loaded " + orders.size() + " orders for agent #" + agentId);

			// ── Earnings ──────────────────────────────────────────────────────────────
			BigDecimal earnToday = BigDecimal.ZERO;
			BigDecimal earnWeek = BigDecimal.ZERO;
			BigDecimal earnMonth = BigDecimal.ZERO;

			try {
				BigDecimal todayResult = walletDAO.getEarningsToday(agentId);
				BigDecimal weekResult = walletDAO.getEarningsThisWeek(agentId);
				BigDecimal monthResult = walletDAO.getEarningsThisMonth(agentId);

				if (todayResult != null) {
					earnToday = todayResult;
				}
				if (weekResult != null) {
					earnWeek = weekResult;
				}
				if (monthResult != null) {
					earnMonth = monthResult;
				}

			} catch (Exception ex) {
				log.warning("Could not load wallet earnings for agent #" + agentId + ": " + ex.getMessage());
			}
			request.setAttribute("dbEarnToday", earnToday);
			request.setAttribute("dbEarnWeek", earnWeek);
			request.setAttribute("dbEarnMonth", earnMonth);

			DeliveryRegistration kycReg = null;
			try (Connection conn = DBConnection.getConnection()) {
				DeliveryRegistrationDAO regDao = new DeliveryRegistrationDAO(conn);
				kycReg = regDao.getByUsername(user.getUsername());
			} catch (Exception kycEx) {
				log.warning("KYC lookup failed for agent #" + agentId + ": " + kycEx.getMessage());
			}
			request.setAttribute("kycReg", kycReg);

			DeliverySlot portalSlot = null;
			String portalSlotStatus = "NONE";
			int portalSlotId = -1;
			String portalSlotType = "";
			boolean portalIsBooked = false;
			boolean portalIsActive = false;
			boolean portalIsOnBreak = false;
			boolean portalIsInactive = false;
			boolean portalIsCompleted = false;
			boolean portalCanStartNow = false;
			String portalSlotStartFmt = "";
			int portalBreakSecsLeft = -1;
			int portalMaxBreak = 10;
			boolean portalCanGoOnline = true;
			int portalSlotStartHour = 6;
			int portalSlotStartMinute = 0;

			try (Connection slotConn = DBConnection.getConnection()) {
				DeliverySlotDAO slotDao = new DeliverySlotDAO(slotConn);
				portalSlot = slotDao.getTodaySlot(agentId);

				// Step 1: Sync order counters into the slot row (non-fatal)
				try {
					slotDao.syncAllCountersForAgent(agentId, LocalDate.now());
				} catch (Exception syncEx) {
					log.warning("syncAllCountersForAgent non-fatal for agent #" + agentId + ": " + syncEx.getMessage());
				}

				// Step 2: Re-fetch slot after counter sync (safe null check)
				portalSlot = slotDao.getTodaySlot(agentId);
				log.info("portalSlot after sync: "
						+ (portalSlot != null ? portalSlot.getStatus() + " #" + portalSlot.getSlotId()
								: "NULL (no slot today)"));

				// Step 3: Expire stale BOOKED slots; re-fetch only if rows changed (non-fatal)
				int expired = 0;
				try {
					expired = slotDao.expireStaleBookedSlots();
					if (expired > 0) {
						portalSlot = slotDao.getTodaySlot(agentId);
						log.info("portalSlot after expiry " + expired + " row(s): "
								+ (portalSlot != null ? portalSlot.getStatus() : "NULL"));
					}
				} catch (Exception expEx) {
					log.warning("expireStaleBookedSlots non-fatal for agent #" + agentId + ": " + expEx.getMessage());
				}

				log.info(
						"expireStaleBookedSlots: expired " + expired + " slot(s) on portal load for agent #" + agentId);
				if (portalSlot != null) {
					portalSlotStatus = portalSlot.getStatus();
					portalSlotId = portalSlot.getSlotId();
					portalSlotType = portalSlot.getSlotType();
					portalIsBooked = "BOOKED".equalsIgnoreCase(portalSlotStatus);
					portalIsActive = "ACTIVE".equals(portalSlotStatus);
					portalIsOnBreak = "ON_BREAK".equals(portalSlotStatus);
					portalIsInactive = "INACTIVE".equals(portalSlotStatus);
					boolean portalIsExpiredSlot = "EXPIRED".equals(portalSlotStatus);
					boolean portalIsCancelledSlot = "CANCELLED".equals(portalSlotStatus);
					portalIsCompleted = "COMPLETED".equals(portalSlotStatus) || portalIsExpiredSlot
							|| portalIsCancelledSlot;
					request.setAttribute("portalIsExpired", portalIsExpiredSlot);
					request.setAttribute("portalIsCancelled", portalIsCancelledSlot);

					LocalTime ps = DeliverySlotDAO.getSlotStartTime(portalSlotType);
					portalSlotStartHour = ps.getHour();
					portalSlotStartMinute = ps.getMinute();

					// ── Format and epoch — always set regardless of terminal state
					// so JSP banners (EXPIRED, CANCELLED) can show the original shift time ──
					portalSlotStartFmt = DeliverySlotDAO.getSlotStartTime(portalSlotType)
							.format(DateTimeFormatter.ofPattern("h:mm a"));
					portalMaxBreak = DeliverySlotDAO.MAX_BREAK_MINUTES;

					// Direct extraction from precise pre-computed DB landmarks
					long startMs = portalSlot.getStartEpochMs();
					long endMs = portalSlot.getEndEpochMs();

					// Fallback: derive from slot type if epoch not stored
					if (startMs <= 0) {
						LocalTime st = DeliverySlotDAO.getSlotStartTime(portalSlotType);
						startMs = LocalDate.now().atTime(st).atZone(ZoneId.systemDefault()).toInstant().toEpochMilli();
					}

					// canStart only relevant for BOOKED — not for terminal states
					if (!portalIsCompleted && portalSlot.getWindowStartAt() != null
							&& portalSlot.getWindowEndAt() != null) {
						java.time.LocalDateTime currentMoment = java.time.LocalDateTime.now();
						// Permits check-in starting 15 minutes ahead of schedule up to the end boundary
						portalCanStartNow = !currentMoment.isBefore(portalSlot.getWindowStartAt())
								&& currentMoment.isBefore(portalSlot.getWindowEndAt());
					}

					log.info("portal can start now : " + portalCanStartNow);
					log.info("start time: " + startMs);

					log.info("End time: " + endMs);
					request.setAttribute("portalSlotStartEpochMs", startMs);
					request.setAttribute("portalSlotEndEpochMs", endMs);

					long shiftStartedAtMs = 0L;
					if (portalSlot.getShiftStartedAt() != null) {
						shiftStartedAtMs = portalSlot.getShiftStartedAt().atZone(ZoneId.systemDefault()).toInstant()
								.toEpochMilli();
					}
					request.setAttribute("portalShiftStartedAtMs", shiftStartedAtMs);

					if (portalIsOnBreak) {
						portalBreakSecsLeft = slotDao.getBreakSecondsRemaining(portalSlotId);
						// BUG-4 FIX: expose break_start as an epoch-ms so the JSP can seed
						// _shiftState.breakStartEpoch — without it the working-hours clock
						// never subtracts the in-progress live break seconds.
						long breakStartEpochMs = slotDao.getBreakStartEpochMs(portalSlotId);
						request.setAttribute("portalBreakStartEpochMs", breakStartEpochMs);
					}
				}
			} catch (Exception slotEx) {
				log.warning("Slot load skipped for agent #" + agentId + ": " + slotEx.getMessage());
			}

			try {
				AgentWallet walletCheck = walletDAO.getWallet(agentId);
				portalCanGoOnline = walletCheck.getBalance().compareTo(walletCheck.getMinBalance()) >= 0;
			} catch (Exception walletCheckEx) {
				log.warning("Wallet check skipped for agent #" + agentId + ": " + walletCheckEx.getMessage());
			}

			request.setAttribute("portalSlot", portalSlot);
			request.setAttribute("portalSlotStatus", portalSlotStatus);
			request.setAttribute("portalSlotId", portalSlotId);
			request.setAttribute("portalSlotType", portalSlotType);
			request.setAttribute("portalIsBooked", portalIsBooked);
			request.setAttribute("portalIsActive", portalIsActive);
			request.setAttribute("portalIsOnBreak", portalIsOnBreak);
			request.setAttribute("portalIsInactive", portalIsInactive);
			request.setAttribute("portalIsCompleted", portalIsCompleted);
			request.setAttribute("portalCanStartNow", portalCanStartNow);
			request.setAttribute("portalSlotStartFmt", portalSlotStartFmt);
			request.setAttribute("portalBreakSecsLeft", portalBreakSecsLeft);
			request.setAttribute("portalMaxBreak", portalMaxBreak);
			request.setAttribute("portalCanGoOnline", portalCanGoOnline);
			request.setAttribute("portalSlotStartHour", portalSlotStartHour);
			request.setAttribute("portalSlotStartMinute", portalSlotStartMinute);
			log.info("Is portal booked: " + portalIsBooked);
			// ── OTP state ─────────────────────────────────────────────────────────────
			String activeOrderId = coalesce(request.getParameter("orderId"),
					(String) request.getAttribute("activeOrderId"));
			String otpGeneratedFlag = coalesce(request.getParameter("otpGenerated"),
					(String) request.getAttribute("otpGeneratedFlag"));
			String otpSuccessFlag = coalesce(request.getParameter("otpSuccess"),
					(String) request.getAttribute("otpSuccessFlag"));
			String otpFailedFlag = coalesce(request.getParameter("otpFailed"),
					(String) request.getAttribute("otpFailedFlag"));

			request.setAttribute("activeOrderId", activeOrderId);
			request.setAttribute("otpGeneratedFlag", otpGeneratedFlag);
			request.setAttribute("otpSuccessFlag", otpSuccessFlag);
			request.setAttribute("otpFailedFlag", otpFailedFlag);
			request.setAttribute("orders", orders);
			request.setAttribute("deliveryUser", user);

			// ── Slot booking history (for the History tab in DeliveryPortal.jsp) ──────
			List<java.util.Map<String, Object>> slotBookings = new java.util.ArrayList<>();
			java.util.Map<Integer, List<java.util.Map<String, Object>>> slotOrdersMap = new java.util.HashMap<>();
			try (Connection histConn = DBConnection.getConnection()) {
				DeliverySlotDAO histDao = new DeliverySlotDAO(histConn);
				slotBookings = histDao.getBookingHistory(agentId);
				for (java.util.Map<String, Object> b : slotBookings) {
					int sid = (Integer) b.get("slotId");
					slotOrdersMap.put(sid, histDao.getOrdersForSlot(sid));
				}
			} catch (Exception histEx) {
				log.warning("History load skipped for agent #" + agentId + ": " + histEx.getMessage());
			}
			request.setAttribute("slotBookings", slotBookings);
			request.setAttribute("slotOrdersMap", slotOrdersMap);

			passAttributeIfSet(request, "msg");
			passAttributeIfSet(request, "otpgeneratemsg");

			request.getRequestDispatcher("DeliveryPortal.jsp").forward(request, response);

		} catch (Exception e) {
			log.log(Level.SEVERE, "GET error for agent #" + user.getUid(), e);
			throw new ServletException("Failed to load delivery portal: " + e.getMessage(), e);
		}
	}

	// ─────────────────────────────────────────────────────────────────────────
	// POST — online/offline toggle ONLY
	// ─────────────────────────────────────────────────────────────────────────
	@Override
	protected void doPost(HttpServletRequest request, HttpServletResponse response)
			throws ServletException, IOException {

		HttpSession session = request.getSession(false);
		User user = (session != null) ? (User) session.getAttribute("deliveryUser") : null;

		if (user == null) {
			response.sendRedirect(request.getContextPath() + "/deliveryLogin.jsp");
			return;
		}

		String action = request.getParameter("action");
		if ("getStatus".equals(action)) {
			// FIX-GETSTATUS-1: Missing Content-Type header — browser received the JSON
			// as text/html, causing _pollStatus() to throw "Unexpected token" on
			// JSON.parse() and silently swallow the server's offline signal.
			// FIX-GETSTATUS-2: user.getStatus() returns "Active" / "Inactive" (title-case
			// DB values) but the JS poller compares `data.status === 'active'`
			// (lowercase). On a mismatch, serverOnline was always false and the pill
			// would snap Offline on the first poll even for a legitimately active agent.
			// FIX: normalise to lowercase before writing the JSON response.
			response.setContentType("application/json");
			response.setCharacterEncoding("UTF-8");
			String rawStatus = user.getStatus() != null ? user.getStatus().toLowerCase() : "inactive";
			response.getWriter().write("{\"status\":\"" + rawStatus + "\"}");
			return;
		}

		if ("updateStatus".equals(action)) {
			String newStatus = request.getParameter("status"); // "active" or "inactive"
			String dbStatus = "active".equalsIgnoreCase(newStatus) ? "Active" : "Inactive";

			if (dbStatus == null || (!dbStatus.equalsIgnoreCase("Active") && !dbStatus.equalsIgnoreCase("Inactive"))) {
				response.setStatus(400);
				response.getWriter().write("{\"success\":false,\"message\":\"Invalid status: " + dbStatus + "\"}");
				return;
			}

			try (Connection conn = DBConnection.getConnection()) {
				DeliveryPersonDAO dao = new DeliveryPersonDAO(conn);

				if ("Active".equals(dbStatus)) {
					DeliverySlotDAO slotDao = new DeliverySlotDAO(conn);

					// Check slot exists for today
					DeliverySlot activeSlot = slotDao.getTodaySlot(user.getUid());
					AgentWalletDAO walletDAO = new AgentWalletDAO();
					AgentWallet wallet = walletDAO.getWallet(user.getUid());

					if (activeSlot == null) {
						response.setStatus(400);
						sendJson(response, false, "No shift booked for today. Please book a slot to go online.");
						return;
					}
					// Check slot is not already ended
					else if ("COMPLETED".equals(activeSlot.getStatus()) || "INACTIVE".equals(activeSlot.getStatus())) {
						sendJson(response, false, "Cannot go online. Your shift has already ended.");
						return;
					}
					// Check wallet balance BEFORE marking active
					else if (wallet.getBalance().compareTo(wallet.getMinBalance()) < 0) {
						sendJson(response, false,
								"Cannot go Online. Your balance (₹" + wallet.getBalance() + ") is below the minimum ₹"
										+ wallet.getMinBalance() + ". Please top up your wallet first.");
						return;
					}
				}

				// Single authoritative DB update for both active and inactive
				boolean updated = dao.updateUserStatus(user.getUid(), dbStatus);
				if (updated) {
					user.setStatus(dbStatus);
					session.setAttribute("deliveryUser", user);
					log.info("Agent #" + user.getUid() + " → " + dbStatus);
					String msg = "Active".equalsIgnoreCase(dbStatus) ? "You are now online." : "You are now offline.";
					sendJson(response, true, msg);
				} else {
					log.warning("updateUserStatus returned false for agent #" + user.getUid());
					response.setStatus(500);
					sendJson(response, false, "DB update returned no rows. Please try again.");
				}

			} catch (Exception e) {
				log.log(Level.SEVERE, "updateStatus error for agent #" + user.getUid(), e);
				response.setStatus(500);
				response.setContentType("application/json");
				response.getWriter().write("{\"success\":false,\"message\":\"Server error\"}");
			}
		} else {
			response.setStatus(400);
			response.setContentType("application/json");
			response.getWriter().write("{\"success\":false,\"message\":\"Unknown action: " + action + "\"}");
		}
	}

	// ─────────────────────────────────────────────────────────────────────────
	// Helpers
	// ─────────────────────────────────────────────────────────────────────────
	private void sendJson(HttpServletResponse response, boolean success, String message) throws IOException {
		response.setContentType("application/json");
		response.setCharacterEncoding("UTF-8");
		String msg = (message != null) ? message.replace("\"", "'") : "";
		response.getWriter().write("{\"success\":" + success + ",\"message\":\"" + msg + "\"}");
	}

	private static String coalesce(String a, String b) {
		return (a != null && !a.isBlank()) ? a : b;
	}

	private static void passAttributeIfSet(HttpServletRequest req, String key) {
		Object val = req.getAttribute(key);
		if (val != null) {
			req.setAttribute(key, val);
		}
	}
}