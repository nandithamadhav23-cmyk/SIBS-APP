package com.servlet;

import java.io.IOException;
import java.io.PrintWriter;
import java.sql.*;
import java.util.*;

import com.DAO.LeaveDAO;
import com.util.DBConnection;
import com.util.LeaveRequest;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.*;

/**
 * AdminLeaveServlet — all admin-side leave management endpoints.
 *
 * GET  ?action=pending          → JSON list of pending leave requests
 * GET  ?action=all              → JSON list of all requests (with filters)
 * GET  ?action=stats            → JSON KPI counters
 * GET  ?action=calendar&month=  → JSON approved leaves for calendar view
 * GET  ?action=staffBalance&username= → JSON per-user balance summary
 *
 * POST ?action=approve          → approve a request  (body: requestId, note)
 * POST ?action=reject           → reject a request   (body: requestId, note)
 * POST ?action=revoke           → revoke approved    (body: requestId, note)
 * POST ?action=bulkApprove      → approve many       (body: ids=1,2,3)
 * POST ?action=bulkReject       → reject many        (body: ids=1,2,3, note)
 *
 * All responses are JSON.  Servlet is admin-only (role check in doGet/doPost).
 */
@WebServlet("/AdminLeaveServlet")
public class AdminLeaveServlet extends HttpServlet {

    private final LeaveDAO leaveDAO = new LeaveDAO();

    // ══════════════════════════════════════════════════════════
    //  GET
    // ══════════════════════════════════════════════════════════
    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse res)
            throws ServletException, IOException {

        res.setContentType("application/json;charset=UTF-8");
        PrintWriter out = res.getWriter();

        if (!isAdmin(req)) { out.print("{\"error\":\"Access denied\"}"); return; }

        String action = req.getParameter("action");
        if (action == null) action = "pending";

        try {
            switch (action) {

                case "pending" -> {
                    List<LeaveRequest> list = leaveDAO.getPendingRequests();
                    out.print(toJsonArray(list));
                }

                case "all" -> {
                    String status     = req.getParameter("status");      // optional filter
                    String username   = req.getParameter("username");    // optional filter
                    String leaveType  = req.getParameter("leaveType");   // optional filter
                    String fromDate   = req.getParameter("from");
                    String toDate     = req.getParameter("to");
                    List<LeaveRequest> list = leaveDAO.getFilteredRequests(status, username, leaveType, fromDate, toDate);
                    out.print(toJsonArray(list));
                }

                case "stats" -> {
                    out.print(buildStats());
                }

                case "calendar" -> {
                    String month = req.getParameter("month"); // YYYY-MM
                    out.print(buildCalendar(month));
                }

                case "staffBalance" -> {
                    String uname = req.getParameter("username");
                    if (uname == null || uname.isBlank()) {
                        out.print("{\"error\":\"username required\"}");
                    } else {
                        out.print(buildStaffBalance(uname));
                    }
                }

                default -> out.print("{\"error\":\"Unknown action\"}");
            }
        } catch (Exception e) {
            res.setStatus(500);
            out.print("{\"error\":" + jsonStr(e.getMessage()) + "}");
        }
    }

    // ══════════════════════════════════════════════════════════
    //  POST
    // ══════════════════════════════════════════════════════════
    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse res)
            throws ServletException, IOException {

        res.setContentType("application/json;charset=UTF-8");
        PrintWriter out = res.getWriter();

        if (!isAdmin(req)) { out.print("{\"ok\":false,\"error\":\"Access denied\"}"); return; }

        String action = req.getParameter("action");
        String reviewer = (String) req.getSession().getAttribute("username");

        try {
            switch (action != null ? action : "") {

                case "approve" -> {
                    int id    = Integer.parseInt(req.getParameter("requestId"));
                    String note = nullSafe(req.getParameter("note"));
                    String err  = leaveDAO.approveLeave(id, reviewer, note);
                    out.print(err == null ? "{\"ok\":true}" : "{\"ok\":false,\"error\":" + jsonStr(err) + "}");
                }

                case "reject" -> {
                    int id    = Integer.parseInt(req.getParameter("requestId"));
                    String note = nullSafe(req.getParameter("note"));
                    if (note.isBlank()) {
                        out.print("{\"ok\":false,\"error\":\"Rejection reason is required.\"}");
                        return;
                    }
                    String err = leaveDAO.rejectLeave(id, reviewer, note);
                    out.print(err == null ? "{\"ok\":true}" : "{\"ok\":false,\"error\":" + jsonStr(err) + "}");
                }

                case "revoke" -> {
                    int id    = Integer.parseInt(req.getParameter("requestId"));
                    String note = nullSafe(req.getParameter("note"));
                    String err  = revokeLeave(id, reviewer, note);
                    out.print(err == null ? "{\"ok\":true}" : "{\"ok\":false,\"error\":" + jsonStr(err) + "}");
                }

                case "bulkApprove" -> {
                    String[] ids = req.getParameter("ids").split(",");
                    int ok = 0, fail = 0;
                    for (String sid : ids) {
                        try {
                            String err = leaveDAO.approveLeave(Integer.parseInt(sid.trim()), reviewer, "Bulk approved by admin");
                            if (err == null) ok++; else fail++;
                        } catch (Exception ignored) { fail++; }
                    }
                    out.print("{\"ok\":true,\"approved\":" + ok + ",\"failed\":" + fail + "}");
                }

                case "bulkReject" -> {
                    String[] ids  = req.getParameter("ids").split(",");
                    String note   = nullSafe(req.getParameter("note"));
                    if (note.isBlank()) note = "Bulk rejected by admin";
                    int ok = 0, fail = 0;
                    for (String sid : ids) {
                        try {
                            String err = leaveDAO.rejectLeave(Integer.parseInt(sid.trim()), reviewer, note);
                            if (err == null) ok++; else fail++;
                        } catch (Exception ignored) { fail++; }
                    }
                    out.print("{\"ok\":true,\"rejected\":" + ok + ",\"failed\":" + fail + "}");
                }

                default -> out.print("{\"ok\":false,\"error\":\"Unknown action\"}");
            }
        } catch (NumberFormatException e) {
            out.print("{\"ok\":false,\"error\":\"Invalid request ID\"}");
        } catch (Exception e) {
            res.setStatus(500);
            out.print("{\"ok\":false,\"error\":" + jsonStr(e.getMessage()) + "}");
        }
    }

    // ══════════════════════════════════════════════════════════
    //  HELPERS
    // ══════════════════════════════════════════════════════════

    /** Revoke an already-approved leave (admin-only action). */
    private String revokeLeave(int id, String reviewer, String note) throws SQLException {
        String sql = """
            UPDATE leave_requests
            SET status='revoked', reviewed_by=?, reviewed_on=NOW(), reviewer_note=?
            WHERE id=? AND status='approved'
            """;
        try (Connection con = DBConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(sql)) {
            ps.setString(1, reviewer);
            ps.setString(2, note);
            ps.setInt(3, id);
            int rows = ps.executeUpdate();
            if (rows == 0) return "Cannot revoke: request not found or not in approved state.";
        }
        // Refund the balance
        LeaveRequest req = leaveDAO.getRequestById(id);
        if (req != null) {
            // Re-use the DAO's deductBalance via a public wrapper if available,
            // else do it inline:
            String refund = """
                UPDATE leave_balances
                SET used_days = GREATEST(0, used_days - ?)
                WHERE username=? AND leave_type_id=? AND leave_year=YEAR(CURDATE())
                """;
            try (Connection con = DBConnection.getConnection();
                 PreparedStatement ps = con.prepareStatement(refund)) {
                ps.setBigDecimal(1, req.getTotalDays());
                ps.setString(2, req.getUsername());
                ps.setInt(3, req.getLeaveTypeId());
                ps.executeUpdate();
            }
        }
        return null;
    }

    /** KPI statistics JSON. */
    private String buildStats() throws SQLException {
        String sql = """
            SELECT
              COUNT(*)                                          AS total,
              SUM(status='pending')                            AS pending,
              SUM(status='approved')                           AS approved,
              SUM(status='rejected')                           AS rejected,
              SUM(status='cancelled')                          AS cancelled,
              SUM(status='revoked')                            AS revoked,
              SUM(status='pending' AND from_date = CURDATE())  AS urgent_today,
              SUM(status='approved' AND CURDATE() BETWEEN from_date AND to_date) AS on_leave_now
            FROM leave_requests
            """;
        try (Connection con = DBConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {
            if (rs.next()) {
                return String.format(
                    "{\"total\":%d,\"pending\":%d,\"approved\":%d,\"rejected\":%d," +
                    "\"cancelled\":%d,\"revoked\":%d,\"urgentToday\":%d,\"onLeaveNow\":%d}",
                    rs.getLong("total"), rs.getLong("pending"), rs.getLong("approved"),
                    rs.getLong("rejected"), rs.getLong("cancelled"), rs.getLong("revoked"),
                    rs.getLong("urgent_today"), rs.getLong("on_leave_now")
                );
            }
        }
        return "{\"total\":0,\"pending\":0,\"approved\":0,\"rejected\":0,\"cancelled\":0,\"revoked\":0,\"urgentToday\":0,\"onLeaveNow\":0}";
    }

    /** Approved leaves for a given month as calendar events. */
    private String buildCalendar(String month) throws SQLException {
        if (month == null || month.isBlank()) {
            month = new java.text.SimpleDateFormat("yyyy-MM").format(new java.util.Date());
        }
        String sql = """
            SELECT lr.username, lr.from_date, lr.to_date, lt.type_name, lr.total_days
            FROM   leave_requests lr
            JOIN   leave_types lt ON lt.id = lr.leave_type_id
            WHERE  lr.status = 'approved'
              AND  DATE_FORMAT(lr.from_date,'%Y-%m') = ?
            ORDER  BY lr.from_date
            """;
        StringBuilder sb = new StringBuilder("[");
        try (Connection con = DBConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(sql)) {
            ps.setString(1, month);
            try (ResultSet rs = ps.executeQuery()) {
                boolean first = true;
                while (rs.next()) {
                    if (!first) sb.append(",");
                    sb.append(String.format(
                        "{\"username\":%s,\"from\":%s,\"to\":%s,\"type\":%s,\"days\":%s}",
                        jsonStr(rs.getString("username")),
                        jsonStr(rs.getString("from_date")),
                        jsonStr(rs.getString("to_date")),
                        jsonStr(rs.getString("type_name")),
                        rs.getBigDecimal("total_days").toPlainString()
                    ));
                    first = false;
                }
            }
        }
        return sb.append("]").toString();
    }

    /** Per-staff balance summary for all leave types. */
    private String buildStaffBalance(String username) throws SQLException {
        String sql = """
            SELECT lt.type_name, lt.max_days, lt.is_paid,
                   COALESCE(lb.total_days, lt.max_days) AS allotted,
                   COALESCE(lb.used_days, 0)            AS used,
                   COALESCE(lb.carried_days, 0)         AS carried
            FROM   leave_types lt
            LEFT   JOIN leave_balances lb
                        ON lb.leave_type_id=lt.id AND lb.username=? AND lb.leave_year=YEAR(CURDATE())
            ORDER  BY lt.id
            """;
        StringBuilder sb = new StringBuilder("[");
        try (Connection con = DBConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(sql)) {
            ps.setString(1, username);
            try (ResultSet rs = ps.executeQuery()) {
                boolean first = true;
                while (rs.next()) {
                    if (!first) sb.append(",");
                    double allotted = rs.getDouble("allotted");
                    double used     = rs.getDouble("used");
                    double carried  = rs.getDouble("carried");
                    sb.append(String.format(
                        "{\"type\":%s,\"allotted\":%.1f,\"used\":%.1f,\"carried\":%.1f,\"available\":%.1f,\"paid\":%b}",
                        jsonStr(rs.getString("type_name")),
                        allotted, used, carried, (allotted + carried - used),
                        rs.getBoolean("is_paid")
                    ));
                    first = false;
                }
            }
        }
        return sb.append("]").toString();
    }

    /** Convert a LeaveRequest list to a JSON array string. */
    private String toJsonArray(List<LeaveRequest> list) {
        StringBuilder sb = new StringBuilder("[");
        for (int i = 0; i < list.size(); i++) {
            if (i > 0) sb.append(",");
            sb.append(toJson(list.get(i)));
        }
        return sb.append("]").toString();
    }

    private String toJson(LeaveRequest r) {
        // documentPath in DB is the relative key: "leave-docs/<filename>"
        // The browser must fetch it via LeaveDocServlet:
        //   GET /LeaveDocServlet?file=leave-docs/<filename>
        // We send the raw key; the JS builds the URL.
        return String.format(
            "{\"id\":%d,\"username\":%s,\"leaveType\":%s,\"leaveTypeId\":%d," +
            "\"from\":%s,\"to\":%s,\"days\":%s,\"session\":%s," +
            "\"reason\":%s,\"contact\":%s,\"covering\":%s,\"handover\":%s," +
            "\"documentPath\":%s," +
            "\"status\":%s,\"appliedOn\":%s," +
            "\"reviewedBy\":%s,\"reviewedOn\":%s,\"reviewerNote\":%s," +
            "\"cancelReason\":%s,\"isPaid\":%b}",
            r.getId(),
            jsonStr(r.getUsername()),
            jsonStr(r.getLeaveTypeName()),
            r.getLeaveTypeId(),
            jsonStr(r.getFromDate()   != null ? r.getFromDate().toString()   : null),
            jsonStr(r.getToDate()     != null ? r.getToDate().toString()     : null),
            r.getTotalDays() != null ? r.getTotalDays().toPlainString() : "0",
            jsonStr(r.getSessionType()),
            jsonStr(r.getReason()),
            jsonStr(r.getContactDuringLeave()),
            jsonStr(r.getCoveringPerson()),
            jsonStr(r.getWorkHandover()),
            jsonStr(r.getDocumentPath()),   // "leave-docs/<file>" or null
            jsonStr(r.getStatus()),
            jsonStr(r.getAppliedOn()  != null ? r.getAppliedOn().toString()  : null),
            jsonStr(r.getReviewedBy()),
            jsonStr(r.getReviewedOn() != null ? r.getReviewedOn().toString() : null),
            jsonStr(r.getReviewerNote()),
            jsonStr(r.getCancelReason()),
            r.isPaid()
        );
    }

    private String jsonStr(String s) {
        if (s == null) return "null";
        return "\"" + s.replace("\\","\\\\").replace("\"","\\\"")
                        .replace("\n","\\n").replace("\r","") + "\"";
    }

    private String nullSafe(String s) { return s != null ? s.trim() : ""; }

    private boolean isAdmin(HttpServletRequest req) {
        HttpSession s = req.getSession(false);
        if (s == null) return false;
        String role = (String) s.getAttribute("role");
        return "admin".equalsIgnoreCase(role);
    }
}
