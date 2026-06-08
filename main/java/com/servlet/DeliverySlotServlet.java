package com.servlet;

import java.io.IOException;
import java.math.BigDecimal;
import java.sql.Connection;
import java.sql.SQLException;
import java.time.LocalDate;
import java.time.LocalTime;
import java.time.ZoneId;
import java.time.format.DateTimeFormatter;
import java.util.List;
import java.util.Map;
import java.util.logging.Level;
import java.util.logging.Logger;

import com.DAO.AgentWalletDAO;
import com.DAO.DeliveryPersonDAO;
import com.DAO.DeliverySlotDAO;
import com.util.AgentWallet;
import com.util.DBConnection;
import com.util.DeliverySlot;
import com.util.DeliveryZone;
import com.util.ShiftWindowValidator;
import com.util.User;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.MultipartConfig;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;

/**
 * DeliverySlotServlet — Updated Version using Absolute Window Coordinates
 * ─────────────────────────────────────────────────────────────────────────────
 * Refactored to leverage direct window_start_at and window_end_at expressions.
 * Cleans up error-prone local server timezone and cross-midnight date guessing.
 */
@WebServlet("/DeliverySlotServlet")
@MultipartConfig
public class DeliverySlotServlet extends HttpServlet {

	private static final long serialVersionUID = 2L;
	private static final Logger log = Logger.getLogger(DeliverySlotServlet.class.getName());

	/** Formats a LocalTime as "6:00 AM" style for user-facing messages. */
	private static final DateTimeFormatter TIME_FMT = DateTimeFormatter.ofPattern("h:mm a");

	/** Slot type whitelist */
	private static final String SLOT_TYPE_PATTERN = "AM|PM|EVENING|FULL_DAY|NIGHT|MIDNIGHT|EARLY_MORNING";

	// ─────────────────────────────────────────────────────────────────────────
	// GET
	// ─────────────────────────────────────────────────────────────────────────
	@Override
	protected void doGet(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {

		HttpSession session = req.getSession(false);
		String action = req.getParameter("action");
		if ("adminSlots".equals(action)) {
			handleAdminDashboard(req, resp);
			return;
		}
		User user = (session != null) ? (User) session.getAttribute("deliveryUser") : null;
		if (user == null) {
			resp.sendRedirect(req.getContextPath() + "/deliveryLogin.jsp");
			return;
		}

		if ("getShiftStatus".equals(action)) {
			handleGetShiftStatus(req, resp);
			return;
		}

		if ("slotHistory".equals(action)) {
			try (Connection histConn = DBConnection.getConnection()) {
				DeliverySlotDAO histDao = new DeliverySlotDAO(histConn);
				List<Map<String, Object>> bookings = histDao.getBookingHistory(user.getUid());
				Map<Integer, List<Map<String, Object>>> slotOrdersMap = new java.util.HashMap<>();
				for (Map<String, Object> b : bookings) {
					int slotId = (Integer) b.get("slotId");
					slotOrdersMap.put(slotId, histDao.getOrdersForSlot(slotId));
				}
				req.setAttribute("slotBookings", bookings);
				req.setAttribute("slotOrdersMap", slotOrdersMap);
				req.getRequestDispatcher("DeliveryPortal.jsp").forward(req, resp);
			} catch (SQLException e) {
				log.log(Level.SEVERE, "slotHistory load error for agent #" + user.getUid(), e);
				resp.sendError(HttpServletResponse.SC_INTERNAL_SERVER_ERROR, "Could not load booking history.");
			}
			return;
		}

		try (Connection conn = DBConnection.getConnection()) {
			DeliverySlotDAO slotDao = new DeliverySlotDAO(conn);
			AgentWalletDAO walletDao = new AgentWalletDAO();

			List<DeliveryZone> zones = slotDao.getAllZones();
			req.setAttribute("zones", zones);

			try {
				slotDao.syncAllCountersForAgent(user.getUid(), LocalDate.now());
			} catch (Exception syncEx) {
				log.warning("syncAllCountersForAgent non-fatal: " + syncEx.getMessage());
			}

			// ── EXPIRY SWEEP — runs ONCE on page load (GET only) ──────────────────
			// This is the ONLY correct place to call expireStaleBookedSlots().
			// Running it inside POST actions (e.g. startShift) caused the observed bug:
			// agent taps "Start Shift" → expiry fires → slot goes EXPIRED → start fails.
			// Confining expiry to GET gives the agent a clean, race-free activation window.
			try {
				slotDao.expireStaleBookedSlots();
			} catch (Exception expireEx) {
				log.warning("expireStaleBookedSlots non-fatal: " + expireEx.getMessage());
			}

			// Primary slot (highest priority — ACTIVE/ON_BREAK > BOOKED)
			DeliverySlot todaySlot = slotDao.getTodaySlot(user.getUid());
			req.setAttribute("todaySlot", todaySlot);

			// ALL today's slots for multi-slot timeline display
			List<DeliverySlot> todaySlots = slotDao.getTodaySlots(user.getUid());
			req.setAttribute("todaySlots", todaySlots);

			java.util.Set<String> bookedTypesToday = slotDao.getBookedSlotTypesForDate(user.getUid(), LocalDate.now());
			req.setAttribute("bookedSlotTypesToday", bookedTypesToday);

			try {
				AgentWallet wallet = walletDao.getWallet(user.getUid());
				req.setAttribute("agentWallet", wallet);
				req.setAttribute("walletBalance", wallet.getBalance());
				req.setAttribute("walletMinBalance", wallet.getMinBalance());
				req.setAttribute("walletEarnToday", walletDao.getEarningsToday(user.getUid()));
				req.setAttribute("walletEarnMonth", walletDao.getEarningsThisMonth(user.getUid()));
				req.setAttribute("canGoOnline", wallet.getBalance().compareTo(wallet.getMinBalance()) >= 0);
			} catch (Exception walletEx) {
				log.warning("Could not load wallet for agent #" + user.getUid() + ": " + walletEx.getMessage());
				req.setAttribute("canGoOnline", true);
			}

			req.setAttribute("maxBreakMinutes", DeliverySlotDAO.MAX_BREAK_MINUTES);
			req.setAttribute("portalMaxBreak", DeliverySlotDAO.MAX_BREAK_MINUTES);

			if (todaySlot != null && "ON_BREAK".equals(todaySlot.getStatus())) {
				int secsLeft = slotDao.getBreakSecondsRemaining(todaySlot.getSlotId());
				req.setAttribute("breakSecondsRemaining", secsLeft);
				req.setAttribute("portalBreakSecsLeft", secsLeft);
				// BUG-3 FIX: expose break_start as epoch-ms for SlotBooking.jsp live timer,
				// consistent with the fix applied to DeliveryPortalServlet in the previous
				// session.
				long breakStartEpochMs = slotDao.getBreakStartEpochMs(todaySlot.getSlotId());
				req.setAttribute("portalBreakStartEpochMs", breakStartEpochMs);
			}

			// ── UPDATED: TIMELINE TIMERS REFACTORED TO USE ABSOLUTE FIELD MARKERS ──
			java.util.Map<Integer, Long> slotStartEpochMap = new java.util.LinkedHashMap<>();
			java.util.Map<Integer, Long> slotEndEpochMap = new java.util.LinkedHashMap<>();
			java.util.Map<Integer, Boolean> slotCanStartMap = new java.util.LinkedHashMap<>();

			for (DeliverySlot s : todaySlots) {
				// Pull pre-computed absolute millisecond landmarks
				long startMs = s.getStartEpochMs();
				long endMs = s.getEndEpochMs();

				slotStartEpochMap.put(s.getSlotId(), startMs);
				slotEndEpochMap.put(s.getSlotId(), endMs);

				// Evaluate window readiness directly using database computed datetime objects
				boolean canStart = false;
				if (s.getWindowStartAt() != null && s.getWindowEndAt() != null) {
					java.time.LocalDateTime now = java.time.LocalDateTime.now();
					// BUG-6 FIX: windowStartAt is already the pre-open epoch (slot start - 15 min).
					// Previously subtracted another 15 min making the button active 30 min early.
					canStart = !now.isBefore(s.getWindowStartAt()) && now.isBefore(s.getWindowEndAt());
				}
				slotCanStartMap.put(s.getSlotId(), canStart);
			}
			req.setAttribute("slotStartEpochMap", slotStartEpochMap);
			req.setAttribute("slotEndEpochMap", slotEndEpochMap);
			req.setAttribute("slotCanStartMap", slotCanStartMap);

			java.util.Map<String, Boolean> slotBookableMap = new java.util.LinkedHashMap<>();
			LocalTime nowLocal = LocalTime.now();
			for (String code : new String[] { "MIDNIGHT", "EARLY_MORNING", "AM", "PM", "EVENING", "FULL_DAY",
					"NIGHT" }) {
				boolean bookable;
				if ("MIDNIGHT".equals(code)) {
					// MIDNIGHT (2 AM–6 AM) is booked the evening before — the booking window
					// spans the date boundary, so we treat it as always bookable from the
					// servlet's perspective (the DAO cutoff still enforces the 02:00 hard stop).
					bookable = true;
				} else if ("NIGHT".equals(code)) {
					// NIGHT is bookable before 22:00 and not in the post-midnight dead zone.
					LocalTime cutoff = DeliverySlotDAO.getSlotBookingCutoff(code);
					bookable = nowLocal.isBefore(cutoff) && !(nowLocal.isBefore(LocalTime.of(2, 0)));
				} else {
					// ROOT CAUSE FIX: EARLY_MORNING (4 AM cutoff) was incorrectly lumped with
					// MIDNIGHT as always-bookable. It must use its proper cutoff check so the
					// card is disabled once 4 AM has passed, like any other slot type.
					LocalTime cutoff = DeliverySlotDAO.getSlotBookingCutoff(code);
					bookable = nowLocal.isBefore(cutoff);
				}
				slotBookableMap.put(code, bookable);
			}
			req.setAttribute("slotBookableMap", slotBookableMap);

			if (todaySlot != null) {
				req.setAttribute("portalSlotStartEpochMs", slotStartEpochMap.get(todaySlot.getSlotId()));
				req.setAttribute("portalSlotEndEpochMs", slotEndEpochMap.get(todaySlot.getSlotId()));
				req.setAttribute("portalCanStartNow", Boolean.TRUE.equals(slotCanStartMap.get(todaySlot.getSlotId())));

				long shiftStartedAtMs = 0L;
				if (todaySlot.getShiftStartedAt() != null) {
					shiftStartedAtMs = todaySlot.getShiftStartedAt().atZone(ZoneId.systemDefault()).toInstant()
							.toEpochMilli();
				}
				req.setAttribute("portalShiftStartedAtMs", shiftStartedAtMs);
			}

			req.setAttribute("deliveryUser", user);
			req.getRequestDispatcher("SlotBooking.jsp").forward(req, resp);

		} catch (Exception e) {
			log.log(Level.SEVERE, "GET error in DeliverySlotServlet", e);
			throw new ServletException(e);
		}
	}

	// ─────────────────────────────────────────────────────────────────────────
	// POST
	// ─────────────────────────────────────────────────────────────────────────
	@Override
	protected void doPost(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {

		HttpSession session = req.getSession(false);
		User user = (session != null) ? (User) session.getAttribute("deliveryUser") : null;
		String action = req.getParameter("action");

		switch (action == null ? "" : action) {

		case "book" -> {
			if (user == null) {
				resp.sendRedirect(req.getContextPath() + "/deliveryLogin.jsp");
				return;
			}
			try {
				int zoneId = Integer.parseInt(req.getParameter("zoneId"));
				String slotType = req.getParameter("slotType");
				String dateStr = req.getParameter("slotDate");

				// MIDNIGHT POST-MIDNIGHT FIX
				// Design: MIDNIGHT slot ALWAYS stores window_start_at = DATE_ADD(slot_date, 1
				// day) 02:00.
				// If agent books at e.g. 00:30 on May 28 with slotDate=May 28:
				// window = DATE_ADD(May28, 1) = May 29 02:00 <- 25.5hrs away, WRONG
				// Correct: slotDate must be May 27 so:
				// window = DATE_ADD(May27, 1) = May 28 02:00 <- 90min away, RIGHT
				// Rule: MIDNIGHT is always "booked the previous calendar day".
				// When time is between 00:00-01:59 (before the 02:00 window opens),
				// use yesterday as slotDate so the window resolves to today 02:00.
				LocalDate slotDate;
				if (dateStr != null && !dateStr.isBlank()) {
					slotDate = LocalDate.parse(dateStr);
				} else if ("MIDNIGHT".equals(slotType) && LocalTime.now().isBefore(LocalTime.of(2, 0))) {
					// Post-midnight booking (00:00-01:59): the upcoming 02:00 window
					// is on today, so slot_date must be yesterday (DATE_ADD(yesterday,1)=today)
					slotDate = LocalDate.now().minusDays(1);
					log.info("MIDNIGHT post-midnight: slotDate set to " + slotDate
							+ " so window resolves to today 02:00");
				} else {
					slotDate = LocalDate.now();
				}

				if (slotType == null || !slotType.matches(SLOT_TYPE_PATTERN)) {
					sendJsonError(resp, "Invalid slot type: " + slotType);
					return;
				}

				try {
					AgentWalletDAO walletDao = new AgentWalletDAO();
					AgentWallet wallet = walletDao.getWallet(user.getUid());
					if (wallet.getBalance().compareTo(wallet.getMinBalance()) < 0) {
						sendJsonError(resp, "Your wallet balance (₹" + wallet.getBalance().toPlainString()
								+ ") is below the minimum required (₹" + wallet.getMinBalance().toPlainString() + ").");
						return;
					}
				} catch (Exception walletEx) {
					log.warning("Wallet check failed for agent #" + user.getUid() + ": " + walletEx.getMessage());
				}

				// ── DATE VALIDATION: advance booking support ──────────────────────────
				// Agents may book a slot for TODAY or any FUTURE date (up to 7 days ahead).
				// Booking a date in the PAST is rejected.
				// Same-day booking is still subject to the per-slot cutoff time.
				LocalDate today = LocalDate.now();
				if (slotDate.isBefore(today)) {
					// Exception: MIDNIGHT post-midnight (00:00-01:59) sets slotDate=yesterday
					// intentionally
					boolean isMidnightPostMidnight = "MIDNIGHT".equals(slotType) && slotDate.equals(today.minusDays(1))
							&& LocalTime.now().isBefore(LocalTime.of(2, 0));
					if (!isMidnightPostMidnight) {
						sendJsonError(resp, "Cannot book a slot for a past date.");
						return;
					}
				}
				if (slotDate.isAfter(today.plusDays(7))) {
					sendJsonError(resp, "Advance booking is limited to 7 days ahead.");
					return;
				}
				if (slotDate.equals(today)) {
					// Same-day: enforce per-slot cutoff time
					LocalTime now = LocalTime.now();
					LocalTime cutoff = DeliverySlotDAO.getSlotBookingCutoff(slotType);
					if (!now.isBefore(cutoff)) {
						sendJsonError(resp, "This slot's booking window has already passed for today (" + slotType
								+ "). " + "You can still book this slot type for a future date.");
						return;
					}
				}
				// Future date: no time-of-day cutoff applies — agent can book at any time
				// The slot will expire naturally 1 hour before shift end ON THAT FUTURE DATE

				try (Connection conn = DBConnection.getConnection()) {
					DeliverySlotDAO dao = new DeliverySlotDAO(conn);
					int newSlotId = dao.bookSlot(user.getUid(), zoneId, slotDate, slotType);

					if (newSlotId > 0) {
						try {
							dao.persistBooking(user.getUid(), newSlotId);
						} catch (Exception ledgerEx) {
							log.warning("persistBooking failed: " + ledgerEx.getMessage());
						}
						LocalTime startTime = DeliverySlotDAO.getSlotStartTime(slotType);
						// SLOT_BOOKED notification already pushed inside dao.bookSlot()
						sendJsonSuccess(resp, "Slot booked! Your shift starts at " + startTime.format(TIME_FMT) + ".",
								newSlotId);
					} else if (newSlotId == -1) {
						sendJsonError(resp, "You already have an active or booked slot for this operational timeline.");
					} else if (newSlotId == -2) {
						sendJsonError(resp, "Slot already closed. Please book for a future date.");
					} else {
						sendJsonError(resp, "Booking failed. Please try again.");
					}
				}
			} catch (Exception e) {
				log.log(Level.SEVERE, "book slot error", e);
				sendJsonError(resp, "Server error: " + e.getMessage());
			}
		}

		case "startShift" -> {
			if (user == null) {
				resp.sendRedirect(req.getContextPath() + "/deliveryLogin.jsp");
				return;
			}
			try {
				int slotId;
				try {
					slotId = Integer.parseInt(req.getParameter("slotId"));
				} catch (NumberFormatException nfe) {
					sendJsonError(resp, "Invalid slot ID.");
					return;
				}

				try (Connection conn = DBConnection.getConnection()) {
					DeliverySlotDAO dao = new DeliverySlotDAO(conn);

					if (!dao.isSlotActivatable(slotId, user.getUid())) {
						// Do NOT call expireStaleBookedSlots() here — it would expire the slot
						// the agent is actively trying to start, creating a race condition.
						// Expiry runs on page load (GET) only, giving the agent a clean window.
						String reason = ShiftWindowValidator.getWindowClosedReason(
								getSlotTypeForId(dao, slotId, user.getUid()),
								getSlotDateForId(dao, slotId, user.getUid()), ZoneId.systemDefault());
						sendJsonError(resp,
								reason != null ? reason : "This slot's window is not open yet or has passed.");
						return;
					}

					DeliverySlot slot = null;
					for (DeliverySlot s : dao.getTodaySlots(user.getUid())) {
						if (s.getSlotId() == slotId) {
							slot = s;
							break;
						}
					}
					if (slot == null) {
						sendJsonError(resp, "Slot not found. Please refresh.");
						return;
					}
					if (!"BOOKED".equals(slot.getStatus())) {
						sendJsonError(resp,
								"Shift cannot be activated in its current state (" + slot.getStatus() + ").");
						return;
					}

					try {
						AgentWalletDAO walletDao = new AgentWalletDAO();
						AgentWallet wallet = walletDao.getWallet(user.getUid());
						if (wallet.getBalance().compareTo(wallet.getMinBalance()) < 0) {
							sendJsonError(resp, "Cannot start shift: balance below minimum requirement.");
							return;
						}
					} catch (Exception walletEx) {
						log.warning("Wallet check skipped: " + walletEx.getMessage());
					}

					boolean ok = dao.activateSlot(slotId, user.getUid());
					if (ok) {
						log.info("Agent #" + user.getUid() + " started shift on slot #" + slotId);

						// Push SHIFT_ACTIVE notification
						try {
							dao.pushSlotNotif(user.getUid(), "SHIFT_ACTIVE", "🟢 Shift started — you are online!",
									"Your " + slot.getSlotType().toLowerCase().replace("_", " ")
											+ " shift is active. Orders will start arriving.",
									"🚴", "green", slotId);
						} catch (Exception ne) {
							log.warning("SHIFT_ACTIVE notif: " + ne.getMessage());
						}

						DeliveryPersonDAO personDao = new DeliveryPersonDAO(conn);
						personDao.updateUserStatus(user.getUid(), "Active");
						user.setStatus("Active");
						session.setAttribute("deliveryUser", user);

						// ── UPDATED: DIRECT EXTRACTION FROM POJO ABSOLUTE EPOCH MAPPINGS ──
						long startEpochMs = slot.getStartEpochMs();
						long endEpochMs = slot.getEndEpochMs();

						long shiftStartedAtMs = java.time.Instant.now().toEpochMilli();
						try {
							DeliverySlot refreshed = dao.getTodaySlot(user.getUid());
							if (refreshed != null && refreshed.getShiftStartedAt() != null) {
								shiftStartedAtMs = refreshed.getShiftStartedAt().atZone(ZoneId.systemDefault())
										.toInstant().toEpochMilli();
							}
						} catch (Exception ignored) {
						}

						LocalTime slotStart = DeliverySlotDAO.getSlotStartTime(slot.getSlotType());
						LocalTime slotEnd = DeliverySlotDAO.getSlotEndTime(slot.getSlotType());

						resp.setContentType("application/json");
						resp.setCharacterEncoding("UTF-8");
						resp.getWriter().write("{" + "\"success\":true,"
								+ "\"message\":\"Shift started! You are now online and ready to receive orders.\","
								+ "\"slotStartTime\":\"" + slotStart.format(TIME_FMT) + "\"," + "\"slotEndTime\":\""
								+ slotEnd.format(TIME_FMT) + "\"," + "\"slotStartEpochMs\":" + startEpochMs + ","
								+ "\"slotEndEpochMs\":" + endEpochMs + "," + "\"shiftStartedAtEpochMs\":"
								+ shiftStartedAtMs + "," + "\"id\":" + slotId + "}");
					} else {
						sendJsonError(resp, "Could not start shift. It may have already been activated.");
					}
				}
			} catch (Exception e) {
				log.log(Level.SEVERE, "startShift error", e);
				sendJsonError(resp, "Server error: " + e.getMessage());
			}
		}

		case "startBreak" -> {
			if (user == null) {
				resp.sendRedirect(req.getContextPath() + "/deliveryLogin.jsp");
				return;
			}
			try {
				int slotId = Integer.parseInt(req.getParameter("slotId"));
				try (Connection conn = DBConnection.getConnection()) {
					DeliverySlotDAO dao = new DeliverySlotDAO(conn);
					boolean ok = dao.startBreak(slotId, user.getUid());
					if (ok) {
						resp.setContentType("application/json");
						resp.setCharacterEncoding("UTF-8");
						resp.getWriter()
								.write("{" + "\"success\":true,\"message\":\"Break started.\"," + "\"maxBreakMinutes\":"
										+ DeliverySlotDAO.MAX_BREAK_MINUTES + "," + "\"breakSecondsTotal\":"
										+ (DeliverySlotDAO.MAX_BREAK_MINUTES * 60) + ",\"id\":" + slotId + "}");
					} else {
						sendJsonError(resp, "Cannot start break — shift is not active.");
					}
				}
			} catch (Exception e) {
				log.log(Level.SEVERE, "startBreak error", e);
				sendJsonError(resp, "Server error: " + e.getMessage());
			}
		}

		case "endBreak" -> {
			if (user == null) {
				resp.sendRedirect(req.getContextPath() + "/deliveryLogin.jsp");
				return;
			}
			try {
				int slotId = Integer.parseInt(req.getParameter("slotId"));
				try (Connection conn = DBConnection.getConnection()) {
					DeliverySlotDAO dao = new DeliverySlotDAO(conn);

					String newStatus = dao.endBreak(slotId, user.getUid());
					int totalBreakMins = dao.getBreakMinutes(slotId);

					if (newStatus == null) {
						sendJsonError(resp, "Break row reference not active.");
						return;
					}

					boolean wentOffline = "INACTIVE".equals(newStatus);
					if (wentOffline) {
						DeliveryPersonDAO dpDao = new DeliveryPersonDAO(conn);
						dpDao.updateUserStatus(user.getUid(), "Inactive");
						user.setStatus("Inactive");
						session.setAttribute("deliveryUser", user);
					}
					String msg = wentOffline ? "Break limit exceeded. Systems forced offline."
							: "Welcome back! Break used: " + totalBreakMins + " min.";

					resp.setContentType("application/json");
					resp.setCharacterEncoding("UTF-8");
					resp.getWriter()
							.write("{" + "\"success\":true,\"message\":\"" + msg + "\"," + "\"newStatus\":\""
									+ newStatus + "\"," + "\"wentOffline\":" + wentOffline + ","
									+ "\"totalBreakMinutes\":" + totalBreakMins + ",\"id\":" + slotId + "}");
				}
			} catch (Exception e) {
				log.log(Level.SEVERE, "endBreak error", e);
				sendJsonError(resp, "Server error: " + e.getMessage());
			}
		}

		case "endShift" -> {
			if (user == null) {
				resp.sendRedirect(req.getContextPath() + "/deliveryLogin.jsp");
				return;
			}
			try {
				int slotId = Integer.parseInt(req.getParameter("slotId"));
				try (Connection conn = DBConnection.getConnection()) {
					DeliverySlotDAO dao = new DeliverySlotDAO(conn);

					long[] codSummary = dao.getUndepositedCodSummary(slotId);
					if (codSummary[0] > 0) {
						resp.setContentType("application/json");
						resp.setCharacterEncoding("UTF-8");
						resp.getWriter().write("{" + "\"success\":false,\"errorCode\":\"UNDEPOSITED_COD\","
								+ "\"undepositedCount\":" + codSummary[0] + "," + "\"undepositedTotal\":"
								+ codSummary[1] + "," + "\"message\":\"Deposit pending COD collections first.\"" + "}");
						return;
					}

					int nextSlotId = dao.releaseAgentIfSlotDoneV2(slotId, user.getUid());
					if (nextSlotId == -2) {
						// -2 = isSlotSafeToComplete() returned false:
						// orders still In-Progress (Picked Up / Out for Delivery / Assigned).
						// Sync counters so the UI reflects live order state.
						try {
							dao.syncSlotCountersFromOrders(slotId);
						} catch (Exception ignored) {
						}
						sendJsonError(resp, "Cannot end shift: you still have active shipments out for delivery. "
								+ "Mark all orders as Delivered or Cancelled first.");
						return;
					}

					try {
						DeliveryPersonDAO dpDao = new DeliveryPersonDAO(conn);
						// BUG FIX: After end shift, set user status back to "Active"
						// (not "Inactive") so the agent can immediately book a new slot
						// without having to log out and back in.
						// releaseAgentIfSlotDoneV2() already sets users.status="Active" in DB;
						// we mirror that in the session object here.
						dpDao.updateUserStatus(user.getUid(), "Active");
						user.setStatus("Active");
						session.setAttribute("deliveryUser", user);
					} catch (Exception ignored) {
					}

					BigDecimal earnedToday = BigDecimal.ZERO;
					try {
						earnedToday = new AgentWalletDAO().getEarningsToday(user.getUid());
					} catch (Exception ignored) {
					}

					String nextSlotJson = nextSlotId > 0
							? ",\"nextSlotId\":" + nextSlotId + ",\"nextSlotAvailable\":true"
							: ",\"nextSlotAvailable\":false";

					resp.setContentType("application/json");
					resp.setCharacterEncoding("UTF-8");
					resp.getWriter()
							.write("{" + "\"success\":true,\"message\":\"Shift ended! Earnings credited.\","
									+ "\"earnedToday\":" + earnedToday.toPlainString() + ",\"id\":" + slotId
									+ nextSlotJson + "}");
				}
			} catch (Exception e) {
				log.log(Level.SEVERE, "endShift error", e);
				sendJsonError(resp, "Server error: " + e.getMessage());
			}
		}

		case "autoOffline" -> {
			if (user == null) {
				sendJsonError(resp, "Session expired.");
				return;
			}
			try {
				int slotId = Integer.parseInt(req.getParameter("slotId"));
				try (Connection conn = DBConnection.getConnection()) {
					DeliverySlotDAO dao = new DeliverySlotDAO(conn);
					DeliverySlot slot = dao.getTodaySlot(user.getUid());

					if (slot != null && slot.getSlotId() == slotId
							&& ("ACTIVE".equals(slot.getStatus()) || "ON_BREAK".equals(slot.getStatus()))) {
						dao.completeSlot(slotId, user.getUid());

						DeliveryPersonDAO dpDao = new DeliveryPersonDAO(conn);
						dpDao.updateUserStatus(user.getUid(), "Inactive");
						user.setStatus("Inactive");
						session.setAttribute("deliveryUser", user);

						BigDecimal earned = BigDecimal.ZERO;
						try {
							earned = new AgentWalletDAO().getEarningsToday(user.getUid());
						} catch (Exception ignored) {
						}

						resp.setContentType("application/json");
						resp.setCharacterEncoding("UTF-8");
						resp.getWriter().write("{" + "\"success\":true,\"message\":\"Your shift has ended.\","
								+ "\"earnedToday\":" + earned.toPlainString() + "}");
					} else {
						resp.setContentType("application/json");
						resp.setCharacterEncoding("UTF-8");
						resp.getWriter().write("{\"success\":true,\"message\":\"Already offline.\"}");
					}
				}
			} catch (Exception e) {
				log.log(Level.SEVERE, "autoOffline error", e);
				sendJsonError(resp, "Server error: " + e.getMessage());
			}
		}

		case "cancel" -> {
			if (user == null) {
				resp.sendRedirect(req.getContextPath() + "/DeliveryLoginServlet");
				return;
			}
			try {
				int slotId = Integer.parseInt(req.getParameter("slotId"));
				String reason = req.getParameter("reason");
				try (Connection conn = DBConnection.getConnection()) {
					DeliverySlotDAO dao = new DeliverySlotDAO(conn);
					if (dao.cancelSlot(slotId, user.getUid(), reason)) {
						dao.updateBookingStatus(slotId, "Cancelled");
						sendJsonSuccess(resp, "Slot cancelled successfully.", slotId);
					} else {
						sendJsonError(resp, "Could not cancel this slot.");
					}
				}
			} catch (Exception e) {
				log.log(Level.SEVERE, "cancel slot error", e);
				sendJsonError(resp, "Server error: " + e.getMessage());
			}
		}

		// (Keep admin actions intact below)
		case "assignOrder" -> {
			User admin = (session != null) ? (User) session.getAttribute("user") : null;
			if (admin == null || !"admin".equals(admin.getRole())) {
				resp.setStatus(403);
				return;
			}
			try {
				int orderId = Integer.parseInt(req.getParameter("orderId"));
				int agentId = Integer.parseInt(req.getParameter("agentId"));
				try (Connection conn = DBConnection.getConnection()) {
					if (new DeliverySlotDAO(conn).assignOrderToSlot(orderId, agentId)) {
						sendJsonSuccess(resp, "Order #" + orderId + " assigned to agent #" + agentId, -1);
					} else {
						sendJsonError(resp, "Assignment failed.");
					}
				}
			} catch (Exception e) {
				sendJsonError(resp, e.getMessage());
			}
		}

		case "setSurge" -> {
			User admin = (session != null) ? (User) session.getAttribute("user") : null;
			if (admin == null || !"admin".equals(admin.getRole())) {
				resp.setStatus(403);
				return;
			}
			try {
				int zoneId = Integer.parseInt(req.getParameter("zoneId"));
				boolean isSurge = "true".equals(req.getParameter("isSurge"));
				double multiplier = Double.parseDouble(req.getParameter("multiplier"));
				try (Connection conn = DBConnection.getConnection()) {
					if (new DeliverySlotDAO(conn).updateZoneSurge(zoneId, isSurge, multiplier)) {
						sendJsonSuccess(resp, "Surge toggled.", zoneId);
					} else {
						sendJsonError(resp, "Zone not found.");
					}
				}
			} catch (Exception e) {
				sendJsonError(resp, e.getMessage());
			}
		}

		case "addZone" -> {
			User admin = (session != null) ? (User) session.getAttribute("user") : null;
			if (admin == null || !"admin".equals(admin.getRole())) {
				resp.setStatus(403);
				return;
			}
			String zoneName = req.getParameter("zoneName");
			String pincodes = req.getParameter("pincodes");
			if (zoneName == null || zoneName.isBlank()) {
				sendJsonError(resp, "Zone name is required.");
				return;
			}
			try (Connection conn = DBConnection.getConnection()) {
				DeliverySlotDAO dao = new DeliverySlotDAO(conn);
				int newId = dao.addZone(zoneName, pincodes);
				if (newId == -1) {
					sendJsonError(resp, "A zone named \"" + zoneName + "\" already exists.");
				} else if (newId > 0) {
					sendJsonSuccess(resp, "Zone \"" + zoneName + "\" added successfully.", newId);
				} else {
					sendJsonError(resp, "Failed to add zone. Please try again.");
				}
			} catch (Exception e) {
				log.log(Level.SEVERE, "addZone error", e);
				sendJsonError(resp, "Server error: " + e.getMessage());
			}
		}

		case "deleteZone" -> {
			User admin = (session != null) ? (User) session.getAttribute("user") : null;
			if (admin == null || !"admin".equals(admin.getRole())) {
				resp.setStatus(403);
				return;
			}
			try {
				int zoneId = Integer.parseInt(req.getParameter("zoneId"));
				try (Connection conn = DBConnection.getConnection()) {
					DeliverySlotDAO dao = new DeliverySlotDAO(conn);
					String result = dao.deleteZone(zoneId);
					switch (result) {
					case "ok" -> sendJsonSuccess(resp, "Zone deleted successfully.", zoneId);
					case "has_slots" -> sendJsonError(resp, "Cannot delete: this zone has active or booked slots.");
					default -> sendJsonError(resp, "Zone not found.");
					}
				}
			} catch (Exception e) {
				log.log(Level.SEVERE, "deleteZone error", e);
				sendJsonError(resp, "Server error: " + e.getMessage());
			}
		}

		default -> {
			resp.setStatus(400);
			sendJsonError(resp, "Unknown action: " + action);
		}
		}
	}

	// ─────────────────────────────────────────────────────────────────────────
	// GET: getShiftStatus JSON Pipeline
	// ─────────────────────────────────────────────────────────────────────────
	private void handleGetShiftStatus(HttpServletRequest req, HttpServletResponse resp)
			throws ServletException, IOException {
		HttpSession session = req.getSession(false);
		User user = (session != null) ? (User) session.getAttribute("deliveryUser") : null;

		if (user == null) {
			resp.setStatus(401);
			sendJsonError(resp, "Not authenticated.");
			return;
		}

		try (Connection conn = DBConnection.getConnection()) {
			DeliverySlotDAO dao = new DeliverySlotDAO(conn);
			DeliverySlot slot = dao.getTodaySlot(user.getUid());

			resp.setContentType("application/json");
			resp.setCharacterEncoding("UTF-8");

			if (slot == null || "EXPIRED".equals(slot.getStatus()) || "CANCELLED".equals(slot.getStatus())) {
				resp.getWriter().write("{\"hasSlot\":false,\"agentStatus\":\"" + safeStatus(user) + "\"}");
				return;
			}

			String agentStatus = switch (slot.getStatus()) {
			case "ACTIVE", "ON_BREAK" -> "Active";
			default -> "Inactive";
			};

			// ── UPDATED: STREAMLINED DATA LOADING DIRECTLY FROM MODEL FIELDS ──
			long startEpochMs = slot.getStartEpochMs();
			long endEpochMs = slot.getEndEpochMs();

			long shiftStartedAtMs = 0L;
			if (slot.getShiftStartedAt() != null) {
				shiftStartedAtMs = slot.getShiftStartedAt().atZone(ZoneId.systemDefault()).toInstant().toEpochMilli();
			}

			String slotStartTimeFmt = DeliverySlotDAO.getSlotStartTime(slot.getSlotType())
					.format(DateTimeFormatter.ofPattern("h:mm a"));
			String slotEndTimeFmt = DeliverySlotDAO.getSlotEndTime(slot.getSlotType())
					.format(DateTimeFormatter.ofPattern("h:mm a"));

			resp.getWriter()
					.write("{" + "\"hasSlot\":true," + "\"slotId\":" + slot.getSlotId() + "," + "\"status\":\""
							+ slot.getStatus() + "\"," + "\"slotType\":\"" + slot.getSlotType() + "\","
							+ "\"slotStartTime\":\"" + slotStartTimeFmt + "\"," + "\"slotEndTime\":\"" + slotEndTimeFmt
							+ "\"," + "\"slotStartEpochMs\":" + startEpochMs + "," + "\"slotEndEpochMs\":" + endEpochMs
							+ "," + "\"shiftStartedAtEpochMs\":" + shiftStartedAtMs + "," + "\"breakStartEpoch\":"
							+ slot.getBreakStartEpoch() + "," + "\"totalBreakMin\":" + slot.getTotalBreakMin() + ","
							+ "\"agentStatus\":\"" + agentStatus + "\"" + "}");

		} catch (Exception e) {
			log.log(Level.SEVERE, "getShiftStatus error", e);
			sendJsonError(resp, "Server error: " + e.getMessage());
		}
	}

	private void handleAdminDashboard(HttpServletRequest req, HttpServletResponse resp)
			throws ServletException, IOException {
		HttpSession session = req.getSession(false);
		User admin = (session != null) ? (User) session.getAttribute("user") : null;
		if (admin == null) {
			resp.sendRedirect(req.getContextPath() + "/dashboard.jsp");
			return;
		}
		try {
			String dateParam = req.getParameter("date");
			LocalDate viewDate = (dateParam != null && !dateParam.isBlank()) ? LocalDate.parse(dateParam)
					: LocalDate.now();
			try (Connection conn = DBConnection.getConnection()) {
				DeliverySlotDAO dao = new DeliverySlotDAO(conn);
				req.setAttribute("slots", dao.getSlotsForDate(viewDate));
				req.setAttribute("zones", dao.getAllZones());
				req.setAttribute("viewDate", viewDate);
				req.getRequestDispatcher("SlotDashboard.jsp").forward(req, resp);
			}
		} catch (Exception e) {
			throw new ServletException(e);
		}
	}

	private void sendJsonSuccess(HttpServletResponse resp, String message, int id) throws IOException {
		resp.setContentType("application/json");
		resp.setCharacterEncoding("UTF-8");
		resp.getWriter()
				.write("{\"success\":true,\"message\":\"" + message.replace("\"", "'") + "\",\"id\":" + id + "}");
	}

	private void sendJsonError(HttpServletResponse resp, String message) throws IOException {
		resp.setContentType("application/json");
		resp.setCharacterEncoding("UTF-8");
		resp.getWriter().write("{\"success\":false,\"message\":\"" + message.replace("\"", "'") + "\"}");
	}

	private static String safeStatus(User u) {
		return (u != null && u.getStatus() != null) ? u.getStatus() : "Inactive";
	}

	/**
	 * Looks up the slot_type for a given slotId from today's slots list. Used by
	 * startShift to produce a meaningful window-closed reason message.
	 */
	private String getSlotTypeForId(DeliverySlotDAO dao, int slotId, int agentId) {
		try {
			for (DeliverySlot s : dao.getTodaySlots(agentId)) {
				if (s.getSlotId() == slotId) {
					return s.getSlotType();
				}
			}
		} catch (Exception ignored) {
		}
		return "AM";
	}

	/**
	 * Looks up the slot_date for a given slotId from today's slots list. Returns
	 * LocalDate.now() as a safe fallback.
	 */
	private java.time.LocalDate getSlotDateForId(DeliverySlotDAO dao, int slotId, int agentId) {
		try {
			for (DeliverySlot s : dao.getTodaySlots(agentId)) {
				if (s.getSlotId() == slotId) {
					return s.getSlotDate();
				}
			}
		} catch (Exception ignored) {
		}
		return java.time.LocalDate.now();
	}
}