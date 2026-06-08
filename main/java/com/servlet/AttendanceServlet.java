package com.servlet;

import java.io.IOException;
import java.io.PrintWriter;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.LocalTime;
import java.time.format.DateTimeFormatter;
import java.util.List;

import com.DAO.AttendanceDAO;
import com.DAO.AttendanceDAO.PunchInCheckResult;
import com.util.AttendanceLogEntry;
import com.util.AttendanceSession;
import com.util.AttendanceStatusUtil;
import com.util.DBConnection;
import com.util.OfficeShift;

import jakarta.servlet.ServletContext;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;

/**
 * AttendanceServlet v5 — bug-fixed, contextual-toast, unified-status bridge.
 *
 * ── BUGS FIXED IN v5 ──────────────────────────────────────────────────────
 *
 * BUG 1 — PARAMETER NAME MISMATCH on punch-out while on break (critical). The
 * JSP sent breakDurationMs as "additionalBreakMs" in the POST body but the
 * servlet read req.getParameter("breakDurationMs"). When a staff member punched
 * out while still on break, the uncommitted break time was silently dropped,
 * inflating net_work_ms. FIX: servlet now reads BOTH "additionalBreakMs" and
 * "breakDurationMs" (legacy) so old and new clients both work.
 *
 * BUG 2 — buildNoSessionJson() hardcoded attendanceStatus="absent". This caused
 * the badge to show "Absent" at 8 AM before the staff member had even arrived,
 * even though the correct display is "No Check-In". FIX: status is now
 * "no_checkin" and label is "No Check-In".
 *
 * BUG 3 — punchIn response sent attendanceLabel:"In Progress" even for LATE.
 * FIX: Late punch-ins now get attendanceLabel:"Late Arrival" in the response so
 * the initial badge shows the correct state immediately.
 *
 * BUG 4 — getLabel() / getCss() did not handle unified lowercase_snake status
 * strings from AttendanceStatusUtil ("full_day", "half_day", "overtime",
 * "late_half", "late_overtime"). They fell through to the default "In
 * Progress". FIX: getLabel() and getCss() now call AttendanceStatusUtil.label()
 * and .cssClass() as the single source of truth.
 *
 * BUG 5 — No contextual toast reasons were returned by the servlet.
 * Requirement: toasts should explain WHY status is late / why break was
 * blocked, etc. FIX: punchIn, punchOut, startBreak responses all include a
 * "toastMsg" field built by AttendanceStatusUtil.buildStatusReason().
 *
 * BUG 6 — AUTO_CLOSE banner check used equalsIgnoreCase("AUTO_CLOSE") but the
 * DB now stores 'auto_close' (v5 lowercase fix). FIX: comparison is
 * case-insensitive so both old and new rows work.
 *
 * ── Staff actions (POST) ──────────────────────────────────────────────────
 * punchIn → pre-punch check → start session; toast includes late reason
 * startBreak → onBreak (max MAX_BREAKS_PER_SHIFT); toast explains limit
 * resumeWork → end break, accumulate breakDurationMs punchOut → finalise; toast
 * includes status reason + explanation
 *
 * ── Staff actions (GET) ───────────────────────────────────────────────────
 * todaySession → restore today's session on page load; prevAutoClose flag
 * history → past N days for logged-in staff member
 *
 * ── Admin read actions (GET) ──────────────────────────────────────────────
 * allStaff → all sessions for a given date shifts → all office_shifts
 * configurations notifications → unread admin notifications staffList → all
 * staff with their assigned shift_id
 *
 * ── Admin write actions (POST) ────────────────────────────────────────────
 * saveShift → create or update an office_shifts row assignShift → map a user to
 * a shift_id markNotifRead → mark one notification as read dismissNotif →
 * dismiss one notification
 */
@WebServlet("/AttendanceServlet")
public class AttendanceServlet extends HttpServlet {

	/**
	 * Maximum breaks allowed per shift. Keep in sync with
	 * AttendanceDAO.MAX_BREAKS_PER_SHIFT.
	 */
	private static final int MAX_BREAKS_PER_DAY = AttendanceDAO.MAX_BREAKS_PER_SHIFT;

	private static final DateTimeFormatter DT_FMT = DateTimeFormatter.ofPattern("dd-MMM-yyyy hh:mm a");
	private static final DateTimeFormatter TIME_FMT = DateTimeFormatter.ofPattern("hh:mm a");
	private static final DateTimeFormatter DATE_FMT = DateTimeFormatter.ofPattern("dd-MMM-yyyy");
	private static final DateTimeFormatter ISO_TIME = DateTimeFormatter.ofPattern("HH:mm");
	private static final DateTimeFormatter ISO_AMPM = DateTimeFormatter.ofPattern("hh:mm a");

	private final AttendanceDAO dao = new AttendanceDAO();

	// ════════════════════════════════════════════════════════════════════════
	// GET — read-only queries
	// ════════════════════════════════════════════════════════════════════════
	@Override
	protected void doGet(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {

		setJsonHeaders(resp);

		String username = getUsername(req);
		if (username == null) {
			sendError(resp, 401, "Not logged in.");
			return;
		}

		String action = nvl(req.getParameter("action"));

		try (PrintWriter out = resp.getWriter()) {
			switch (action) {

			// ── Today's session (staff page-load restore) ─────────────────
			case "todaySession": {
				OfficeShift shift = resolveShiftForUser(username);
				LocalDate attendDate = resolveAttendanceDate(shift, LocalDateTime.now());
				AttendanceSession s = dao.getSessionByUserAndDate(username, attendDate);

				if (s == null) {
					// Check if previous session was auto-closed
					boolean prevAutoClose = false;
					AttendanceSession last = dao.getLastSessionForUser(username);
					if (last != null && "auto_close".equalsIgnoreCase(last.getAttendanceStatus())) {
						prevAutoClose = true;
					}

					// Check for stale open session from yesterday (e.g. missed punch-out,
					// auto-close sweep hasn't fired yet). This lets the staff dashboard
					// show the "Previous Session Still Open" banner so the staff member
					// understands why they can't start a new session.
					AttendanceSession stale = dao.getAnyOpenSessionForUser(username);
					String prevOpenSessionJson = "null";
					if (stale != null && !stale.getSessionDate().equals(attendDate)) {
						// It's from a different (previous) date — genuinely stale
						prevOpenSessionJson = "{" + "\"sessionDate\":\"" + stale.getSessionDate() + "\""
								+ ",\"punchInTime\":" + toEpochMs(stale.getPunchIn()) + ",\"punchInStr\":\""
								+ stale.getPunchIn().format(TIME_FMT) + "\"" + ",\"sessionId\":" + stale.getId() + "}";
					}

					out.print(buildNoSessionJson(shift, prevAutoClose, prevOpenSessionJson));
				} else {
					s.setLogEntries(dao.getLogBySession(s.getId()));
					out.print(sessionToJson(s));
				}
				break;
			}

			// ── History ───────────────────────────────────────────────────
			case "history": {
				int days = parseIntOrDefault(req.getParameter("days"), 30);
				LocalDate to = LocalDate.now();
				LocalDate from = to.minusDays(days);
				out.print(historyToJson(dao.getHistoryByUser(username, from, to)));
				break;
			}

			// ── Admin: all staff for a date ───────────────────────────────
			case "allStaff": {
				if (!requireAdmin(req, resp)) {
					return;
				}
				String dateParam = req.getParameter("date");
				LocalDate date = (dateParam != null && !dateParam.isBlank()) ? LocalDate.parse(dateParam)
						: LocalDate.now();
				out.print(allStaffToJson(dao.getAllSessionsByDate(date), getAllStaffUsernames()));
				break;
			}

			// ── Admin: shift configurations ───────────────────────────────
			case "shifts": {
				if (!requireAdmin(req, resp)) {
					return;
				}
				out.print(shiftsToJson(dao.getAllShifts()));
				break;
			}

			// ── Admin: unread notifications ───────────────────────────────
			case "notifications": {
				if (!requireAdmin(req, resp)) {
					return;
				}
				out.print(notificationsToJson(dao.getUnreadNotifications()));
				break;
			}

			// ── Admin: staff list with shift assignments ───────────────────
			case "staffList": {
				if (!requireAdmin(req, resp)) {
					return;
				}
				out.print(staffListToJson());
				break;
			}

			default:
				sendError(resp, 400, "Unknown action: " + action);
			}

		} catch (SQLException e) {
			e.printStackTrace();
			sendError(resp, 500, "Database error: " + e.getMessage());
		}
	}

	// ════════════════════════════════════════════════════════════════════════
	// POST — state-changing actions
	// ════════════════════════════════════════════════════════════════════════
	@Override
	protected void doPost(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {

		setJsonHeaders(resp);

		String username = getUsername(req);
		if (username == null) {
			sendError(resp, 401, "Not logged in.");
			return;
		}

		String action = nvl(req.getParameter("action"));

		try (PrintWriter out = resp.getWriter()) {
			switch (action) {

			// ── PUNCH IN ──────────────────────────────────────────────────
			case "punchIn": {
				LocalDateTime now = LocalDateTime.now();

				OfficeShift shift = resolveShiftForUser(username);
				LocalDate attendDate = resolveAttendanceDate(shift, now);
				boolean postMidnight = isPostMidnightNightShift(shift, now);

				// Guard 1: already punched in?
				AttendanceSession existing = dao.getSessionByUserAndDate(username, attendDate);
				if (existing != null) {
					existing.setLogEntries(dao.getLogBySession(existing.getId()));
					out.print("{\"ok\":false,\"error\":\"Already punched in today.\"" + ",\"session\":"
							+ sessionToJson(existing) + "}");
					return;
				}

				// Guard 2: pre-punch shift gate (skip for post-midnight night shifts)
				if (!postMidnight) {
					PunchInCheckResult check = dao.checkPunchInAllowed(username, now);
					if (!check.allowed) {
						resp.setStatus(409);
						out.print("{\"ok\":false,\"blocked\":true" + ",\"reason\":\"" + esc(check.reason) + "\""
								+ ",\"error\":\"" + esc(check.message) + "\"}");
						return;
					}
				}

				long sessionId = dao.punchIn(username, now, attendDate);
				dao.addLogEntry(new AttendanceLogEntry(sessionId, username, "PUNCH_IN", now));

				// BUG FIX: isLate computed here (not stored in DB yet — session is 'pending')
				boolean isLate = dao.isLatePunchIn(now, shift);
				String shiftJson = shift != null ? shiftToJson(shift) : "null";

				// Build contextual late-reason toast
				String lateReason = null;
				if (isLate && shift != null) {
					LocalTime deadline = shift.getExpectedLoginTime().plusMinutes(shift.getLateGraceMinutes());
					lateReason = "⏰ Late Check-In — You punched in at " + now.format(ISO_AMPM) + " which is after the "
							+ deadline.format(ISO_AMPM) + " grace deadline for the " + shift.getShiftName() + " shift. "
							+ "This session will be marked as Late unless you work full shift hours.";
				} else if (isLate) {
					lateReason = "⏰ Late Check-In — You punched in at " + now.format(ISO_AMPM) + " (after "
							+ AttendanceStatusUtil.LATE_THRESHOLD.format(ISO_AMPM)
							+ " late threshold). Session will be marked as a Late Mark.";
				}

				// BUG FIX: attendanceLabel was always "In Progress" even for late punch-in
				String attLabel = isLate ? "Late Arrival" : "In Progress";
				String attCss = isLate ? "late" : "pending";
				String toastMsg = isLate ? lateReason
						: "✅ Punched In at " + now.format(ISO_AMPM) + ". Have a great shift!";

				out.print("{\"ok\":true" + ",\"sessionId\":" + sessionId + ",\"punchInTime\":" + toEpochMs(now)
						+ ",\"timeStr\":\"" + now.format(TIME_FMT) + "\"" + ",\"attendanceStatus\":\""
						+ (isLate ? "late" : "pending") + "\"" + ",\"attendanceLabel\":\"" + attLabel + "\""
						+ ",\"attendanceCss\":\"" + attCss + "\"" + ",\"breakCount\":0" + ",\"isLate\":" + isLate
						+ ",\"lateWarning\":" + (isLate ? "\"" + esc(lateReason) + "\"" : "null") + ",\"toastMsg\":\""
						+ esc(toastMsg) + "\"" + ",\"shift\":" + shiftJson + "}");
				break;
			}

			// ── START BREAK ───────────────────────────────────────────────
			case "startBreak": {
				long sessionId = parseLongParam(req, "sessionId");
				if (sessionId < 0) {
					sendError(resp, 400, "Missing sessionId.");
					return;
				}

				int currentBreaks = dao.getBreakCount(sessionId);
				if (currentBreaks >= MAX_BREAKS_PER_DAY) {
					// BUG FIX: message now explains WHY (2 breaks = at the limit, not >2)
					String reason = "☕ Break Limit Reached — You have already used all " + MAX_BREAKS_PER_DAY
							+ " break(s) allowed per shift. "
							+ "Breaks in excess of the limit could affect your attendance record.";
					out.print("{\"ok\":false" + ",\"breakLimitReached\":true" + ",\"breakCount\":" + currentBreaks
							+ ",\"error\":\"Maximum " + MAX_BREAKS_PER_DAY + " break(s) allowed per shift.\""
							+ ",\"toastMsg\":\"" + esc(reason) + "\"}");
					return;
				}

				dao.startBreak(sessionId);
				LocalDateTime now = LocalDateTime.now();
				dao.addLogEntry(new AttendanceLogEntry(sessionId, username, "BREAK_START", now));
				int newCount = currentBreaks + 1;
				int remaining = MAX_BREAKS_PER_DAY - newCount;

				String brToast = "☕ Break started at " + now.format(ISO_AMPM) + ". "
						+ (remaining > 0 ? remaining + " break(s) remaining for this shift."
								: "This is your last allowed break for this shift.");

				out.print("{\"ok\":true" + ",\"timeStr\":\"" + now.format(TIME_FMT) + "\"" + ",\"breakCount\":"
						+ newCount + ",\"breaksRemaining\":" + remaining + ",\"toastMsg\":\"" + esc(brToast) + "\"}");
				break;
			}

			// ── RESUME WORK ───────────────────────────────────────────────
			case "resumeWork": {
				long sessionId = parseLongParam(req, "sessionId");
				long breakDurMs = parseLongParam(req, "breakDurationMs");
				if (sessionId < 0) {
					sendError(resp, 400, "Missing sessionId.");
					return;
				}

				dao.resumeWork(sessionId, Math.max(0, breakDurMs));
				LocalDateTime now = LocalDateTime.now();
				AttendanceLogEntry e = new AttendanceLogEntry(sessionId, username, "BREAK_END", now);
				e.setBreakDurationMs(Math.max(0, breakDurMs));
				dao.addLogEntry(e);

				String resumeToast = "▶ Resumed work at " + now.format(ISO_AMPM) + ". Break duration: "
						+ fmtMsShort(Math.max(0, breakDurMs)) + ".";

				out.print("{\"ok\":true" + ",\"timeStr\":\"" + now.format(TIME_FMT) + "\"" + ",\"breakDurationMs\":"
						+ Math.max(0, breakDurMs) + ",\"breakCount\":" + dao.getBreakCount(sessionId)
						+ ",\"toastMsg\":\"" + esc(resumeToast) + "\"}");
				break;
			}

			// ── PUNCH OUT ─────────────────────────────────────────────────
			case "punchOut": {
				long sessionId = parseLongParam(req, "sessionId");
				if (sessionId < 0) {
					sendError(resp, 400, "Missing sessionId.");
					return;
				}

				// BUG FIX: was reading "breakDurationMs" but JSP sends "additionalBreakMs".
				// Read BOTH to stay backward-compatible.
				long additionalBreakMs = parseLongParam(req, "additionalBreakMs");
				if (additionalBreakMs < 0) {
					additionalBreakMs = parseLongParam(req, "breakDurationMs");
				}
				if (additionalBreakMs < 0) {
					additionalBreakMs = 0;
				}

				LocalDateTime now = LocalDateTime.now();
				dao.punchOut(sessionId, now, additionalBreakMs);
				dao.addLogEntry(new AttendanceLogEntry(sessionId, username, "PUNCH_OUT", now));

				AttendanceSession finalSession = dao.getSessionById(sessionId);
				String attStatus = finalSession != null ? finalSession.getAttendanceStatus() : "absent";
				long netWorkMs = finalSession != null ? finalSession.getNetWorkMs() : 0;
				long totalBreakMs = finalSession != null ? finalSession.getTotalBreakMs() : 0;

				// Build contextual punch-out toast reason
				OfficeShift shift = null;
				long shiftDurationMs = 0;
				if (finalSession != null && finalSession.getShiftId() > 0) {
					shift = dao.getShiftById(finalSession.getShiftId());
					if (shift != null) {
						shiftDurationMs = AttendanceDAO.computeShiftDurationMs(shift);
					}
				}

				double netHours = netWorkMs / 3_600_000.0;
				double fullHours = shiftDurationMs > 0 ? shiftDurationMs / 3_600_000.0
						: AttendanceStatusUtil.DEFAULT_FULL_DAY_MS / 3_600_000.0;

				String lateDeadline = "11:00 AM"; // fallback
				if (shift != null) {
					LocalTime dl = shift.getExpectedLoginTime().plusMinutes(shift.getLateGraceMinutes());
					lateDeadline = dl.format(ISO_AMPM);
				}
				String punchInStr = finalSession != null ? finalSession.getPunchIn().format(ISO_AMPM) : "";

				String toastMsg = AttendanceStatusUtil.buildStatusReason(attStatus,
						shift != null ? shift.getShiftName() : null, lateDeadline, punchInStr, netHours, fullHours);

				out.print("{\"ok\":true" + ",\"punchOutTime\":" + toEpochMs(now) + ",\"timeStr\":\""
						+ now.format(TIME_FMT) + "\"" + ",\"attendanceStatus\":\"" + esc(attStatus) + "\""
						+ ",\"attendanceLabel\":\"" + esc(getLabel(attStatus)) + "\"" + ",\"attendanceCss\":\""
						+ esc(getCss(attStatus)) + "\"" + ",\"netWorkMs\":" + netWorkMs + ",\"totalBreakMs\":"
						+ totalBreakMs + ",\"toastMsg\":\"" + esc(toastMsg) + "\"}");
				break;
			}

			// ── Admin: save (create/update) a shift ───────────────────────
			case "saveShift": {
				if (!requireAdmin(req, resp)) {
					return;
				}
				OfficeShift shift = new OfficeShift();
				shift.setId(parseIntOrDefault(req.getParameter("shiftId"), 0));
				shift.setShiftName(req.getParameter("shiftName"));
				shift.setExpectedLoginTime(LocalTime.parse(nvl(req.getParameter("loginTime")), ISO_TIME));
				shift.setExpectedLogoutTime(LocalTime.parse(nvl(req.getParameter("logoutTime")), ISO_TIME));
				shift.setLateGraceMinutes(parseIntOrDefault(req.getParameter("graceMinutes"), 60));

				boolean isUpdate = shift.getId() > 0;

				// Fetch existing shift BEFORE saving so we can compare times for notification
				OfficeShift oldShift = isUpdate ? dao.getShiftById(shift.getId()) : null;

				int savedId = dao.saveShift(shift);
				shift.setId(savedId);

				// If this is an UPDATE (not a new shift), email all affected staff
				if (isUpdate && oldShift != null) {
					boolean timesChanged = !shift.getExpectedLoginTime().equals(oldShift.getExpectedLoginTime())
							|| !shift.getExpectedLogoutTime().equals(oldShift.getExpectedLogoutTime())
							|| !shift.getShiftName().equals(oldShift.getShiftName())
							|| shift.getLateGraceMinutes() != oldShift.getLateGraceMinutes();

					if (timesChanged) {
						try {
							java.util.List<com.util.User> affected = dao.getUsersOnShift(savedId);
							if (!affected.isEmpty()) {
								ServletContext ctx = getServletContext();
								String host = ctx.getInitParameter("mail.smtp.host");
								String port = ctx.getInitParameter("mail.smtp.port");
								String mailUser = ctx.getInitParameter("mail.smtp.user");
								String mailPass = ctx.getInitParameter("mail.smtp.password");

								java.time.format.DateTimeFormatter timeFmt = java.time.format.DateTimeFormatter
										.ofPattern("hh:mm a");

								for (com.util.User u : affected) {
									if (u.getEmail() == null || u.getEmail().isBlank()) {
										continue;
									}
									String html = buildShiftChangeEmail(u.getUsername(), oldShift, shift, timeFmt);
									try {
										com.util.EmailUtil.sendEmail(host, port, mailUser, mailPass, u.getEmail(),
												"Your work schedule has been updated — " + shift.getShiftName(), html);
									} catch (Exception mailEx) {
										log("saveShift: email failed for " + u.getEmail() + ": " + mailEx.getMessage());
									}
								}
								log("saveShift: shift-change emails sent to " + affected.size() + " staff for shift #"
										+ savedId);
							}
						} catch (Exception notifEx) {
							log("saveShift: could not send shift-change notifications: " + notifEx.getMessage());
						}
					}
				}

				out.print("{\"ok\":true,\"shiftId\":" + savedId + "}");
				break;
			}

			// ── Admin: assign a user to a shift ───────────────────────────
			case "assignShift": {
				if (!requireAdmin(req, resp)) {
					return;
				}
				String targetUser = req.getParameter("username");
				String shiftIdStr = req.getParameter("shiftId");
				Integer shiftId = (shiftIdStr != null && !shiftIdStr.isBlank()) ? Integer.parseInt(shiftIdStr) : null;

				// Capture old shift BEFORE reassigning so we can describe what changed in the
				// email
				com.util.User staffUser = new com.DAO.UserDAO().getUserByUsername(targetUser);
				int oldShiftId = (staffUser != null) ? staffUser.getShiftId() : 0;

				dao.assignUserShift(targetUser, shiftId);

				// Send notification email only when moving to a different (non-null) shift
				if (shiftId != null && shiftId != oldShiftId && staffUser != null && staffUser.getEmail() != null
						&& !staffUser.getEmail().isBlank()) {
					try {
						OfficeShift newShift = dao.getShiftById(shiftId);
						OfficeShift prevShift = (oldShiftId > 0) ? dao.getShiftById(oldShiftId) : null;
						if (newShift != null) {
							ServletContext ctx = getServletContext();
							String html = buildAssignShiftEmail(staffUser.getUsername(), prevShift, newShift);
							com.util.EmailUtil.sendEmail(ctx.getInitParameter("mail.smtp.host"),
									ctx.getInitParameter("mail.smtp.port"), ctx.getInitParameter("mail.smtp.user"),
									ctx.getInitParameter("mail.smtp.password"), staffUser.getEmail(),
									"You've been assigned to a new shift \u2014 " + newShift.getShiftName(), html);
						}
					} catch (Exception mailEx) {
						log("assignShift: email failed for " + targetUser + ": " + mailEx.getMessage());
					}
				}

				out.print("{\"ok\":true}");
				break;
			}

			// ── Admin: force punch-out a specific staff member ────────────
			case "adminForcePunchOut": {
				if (!requireAdmin(req, resp)) {
					return;
				}
				String targetUser = req.getParameter("username");
				String note = nvl(req.getParameter("note")).trim();
				if (targetUser == null || targetUser.isBlank()) {
					sendError(resp, 400, "Missing username.");
					return;
				}
				if (note.isBlank()) {
					note = "Force punch-out by admin.";
				}

				// ── Pre-check: does the user actually have an open session? ──
				// getAnyOpenSessionForUser now searches up to 7 days back so
				// stale sessions from nights, weekends, etc. are found correctly.
				AttendanceSession openCheck = dao.getAnyOpenSessionForUser(targetUser);
				if (openCheck == null) {
					// No open session — return a helpful error to the admin UI
					// instead of throwing a 500. This happens when:
					// - The session was already auto-closed by the sweep
					// - The staff member already punched out manually
					// - The session_date is beyond the 7-day window (extremely stale)
					out.print("{\"ok\":false" + ",\"noSession\":true" + ",\"error\":\"No open session found for '"
							+ esc(targetUser) + "'. The session may have already been closed. "
							+ "Refresh the attendance monitor to see the current state.\"}");
					return;
				}

				LocalDateTime closedAt = dao.adminForcePunchOut(targetUser, note);

				// Re-fetch the closed session to send accurate status back to UI.
				// Search up to 7 days back matching closedAt date.
				LocalDate closedDate = closedAt.toLocalDate();
				AttendanceSession final_ = dao.getSessionByUserAndDate(targetUser, closedDate);
				if (final_ == null) {
					// Fallback: try today and yesterday
					final_ = dao.getSessionByUserAndDate(targetUser, LocalDate.now());
				}
				if (final_ == null) {
					final_ = dao.getSessionByUserAndDate(targetUser, LocalDate.now().minusDays(1));
				}

				String attStatus = final_ != null ? final_.getAttendanceStatus() : "auto_close";
				long netWorkMs = final_ != null ? final_.getNetWorkMs() : 0;
				String timeStr = closedAt.format(DateTimeFormatter.ofPattern("hh:mm a"));

				String toastMsg = "✅ Force punch-out applied for '" + targetUser + "' at " + timeStr + ". Status: "
						+ AttendanceStatusUtil.label(attStatus) + " | Net work: "
						+ AttendanceStatusUtil.formatMs(netWorkMs) + ".";

				out.print("{\"ok\":true" + ",\"username\":\"" + esc(targetUser) + "\"" + ",\"closedAt\":\"" + timeStr
						+ "\"" + ",\"attendanceStatus\":\"" + esc(attStatus) + "\"" + ",\"attendanceLabel\":\""
						+ esc(AttendanceStatusUtil.label(attStatus)) + "\"" + ",\"netWorkMs\":" + netWorkMs
						+ ",\"toastMsg\":\"" + esc(toastMsg) + "\"}");
				break;
			}

			// ── Admin: adjust session times ───────────────────────────────
			case "adminAdjustSession": {
				if (!requireAdmin(req, resp)) {
					return;
				}
				String targetUser = req.getParameter("username");
				String dateStr = req.getParameter("sessionDate");
				String punchInStr = nvl(req.getParameter("punchIn")).trim();
				String punchOutStr = nvl(req.getParameter("punchOut")).trim();
				String note = nvl(req.getParameter("note")).trim();

				// ── Server-side validation ────────────────────────────────
				if (targetUser == null || targetUser.isBlank()) {
					sendError(resp, 400, "Missing username.");
					return;
				}
				if (note.isBlank()) {
					sendError(resp, 400, "Note/reason is required.");
					return;
				}
				// BUG FIX: reject immediately if both times are blank (DAO would throw,
				// but return a clean 400 before even hitting the DB)
				if (punchInStr.isEmpty() && punchOutStr.isEmpty()) {
					sendError(resp, 400, "Please provide at least one corrected time (punch-in or punch-out).");
					return;
				}

				LocalDate sessionDate = (dateStr != null && !dateStr.isBlank()) ? LocalDate.parse(dateStr)
						: LocalDate.now();

				LocalDateTime newIn = punchInStr.isEmpty() ? null : sessionDate.atTime(LocalTime.parse(punchInStr));
				LocalDateTime newOut = punchOutStr.isEmpty() ? null : sessionDate.atTime(LocalTime.parse(punchOutStr));

				// Handle overnight: if punchOut < punchIn, it's next-day
				if (newIn != null && newOut != null && newOut.isBefore(newIn)) {
					newOut = newOut.plusDays(1);
				}

				// BUG FIX: validate adjusted punch-in is not after punch-out on server
				// (complements the DAO check but gives a friendlier error before the DB call)
				if (newIn != null && newOut != null && !newIn.isBefore(newOut)) {
					sendError(resp, 400, "Punch-in time must be before punch-out time.");
					return;
				}

				try {
					dao.adminAdjustSession(targetUser, sessionDate, newIn, newOut, note);
				} catch (SQLException ex) {
					// Surface DAO validation errors (no-op, invalid times, session not found)
					// as clean 400s rather than 500s
					sendError(resp, 400, ex.getMessage());
					return;
				}

				// Fetch updated session for response
				AttendanceSession updated = dao.getSessionByUserAndDate(targetUser, sessionDate);
				String attStatus = updated != null ? updated.getAttendanceStatus() : "pending";
				long netWorkMs = updated != null ? updated.getNetWorkMs() : 0;

				String toastMsg = "✅ Session adjusted for '" + targetUser + "'. " + "Status: "
						+ AttendanceStatusUtil.label(attStatus) + " | Net work: "
						+ AttendanceStatusUtil.formatMs(netWorkMs) + ".";

				out.print("{\"ok\":true" + ",\"username\":\"" + esc(targetUser) + "\"" + ",\"attendanceStatus\":\""
						+ esc(attStatus) + "\"" + ",\"attendanceLabel\":\"" + esc(AttendanceStatusUtil.label(attStatus))
						+ "\"" + ",\"netWorkMs\":" + netWorkMs + ",\"toastMsg\":\"" + esc(toastMsg) + "\"}");
				break;
			}

			// ── Admin: mark notification read ─────────────────────────────
			case "markNotifRead": {
				if (!requireAdmin(req, resp)) {
					return;
				}
				int id = parseIntOrDefault(req.getParameter("id"), -1);
				if (id > 0) {
					dao.markNotificationRead(id);
				}
				out.print("{\"ok\":true}");
				break;
			}

			// ── Admin: dismiss notification ───────────────────────────────
			case "dismissNotif": {
				if (!requireAdmin(req, resp)) {
					return;
				}
				int id = parseIntOrDefault(req.getParameter("id"), -1);
				if (id > 0) {
					dao.dismissNotification(id);
				}
				out.print("{\"ok\":true}");
				break;
			}

			default:
				sendError(resp, 400, "Unknown action: " + action);
			}

		} catch (SQLException e) {
			e.printStackTrace();
			sendError(resp, 500, "Database error: " + e.getMessage());
		}
	}

	// ════════════════════════════════════════════════════════════════════════
	// SHIFT RESOLUTION HELPERS
	// ════════════════════════════════════════════════════════════════════════

	private OfficeShift resolveShiftForUser(String username) {
		try {
			String sql = "SELECT shift_id FROM users WHERE username = ?";
			try (Connection con = DBConnection.getConnection(); PreparedStatement ps = con.prepareStatement(sql)) {
				ps.setString(1, username);
				try (ResultSet rs = ps.executeQuery()) {
					if (rs.next()) {
						int sid = rs.getInt("shift_id");
						if (!rs.wasNull()) {
							return dao.getShiftById(sid);
						}
					}
				}
			}
		} catch (SQLException ignored) {
		}
		return null;
	}

	private LocalDate resolveAttendanceDate(OfficeShift shift, LocalDateTime now) {
		if (shift == null) {
			return now.toLocalDate();
		}
		LocalTime login = shift.getExpectedLoginTime();
		LocalTime logout = shift.getExpectedLogoutTime();
		boolean night = login.isAfter(logout);
		if (night && now.toLocalTime().isBefore(logout)) {
			return now.toLocalDate().minusDays(1);
		}
		return now.toLocalDate();
	}

	private boolean isPostMidnightNightShift(OfficeShift shift, LocalDateTime now) {
		if (shift == null) {
			return false;
		}
		LocalTime login = shift.getExpectedLoginTime();
		LocalTime logout = shift.getExpectedLogoutTime();
		if (!login.isAfter(logout)) {
			return false;
		}
		return now.toLocalTime().isBefore(logout);
	}

	// ════════════════════════════════════════════════════════════════════════
	// JSON BUILDERS
	// ════════════════════════════════════════════════════════════════════════

	/**
	 * "No active session" payload for todaySession response.
	 *
	 * Fields: status = "none" attendanceStatus = "no_checkin" (grey badge, not red
	 * Absent) prevAutoClose = true if last session was auto-closed by system
	 * prevOpenSession = JSON object if stale open session from yesterday exists,
	 * else null shift = shift config for client-side threshold seeding
	 */
	private String buildNoSessionJson(OfficeShift shift, boolean prevAutoClose, String prevOpenSessionJson) {
		String shiftJson = shift != null ? shiftToJson(shift) : "null";
		return "{\"status\":\"none\"" + ",\"attendanceStatus\":\"no_checkin\"" + ",\"attendanceLabel\":\"No Check-In\""
				+ ",\"attendanceCss\":\"absent\"" + ",\"breakCount\":0" + ",\"prevAutoClose\":" + prevAutoClose
				+ ",\"prevOpenSession\":" + prevOpenSessionJson + ",\"shift\":" + shiftJson + "}";
	}

	/** Backward-compatible overload for internal use. */
	private String buildNoSessionJson(OfficeShift shift, boolean prevAutoClose) {
		return buildNoSessionJson(shift, prevAutoClose, "null");
	}

	private String shiftToJson(OfficeShift s) {
		return "{\"id\":" + s.getId() + ",\"shiftName\":\"" + esc(s.getShiftName()) + "\"" + ",\"loginTime\":\""
				+ s.getExpectedLoginTime().format(ISO_TIME) + "\"" + ",\"logoutTime\":\""
				+ s.getExpectedLogoutTime().format(ISO_TIME) + "\"" + ",\"graceMinutes\":" + s.getLateGraceMinutes()
				+ ",\"earlyGraceMinutes\":" + AttendanceDAO.EARLY_GRACE_MINUTES + ",\"shiftDurationMs\":"
				+ AttendanceDAO.computeShiftDurationMs(s) + "}";
	}

	private String shiftsToJson(List<OfficeShift> shifts) {
		StringBuilder sb = new StringBuilder("[");
		for (int i = 0; i < shifts.size(); i++) {
			if (i > 0) {
				sb.append(",");
			}
			sb.append(shiftToJson(shifts.get(i)));
		}
		return sb.append("]").toString();
	}

	private String notificationsToJson(List<com.util.AdminNotification> list) {
		StringBuilder sb = new StringBuilder("{\"count\":").append(list.size()).append(",\"items\":[");
		for (int i = 0; i < list.size(); i++) {
			com.util.AdminNotification n = list.get(i);
			if (i > 0) {
				sb.append(",");
			}
			sb.append("{\"id\":").append(n.getId()).append(",\"type\":\"").append(esc(n.getEventType())).append("\"")
					.append(",\"title\":\"").append(esc(n.getTitle())).append("\"").append(",\"message\":\"")
					.append(esc(n.getMessage())).append("\"").append(",\"relatedEntity\":\"")
					.append(esc(n.getRelatedEntity())).append("\"").append(",\"createdAt\":\"")
					.append(n.getCreatedAt() != null ? n.getCreatedAt().toLocalDateTime().format(DT_FMT) : "")
					.append("\"}");
		}
		return sb.append("]}").toString();
	}

	private String staffListToJson() throws SQLException {
		StringBuilder sb = new StringBuilder("[");
		String sql = "SELECT u.id, u.username, u.department, u.shift_id, s.shift_name "
				+ "FROM users u LEFT JOIN office_shifts s ON s.id = u.shift_id "
				+ "WHERE u.role='staff' AND u.status='active' ORDER BY u.username";
		boolean first = true;
		try (Connection con = DBConnection.getConnection();
				PreparedStatement ps = con.prepareStatement(sql);
				ResultSet rs = ps.executeQuery()) {
			while (rs.next()) {
				if (!first) {
					sb.append(",");
				}
				first = false;
				sb.append("{\"username\":\"").append(esc(rs.getString("username"))).append("\"")
						.append(",\"department\":\"").append(esc(rs.getString("department"))).append("\"")
						.append(",\"shiftId\":")
						.append(rs.getObject("shift_id") != null ? rs.getInt("shift_id") : "null")
						.append(",\"shiftName\":\"").append(esc(rs.getString("shift_name"))).append("\"}");
			}
		}
		return sb.append("]").toString();
	}

	private String sessionToJson(AttendanceSession s) {
		StringBuilder sb = new StringBuilder("{");
		sb.append("\"status\":\"").append(esc(s.getStatus())).append("\"");
		sb.append(",\"sessionId\":").append(s.getId());
		sb.append(",\"punchInTime\":").append(toEpochMs(s.getPunchIn()));
		sb.append(",\"punchInStr\":\"").append(s.getPunchIn().format(TIME_FMT)).append("\"");

		if (s.getPunchOut() != null) {
			sb.append(",\"punchOutTime\":").append(toEpochMs(s.getPunchOut()));
			sb.append(",\"punchOutStr\":\"").append(s.getPunchOut().format(TIME_FMT)).append("\"");
		} else {
			sb.append(",\"punchOutTime\":0,\"punchOutStr\":null");
		}

		sb.append(",\"totalBreakMs\":").append(s.getTotalBreakMs());
		sb.append(",\"netWorkMs\":").append(s.getNetWorkMs());

		String attStatus = s.getAttendanceStatus();
		sb.append(",\"attendanceStatus\":\"").append(esc(attStatus)).append("\"");
		sb.append(",\"attendanceLabel\":\"").append(esc(getLabel(attStatus))).append("\"");
		sb.append(",\"attendanceCss\":\"").append(esc(getCss(attStatus))).append("\"");

		// BUG FIX: was checking "AUTO_CLOSE" uppercase — now case-insensitive
		boolean isAutoClose = "auto_close".equalsIgnoreCase(s.getStatus()) || "auto_close".equalsIgnoreCase(attStatus);
		sb.append(",\"prevAutoClose\":").append(isAutoClose);
		sb.append(",\"isAutoClose\":").append(isAutoClose);

		// v6: emit workQualityStatus so userDashboard can show "Auto-Closed (Half Day)"
		String sessionWqs = attStatus;
		if ("auto_close".equalsIgnoreCase(sessionWqs) || sessionWqs == null) {
			if (s.getShiftId() > 0) {
				try {
					com.util.OfficeShift sessShift = dao.getShiftById(s.getShiftId());
					if (sessShift != null) {
						long sessShiftMs = AttendanceDAO.computeShiftDurationMs(sessShift);
						boolean sessLate = dao.isLatePunchIn(s.getPunchIn(), sessShift);
						sessionWqs = AttendanceStatusUtil.compute(s.getPunchIn(), s.getPunchOut(), s.getNetWorkMs(),
								sessShiftMs, sessLate);
					}
				} catch (Exception ignored) {
				}
			}
			if ("auto_close".equalsIgnoreCase(sessionWqs) || sessionWqs == null) {
				sessionWqs = AttendanceStatusUtil.compute(s.getPunchIn(), s.getPunchOut(), s.getNetWorkMs(), 0L, null);
			}
		}
		sb.append(",\"workQualityStatus\":\"").append(esc(sessionWqs)).append("\"");
		sb.append(",\"workQualityLabel\":\"").append(esc(getLabel(sessionWqs))).append("\"");

		sb.append(",\"breakCount\":").append(s.getLogEntries() == null ? 0
				: s.getLogEntries().stream().filter(e -> "BREAK_START".equals(e.getEventType())).count());

		if (s.getShiftId() > 0) {
			sb.append(",\"shiftId\":").append(s.getShiftId());
		}

		List<AttendanceLogEntry> log = s.getLogEntries();
		sb.append(",\"log\":[");
		if (log != null) {
			for (int i = 0; i < log.size(); i++) {
				AttendanceLogEntry e = log.get(i);
				if (i > 0) {
					sb.append(",");
				}
				sb.append("{\"event\":\"").append(esc(e.getEventLabel())).append("\"");
				sb.append(",\"dotClass\":\"").append(esc(e.getDotClass())).append("\"");
				sb.append(",\"timeStr\":\"").append(e.getEventTime().format(TIME_FMT)).append("\"");
				if (e.getBreakDurationMs() != null) {
					sb.append(",\"breakDurationMs\":").append(e.getBreakDurationMs());
					sb.append(",\"extraHtml\":\"<div class=\\\"att-tl-dur\\\">Break lasted ")
							.append(fmtMsShort(e.getBreakDurationMs())).append("</div>\"");
				}
				sb.append("}");
			}
		}
		sb.append("]}");
		return sb.toString();
	}

	private String historyToJson(List<AttendanceSession> list) {
		StringBuilder sb = new StringBuilder("[");
		for (int i = 0; i < list.size(); i++) {
			AttendanceSession s = list.get(i);
			if (i > 0) {
				sb.append(",");
			}
			sb.append("{\"sessionDate\":\"").append(s.getSessionDate().format(DATE_FMT)).append("\"");
			sb.append(",\"status\":\"").append(esc(s.getStatus())).append("\"");
			sb.append(",\"attendanceStatus\":\"").append(esc(s.getAttendanceStatus())).append("\"");
			sb.append(",\"attendanceLabel\":\"").append(esc(getLabel(s.getAttendanceStatus()))).append("\"");
			sb.append(",\"attendanceCss\":\"").append(esc(getCss(s.getAttendanceStatus()))).append("\"");
			sb.append(",\"punchInStr\":\"").append(s.getPunchIn().format(TIME_FMT)).append("\"");
			sb.append(",\"punchOutStr\":");
			if (s.getPunchOut() != null) {
				sb.append("\"").append(s.getPunchOut().format(TIME_FMT)).append("\"");
			} else {
				sb.append("null");
			}
			sb.append(",\"punchInTime\":").append(toEpochMs(s.getPunchIn()));
			sb.append(",\"punchOutTime\":").append(s.getPunchOut() != null ? toEpochMs(s.getPunchOut()) : 0);
			sb.append(",\"totalBreakMs\":").append(s.getTotalBreakMs());
			sb.append(",\"netWorkMs\":").append(s.getNetWorkMs());
			sb.append(",\"netHours\":").append(String.format("%.2f", s.getNetWorkMs() / 3_600_000.0));
			// Emit isAutoClose + workQualityStatus so UI can render "Auto-Closed (Half
			// Day)" etc.
			boolean histIsAutoClose = "auto_close".equalsIgnoreCase(s.getStatus())
					|| "auto_close".equalsIgnoreCase(s.getAttendanceStatus());
			sb.append(",\"isAutoClose\":").append(histIsAutoClose);
			// workQualityStatus = the real payroll quality
			// (full_day/half_day/absent/late/etc.)
			// For new rows (v6) attendanceStatus already holds this; for old rows it's
			// 'auto_close'
			// so we compute it from net_work_ms
			String wqs = s.getAttendanceStatus();
			if ("auto_close".equalsIgnoreCase(wqs) || wqs == null) {
				// Old row: compute from hours
				if (s.getShiftId() > 0) {
					try {
						com.util.OfficeShift wqShift = dao.getShiftById(s.getShiftId());
						if (wqShift != null) {
							long wqShiftMs = AttendanceDAO.computeShiftDurationMs(wqShift);
							boolean wqLate = dao.isLatePunchIn(s.getPunchIn(), wqShift);
							wqs = AttendanceStatusUtil.compute(s.getPunchIn(), s.getPunchOut(), s.getNetWorkMs(),
									wqShiftMs, wqLate);
						}
					} catch (Exception ignored) {
					}
				}
				if ("auto_close".equalsIgnoreCase(wqs) || wqs == null) {
					wqs = AttendanceStatusUtil.compute(s.getPunchIn(), s.getPunchOut(), s.getNetWorkMs(), 0L, null);
				}
			}
			sb.append(",\"workQualityStatus\":\"").append(esc(wqs)).append("\"");
			sb.append(",\"workQualityLabel\":\"").append(esc(getLabel(wqs))).append("\"");
			sb.append("}");
		}
		return sb.append("]").toString();
	}

	private String allStaffToJson(List<AttendanceSession> sessions, List<String> allStaff) {
		java.util.Set<String> present = new java.util.HashSet<>();
		StringBuilder sb = new StringBuilder("[");
		boolean first = true;

		for (AttendanceSession s : sessions) {
			present.add(s.getUsername());
			if (!first) {
				sb.append(",");
			}
			first = false;

			long breakStartMs = 0;
			if ("onBreak".equals(s.getStatus()) && s.getLogEntries() != null) {
				for (AttendanceLogEntry e : s.getLogEntries()) {
					if ("BREAK_START".equals(e.getEventType())) {
						breakStartMs = toEpochMs(e.getEventTime());
					}
				}
			}

			sb.append("{\"username\":\"").append(esc(s.getUsername())).append("\"");
			sb.append(",\"status\":\"").append(esc(s.getStatus())).append("\"");
			sb.append(",\"attendanceStatus\":\"").append(esc(s.getAttendanceStatus())).append("\"");
			sb.append(",\"attendanceLabel\":\"").append(esc(getLabel(s.getAttendanceStatus()))).append("\"");
			sb.append(",\"attendanceCss\":\"").append(esc(getCss(s.getAttendanceStatus()))).append("\"");
			sb.append(",\"punchInTime\":").append(toEpochMs(s.getPunchIn()));
			sb.append(",\"punchOutTime\":").append(s.getPunchOut() != null ? toEpochMs(s.getPunchOut()) : 0);
			sb.append(",\"totalBreakMs\":").append(s.getTotalBreakMs());
			sb.append(",\"netWorkMs\":").append(s.getNetWorkMs());
			// Emit isAutoClose + workQualityStatus for admin dashboard "Auto-Closed (Half
			// Day)" display
			boolean staffIsAutoClose = "auto_close".equalsIgnoreCase(s.getStatus())
					|| "auto_close".equalsIgnoreCase(s.getAttendanceStatus());
			sb.append(",\"isAutoClose\":").append(staffIsAutoClose);
			String staffWqs = s.getAttendanceStatus();
			if ("auto_close".equalsIgnoreCase(staffWqs) || staffWqs == null) {
				if (s.getShiftId() > 0) {
					try {
						com.util.OfficeShift staffShift = dao.getShiftById(s.getShiftId());
						if (staffShift != null) {
							long staffShiftMs = AttendanceDAO.computeShiftDurationMs(staffShift);
							boolean staffLate = dao.isLatePunchIn(s.getPunchIn(), staffShift);
							staffWqs = AttendanceStatusUtil.compute(s.getPunchIn(), s.getPunchOut(), s.getNetWorkMs(),
									staffShiftMs, staffLate);
						}
					} catch (Exception ignored) {
					}
				}
				if ("auto_close".equalsIgnoreCase(staffWqs) || staffWqs == null) {
					staffWqs = AttendanceStatusUtil.compute(s.getPunchIn(), s.getPunchOut(), s.getNetWorkMs(), 0L,
							null);
				}
			}
			sb.append(",\"workQualityStatus\":\"").append(esc(staffWqs)).append("\"");
			sb.append(",\"workQualityLabel\":\"").append(esc(getLabel(staffWqs))).append("\"");
			if (breakStartMs > 0) {
				sb.append(",\"breakStart\":").append(breakStartMs);
			}

			// ── FIX: include shiftId + inline shift details per row ──────────────
			// JS _getShiftEndMs() needs shiftId + _cachedShiftMs populated.
			// Without these, the admin live clock never knows when to freeze.
			// We embed the full shift details inline so the JS has everything on
			// first render without a separate async fetch to action=shifts.
			if (s.getShiftId() > 0) {
				sb.append(",\"shiftId\":").append(s.getShiftId());
				try {
					OfficeShift shift = dao.getShiftById(s.getShiftId());
					if (shift != null) {
						sb.append(",\"shiftDetails\":{").append("\"id\":").append(shift.getId())
								.append(",\"shiftName\":\"").append(esc(shift.getShiftName())).append("\"")
								.append(",\"loginTime\":\"")
								.append(shift.getExpectedLoginTime()
										.format(java.time.format.DateTimeFormatter.ofPattern("HH:mm")))
								.append("\"").append(",\"logoutTime\":\"")
								.append(shift.getExpectedLogoutTime()
										.format(java.time.format.DateTimeFormatter.ofPattern("HH:mm")))
								.append("\"").append(",\"graceMinutes\":").append(shift.getLateGraceMinutes())
								.append(",\"shiftDurationMs\":").append(AttendanceDAO.computeShiftDurationMs(shift))
								.append("}");
					}
				} catch (java.sql.SQLException ignored) {
				}
			}
			// ─────────────────────────────────────────────────────────────────────

			sb.append(",\"log\":[");
			List<AttendanceLogEntry> log = s.getLogEntries();
			if (log != null) {
				for (int j = 0; j < log.size(); j++) {
					AttendanceLogEntry e = log.get(j);
					if (j > 0) {
						sb.append(",");
					}
					sb.append("{\"event\":\"").append(esc(e.getEventLabel())).append("\"");
					sb.append(",\"dotClass\":\"").append(esc(e.getDotClass())).append("\"");
					sb.append(",\"timeStr\":\"").append(e.getEventTime().format(TIME_FMT)).append("\"");
					if (e.getBreakDurationMs() != null) {
						sb.append(",\"extraHtml\":\"<div style=\\\"font-size:.68rem;color:#3b82f6\\\">Break: ")
								.append(fmtMsShort(e.getBreakDurationMs())).append("</div>\"");
					}
					sb.append("}");
				}
			}
			sb.append("]}");
		}

		// Absent staff — no session today
		for (String staffName : allStaff) {
			if (present.contains(staffName)) {
				continue;
			}
			if (!first) {
				sb.append(",");
			}
			first = false;
			sb.append("{\"username\":\"").append(esc(staffName)).append("\"").append(",\"status\":\"absent\"")
					.append(",\"attendanceStatus\":\"no_checkin\"").append(",\"attendanceLabel\":\"No Check-In\"")
					.append(",\"attendanceCss\":\"absent\"")
					.append(",\"punchInTime\":0,\"punchOutTime\":0,\"totalBreakMs\":0,\"netWorkMs\":0,\"log\":[]}");
		}

		return sb.append("]").toString();
	}

	// ════════════════════════════════════════════════════════════════════════
	// LABEL / CSS HELPERS — delegates to AttendanceStatusUtil (single source)
	// ════════════════════════════════════════════════════════════════════════

	/**
	 * Human-readable attendance label.
	 *
	 * BUG FIX v5: was a local switch that missed "full_day", "half_day",
	 * "late_half", "overtime", "late_overtime" — they all fell through to "In
	 * Progress". Now delegates to AttendanceStatusUtil.label().
	 */
	private String getLabel(String status) {
		if (status == null) {
			return "In Progress";
		}
		// Special non-standard values not in AttendanceStatusUtil
		if ("no_checkin".equalsIgnoreCase(status)) {
			return "No Check-In";
		}
		return AttendanceStatusUtil.label(status);
	}

	/**
	 * CSS class for status pill.
	 *
	 * BUG FIX v5: was a local switch missing unified statuses. Now delegates to
	 * AttendanceStatusUtil.cssClass().
	 */
	private String getCss(String status) {
		if (status == null) {
			return "pending";
		}
		if ("no_checkin".equalsIgnoreCase(status)) {
			return "absent";
		}
		return AttendanceStatusUtil.cssClass(status);
	}

	// ════════════════════════════════════════════════════════════════════════
	// HELPERS
	// ════════════════════════════════════════════════════════════════════════

	private List<String> getAllStaffUsernames() {
		List<String> list = new java.util.ArrayList<>();
		String sql = "SELECT username FROM users WHERE role='staff' AND status='active' ORDER BY username";
		try (Connection con = DBConnection.getConnection();
				PreparedStatement ps = con.prepareStatement(sql);
				ResultSet rs = ps.executeQuery()) {
			while (rs.next()) {
				list.add(rs.getString("username"));
			}
		} catch (SQLException e) {
			e.printStackTrace();
		}
		return list;
	}

	private void setJsonHeaders(HttpServletResponse resp) {
		resp.setContentType("application/json;charset=UTF-8");
		resp.setHeader("Cache-Control", "no-store");
	}

	private String getUsername(HttpServletRequest req) {
		HttpSession hs = req.getSession(false);
		return (hs == null) ? null : (String) hs.getAttribute("username");
	}

	private boolean isAdmin(HttpServletRequest req) {
		HttpSession hs = req.getSession(false);
		return hs != null && "admin".equalsIgnoreCase((String) hs.getAttribute("role"));
	}

	private boolean requireAdmin(HttpServletRequest req, HttpServletResponse resp) throws IOException {
		if (!isAdmin(req)) {
			sendError(resp, 403, "Admin access required.");
			return false;
		}
		return true;
	}

	private void sendError(HttpServletResponse resp, int code, String msg) throws IOException {
		resp.setStatus(code);
		resp.getWriter().print("{\"ok\":false,\"error\":\"" + esc(msg) + "\"}");
	}

	private long parseLongParam(HttpServletRequest req, String name) {
		try {
			return Long.parseLong(req.getParameter(name));
		} catch (Exception e) {
			return -1;
		}
	}

	private int parseIntOrDefault(String val, int def) {
		try {
			return Integer.parseInt(val);
		} catch (Exception e) {
			return def;
		}
	}

	private String nvl(String s) {
		return s != null ? s : "";
	}

	private long toEpochMs(LocalDateTime ldt) {
		if (ldt == null) {
			return 0;
		}
		return ldt.atZone(java.time.ZoneId.systemDefault()).toInstant().toEpochMilli();
	}

	private String fmtMsShort(long ms) {
		if (ms < 0) {
			ms = 0;
		}
		long s = ms / 1000, h = s / 3600, m = (s % 3600) / 60;
		return (h > 0) ? h + "h " + m + "m" : m + "m";
	}

	private String esc(String s) {
		if (s == null) {
			return "";
		}
		return s.replace("\\", "\\\\").replace("\"", "\\\"").replace("\n", "\\n").replace("\r", "");
	}

	/**
	 * Builds a plain-English HTML email notifying a staff member that their shift
	 * timings have been changed by an admin.
	 */
	private String buildShiftChangeEmail(String username, OfficeShift oldShift, OfficeShift newShift,
			java.time.format.DateTimeFormatter timeFmt) {

		String oldStart = oldShift.getExpectedLoginTime() != null ? oldShift.getExpectedLoginTime().format(timeFmt)
				: "\u2014";
		String oldEnd = oldShift.getExpectedLogoutTime() != null ? oldShift.getExpectedLogoutTime().format(timeFmt)
				: "\u2014";
		String newStart = newShift.getExpectedLoginTime() != null ? newShift.getExpectedLoginTime().format(timeFmt)
				: "\u2014";
		String newEnd = newShift.getExpectedLogoutTime() != null ? newShift.getExpectedLogoutTime().format(timeFmt)
				: "\u2014";
		int newGrace = newShift.getLateGraceMinutes();
		long newHours = java.time.Duration.between(newShift.getExpectedLoginTime(), newShift.getExpectedLogoutTime())
				.toHours();

		boolean nameChanged = !newShift.getShiftName().equals(oldShift.getShiftName());
		boolean startChanged = !newShift.getExpectedLoginTime().equals(oldShift.getExpectedLoginTime());
		boolean endChanged = !newShift.getExpectedLogoutTime().equals(oldShift.getExpectedLogoutTime());
		boolean graceChanged = newShift.getLateGraceMinutes() != oldShift.getLateGraceMinutes();

		// ── What-changed table ──
		String changesTable = "<p style='margin:0 0 10px;font-size:13px;font-weight:700;letter-spacing:1px;"
				+ "text-transform:uppercase;color:#0369a1;'>\uD83D\uDCCB What Changed</p>"
				+ "<table width='100%' cellpadding='0' cellspacing='0' border='0' "
				+ "style='border-collapse:collapse;margin-bottom:20px;border:1px solid #dbeafe;border-radius:10px;overflow:hidden;'>"
				+ "<tr style='background:#eff6ff;'>"
				+ "<th style='padding:9px 12px;font-size:11px;color:#64748b;text-align:left;font-weight:700;"
				+ "border-bottom:2px solid #bae6fd;'>Detail</th>"
				+ "<th style='padding:9px 12px;font-size:11px;color:#64748b;text-align:left;font-weight:700;"
				+ "border-bottom:2px solid #bae6fd;'>Before</th>"
				+ "<th style='padding:9px 12px;font-size:11px;color:#0369a1;text-align:left;font-weight:700;"
				+ "border-bottom:2px solid #bae6fd;'>Now</th>" + "</tr>"
				+ changeRow("Shift Name", htmlEsc(oldShift.getShiftName()), htmlEsc(newShift.getShiftName()),
						nameChanged)
				+ changeRow("Start Time", oldStart, newStart, startChanged)
				+ changeRow("End Time", oldEnd, newEnd, endChanged)
				+ changeRow("Late Allowance", oldShift.getLateGraceMinutes() + " min", newGrace + " min", graceChanged)
				+ "</table>";

		return emailShell(username, "\uD83D\uDD50", "Your Work Schedule Has Been Updated",
				"Your shift timings have changed. Please check the details below and update your daily routine.",
				changesTable + shiftCard(newShift.getShiftName(), newStart, newEnd, newGrace, newHours)
						+ reminderBox("Your new schedule is effective immediately. Please make sure you "
								+ "<strong>punch in</strong> at the updated start time and "
								+ "<strong>punch out</strong> at the end of your shift. "
								+ "If you have any concerns, contact your supervisor."));
	}

	private static String changeRow(String label, String oldVal, String newVal, boolean changed) {
		String highlight = changed ? "style='color:#0369a1;font-weight:700;'" : "";
		return "<tr style='border-bottom:1px solid #f0f9ff;'>"
				+ "<td style='padding:9px 12px;font-size:12px;font-weight:700;text-transform:uppercase;color:#64748b;'>"
				+ label + "</td>" + "<td style='padding:9px 12px;font-size:14px;color:#94a3b8;text-decoration:"
				+ (changed ? "line-through" : "none") + ";'>" + oldVal + "</td>"
				+ "<td style='padding:9px 12px;font-size:14px;"
				+ (changed ? "color:#0369a1;font-weight:700;" : "color:#64748b;") + "'>" + newVal + "</td>" + "</tr>";
	}

	// ── Email: staff assigned to a brand-new shift (or reassigned) ────────────
	private String buildAssignShiftEmail(String username, OfficeShift prevShift, OfficeShift newShift) {
		java.time.format.DateTimeFormatter tf = java.time.format.DateTimeFormatter.ofPattern("hh:mm a");
		String newStart = newShift.getExpectedLoginTime() != null ? newShift.getExpectedLoginTime().format(tf)
				: "\u2014";
		String newEnd = newShift.getExpectedLogoutTime() != null ? newShift.getExpectedLogoutTime().format(tf)
				: "\u2014";
		int grace = newShift.getLateGraceMinutes();
		long hours = java.time.Duration.between(newShift.getExpectedLoginTime(), newShift.getExpectedLogoutTime())
				.toHours();

		String prevNote = (prevShift != null)
				? "<p style='margin:0 0 20px;font-size:13px;color:#64748b;background:#f8fafc;"
						+ "border:1px solid #e2e8f0;border-radius:8px;padding:10px 14px;'>"
						+ "\uD83D\uDCC4 You were previously on the <strong>" + htmlEsc(prevShift.getShiftName())
						+ "</strong> shift (" + prevShift.getExpectedLoginTime().format(tf) + " \u2013 "
						+ prevShift.getExpectedLogoutTime().format(tf) + "). "
						+ "That assignment has been replaced with the one below.</p>"
				: "";

		return emailShell(username, "\uD83D\uDCC5", "You Have a New Work Shift",
				"Your manager has assigned you to a shift. Your working hours are shown below \u2014 "
						+ "please read them carefully and plan your day accordingly.",
				prevNote + shiftCard(newShift.getShiftName(), newStart, newEnd, grace, hours)
						+ reminderBox("Make sure you log in to the portal and <strong>punch in</strong> when you "
								+ "arrive, and <strong>punch out</strong> before you leave. " + "You have <strong>"
								+ grace + " minutes</strong> after " + newStart + " before you are marked late."));
	}

	// ── Shared email shell ─────────────────────────────────────────────────────
	private static String emailShell(String username, String emoji, String headline, String subHeadline,
			String bodyContent) {
		return "<!DOCTYPE html><html lang='en'><head><meta charset='UTF-8'>"
				+ "<meta name='viewport' content='width=device-width,initial-scale=1'>" + "<style>"
				+ "body{margin:0;padding:0;background:#f0f4f8;font-family:Arial,Helvetica,sans-serif;}"
				+ "@media(max-width:600px){" + ".ew{width:100%!important;border-radius:0!important;}"
				+ ".ep{padding:20px!important;}" + ".eh{padding:28px 20px!important;}"
				+ ".ef{padding:14px 20px!important;}"
				+ ".sc td{display:block;width:100%!important;text-align:left!important;padding:6px 0!important;}" + "}"
				+ "</style></head>" + "<body style='margin:0;padding:24px 0;background:#f0f4f8;'>"
				+ "<table width='100%' cellpadding='0' cellspacing='0' border='0'>" + "<tr><td align='center'>"
				+ "<table class='ew' width='600' cellpadding='0' cellspacing='0' border='0' "
				+ "style='border-radius:16px;overflow:hidden;box-shadow:0 8px 40px rgba(0,0,0,.12);border:1px solid #dbeafe;'>"

				// ── Header ──
				+ "<tr><td class='eh' style='background:linear-gradient(135deg,#1e40af,#0ea5e9);"
				+ "padding:36px 40px;text-align:center;'>" + "<div style='font-size:40px;margin-bottom:12px;'>" + emoji
				+ "</div>"
				+ "<h1 style='margin:0 0 8px;color:#fff;font-size:22px;font-weight:800;letter-spacing:-0.3px;'>"
				+ htmlEsc(headline) + "</h1>"
				+ "<p style='margin:0;color:rgba(255,255,255,.85);font-size:14px;line-height:1.5;'>"
				+ htmlEsc(subHeadline) + "</p>" + "</td></tr>"

				// ── Body ──
				+ "<tr><td class='ep' style='background:#fff;padding:36px 40px;'>"
				+ "<p style='margin:0 0 24px;font-size:16px;color:#0f172a;font-weight:600;'>" + "Hi "
				+ htmlEsc(username) + ",</p>" + bodyContent
				+ "<p style='margin:28px 0 0;font-size:13px;color:#94a3b8;'>"
				+ "If you did not expect this email or have questions, please speak to your supervisor "
				+ "or contact HR at <a href='mailto:hr@sibs.in' style='color:#0ea5e9;'>hr@sibs.in</a>.</p>"
				+ "</td></tr>"

				// ── Footer ──
				+ "<tr><td class='ef' style='background:#1e3a5f;padding:18px 40px;text-align:center;'>"
				+ "<p style='margin:0;color:rgba(255,255,255,.7);font-size:12px;line-height:1.6;'>"
				+ "This email was sent automatically by the SIBS system. Please do not reply to this email.<br>"
				+ "Need help? Contact HR at <a href='mailto:hr@sibs.in' " + "style='color:#7dd3fc;'>hr@sibs.in</a>.</p>"
				+ "<p style='margin:8px 0 0;color:rgba(255,255,255,.35);font-size:11px;'>"
				+ "\u00A9 2026 SIBS Organisation. All rights reserved.</p>" + "</td></tr>"

				+ "</table></td></tr></table></body></html>";
	}

	// ── Shared: shift info card ────────────────────────────────────────────────
	private static String shiftCard(String name, String start, String end, int grace, long hrs) {
		return "<div style='background:#f0f9ff;border:1px solid #bae6fd;border-radius:12px;"
				+ "padding:20px 24px;margin-bottom:20px;'>"
				+ "<p style='margin:0 0 14px;font-size:13px;font-weight:700;letter-spacing:1px;"
				+ "text-transform:uppercase;color:#0369a1;'>\uD83D\uDD52 Your Shift Details</p>"
				+ "<table class='sc' width='100%' cellpadding='0' cellspacing='0' border='0'>"
				+ scRow("Shift Name", "<strong>" + htmlEsc(name) + "</strong>")
				+ scRow("Start Time", "\uD83D\uDFE2 <strong>" + start + "</strong>")
				+ scRow("End Time", "\uD83D\uDD34 <strong>" + end + "</strong>")
				+ scRow("Total Hours", hrs + " hours per working day") + scRow("Late Grace", "You have <strong>" + grace
						+ " minutes</strong> after " + start + " to arrive before being marked late")
				+ "</table></div>";
	}

	private static String scRow(String label, String value) {
		return "<tr>" + "<td style='padding:7px 12px 7px 0;font-size:12px;font-weight:700;color:#64748b;"
				+ "text-transform:uppercase;white-space:nowrap;width:130px;vertical-align:top;'>" + label + "</td>"
				+ "<td style='padding:7px 0;font-size:14px;color:#0f172a;'>" + value + "</td>" + "</tr>";
	}

	// ── Shared: amber reminder box ─────────────────────────────────────────────
	private static String reminderBox(String msg) {
		return "<div style='background:#fffbeb;border-left:4px solid #f59e0b;border-radius:0 8px 8px 0;"
				+ "padding:14px 18px;margin-bottom:20px;font-size:13px;color:#78350f;line-height:1.7;'>"
				+ "<strong>\u26A0\uFE0F Reminder: </strong>" + msg + "</div>";
	}

	private static String htmlEsc(String s) {
		if (s == null) {
			return "";
		}
		return s.replace("&", "&amp;").replace("<", "&lt;").replace(">", "&gt;");
	}
}