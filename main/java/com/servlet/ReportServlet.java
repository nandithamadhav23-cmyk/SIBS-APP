package com.servlet;

import java.io.IOException;
import java.io.PrintWriter;
import java.sql.SQLException;
import java.time.LocalDate;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

import com.DAO.ReportDAO;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;

/**
 * ReportServlet — Zero-dependency JSON API (no Gson, no org.json). Uses a
 * hand-rolled toJson() that handles Map, List, String, Number, Boolean, null.
 */
@WebServlet("/ReportServlet")
public class ReportServlet extends HttpServlet {

	private static final long serialVersionUID = 1L;
	private final ReportDAO dao = new ReportDAO();

	@Override
	protected void doGet(HttpServletRequest req, HttpServletResponse res) throws ServletException, IOException {

		HttpSession session = req.getSession(false);
		String role = (session != null) ? (String) session.getAttribute("role") : null;
		if (role == null || !("admin".equalsIgnoreCase(role) || "staff".equalsIgnoreCase(role))) {
			sendError(res, HttpServletResponse.SC_UNAUTHORIZED, "Unauthorized");
			return;
		}

		res.setContentType("application/json;charset=UTF-8");
		res.setHeader("Cache-Control", "no-cache");

		String action = req.getParameter("action");
		if (action == null) {
			action = "overview";
		}

		try (PrintWriter out = res.getWriter()) {
			switch (action) {

			case "overview":
				out.print(toJson(buildOverview()));
				break;

			case "revenue_trend":
				out.print(toJson(dao.getMonthlyRevenueTrend(intParam(req, "months", 12))));
				break;

			case "order_status":
				out.print(toJson(dao.getOrderStatusBreakdown()));
				break;

			case "attendance": {
				String from = req.getParameter("from");
				String to = req.getParameter("to");
				if (from == null) {
					from = LocalDate.now().withDayOfMonth(1).toString();
				}
				if (to == null) {
					to = LocalDate.now().toString();
				}
				Map<String, Object> p = new LinkedHashMap<>();
				p.put("summary", dao.getAttendanceSummary(from, to));
				p.put("trend", dao.getDailyAttendanceTrend(30));
				out.print(toJson(p));
				break;
			}

			case "leave": {
				Map<String, Object> p = new LinkedHashMap<>();
				p.put("summary", dao.getLeaveSummary());
				p.put("by_type", dao.getLeaveByType());
				out.print(toJson(p));
				break;
			}

			case "products": {
				int topN = intParam(req, "limit", 8);
				Map<String, Object> p = new LinkedHashMap<>();
				p.put("top_products", dao.getTopProducts(topN));
				p.put("category_revenue", dao.getRevenuByCategory());
				p.put("low_stock_count", dao.getLowStockCount(10));
				p.put("total_active", dao.getTotalActiveProducts());
				out.print(toJson(p));
				break;
			}

			case "delivery_agents": {
				Map<String, Object> p = new LinkedHashMap<>();
				p.put("agents", dao.getAgentDeliveryStats(intParam(req, "limit", 10)));
				p.put("success_rate", dao.getDeliverySuccessRate());
				p.put("total_agents", dao.getTotalDeliveryAgents());
				out.print(toJson(p));
				break;
			}

			case "customer_growth":
				out.print(toJson(dao.getCustomerGrowth(intParam(req, "months", 12))));
				break;

			case "payment_methods":
				out.print(toJson(dao.getPaymentMethodBreakdown()));
				break;

			case "staff_dept":
				out.print(toJson(dao.getStaffByDepartment()));
				break;

			case "all":
				out.print(toJson(buildAll(intParam(req, "months", 12))));
				break;

			default:
				sendError(res, HttpServletResponse.SC_BAD_REQUEST, "Unknown action: " + action);
			}
		} catch (SQLException e) {
			e.printStackTrace();
			sendError(res, HttpServletResponse.SC_INTERNAL_SERVER_ERROR, "Database error: " + e.getMessage());
		}
	}

	// ── Business logic helpers ──────────────────────────────────────

	private Map<String, Object> buildOverview() throws SQLException {
		Map<String, Object> m = new LinkedHashMap<>();
		double revTotal = dao.getTotalRevenue();
		double revMonth = dao.getRevenueThisMonth();
		double revLast = dao.getRevenueLastMonth();
		double revChange = revLast > 0 ? Math.round(((revMonth - revLast) / revLast * 100) * 10) / 10.0 : 0;

		m.put("total_revenue", round2(revTotal));
		m.put("revenue_month", round2(revMonth));
		m.put("revenue_change_pct", revChange);
		m.put("total_orders", dao.getTotalOrders());
		m.put("orders_this_month", dao.getOrdersThisMonth());
		m.put("avg_order_value", round2(dao.getAvgOrderValue()));
		m.put("total_customers", dao.getTotalCustomers());
		m.put("total_agents", dao.getTotalDeliveryAgents());
		m.put("total_products", dao.getTotalActiveProducts());
		m.put("low_stock_count", dao.getLowStockCount(10));
		m.put("leave_pending", dao.getLeaveSummary().getOrDefault("pending", 0));
		m.put("delivery_rate", dao.getDeliverySuccessRate().getOrDefault("rate", 0.0));
		return m;
	}

	private Map<String, Object> buildAll(int months) throws SQLException {
		Map<String, Object> all = new LinkedHashMap<>();
		all.put("overview", buildOverview());
		all.put("revenue_trend", dao.getMonthlyRevenueTrend(months));
		all.put("order_status", dao.getOrderStatusBreakdown());
		all.put("top_products", dao.getTopProducts(8));
		all.put("category_revenue", dao.getRevenuByCategory());
		all.put("attendance",
				dao.getAttendanceSummary(LocalDate.now().withDayOfMonth(1).toString(), LocalDate.now().toString()));
		all.put("att_trend", dao.getDailyAttendanceTrend(30));
		all.put("leave", dao.getLeaveSummary());
		all.put("leave_by_type", dao.getLeaveByType());
		all.put("agents", dao.getAgentDeliveryStats(10));
		all.put("delivery_rate", dao.getDeliverySuccessRate());
		all.put("customer_growth", dao.getCustomerGrowth(months));
		all.put("payment_methods", dao.getPaymentMethodBreakdown());
		all.put("staff_dept", dao.getStaffByDepartment());
		return all;
	}

	// ── Zero-dependency JSON serialiser ────────────────────────────
	// Handles: Map, List/array, String, Number, Boolean, null safely.

	@SuppressWarnings("unchecked")
	static String toJson(Object obj) {
		if (obj == null) {
			return "null";
		}
		if (obj instanceof Boolean) {
			return obj.toString();
		}
		if (obj instanceof Number) {
			double d = ((Number) obj).doubleValue();
			if (Double.isNaN(d) || Double.isInfinite(d)) {
				return "0";
			}
			// strip trailing .0 for whole numbers
			if (d == Math.floor(d) && !Double.isInfinite(d) && Math.abs(d) < 1e15) {
				return String.valueOf(((Number) obj).longValue());
			}
			return String.valueOf(d);
		}
		if (obj instanceof String) {
			return jsonString((String) obj);
		}
		if (obj instanceof Map) {
			Map<?, ?> map = (Map<?, ?>) obj;
			StringBuilder sb = new StringBuilder("{");
			boolean first = true;
			for (Map.Entry<?, ?> e : map.entrySet()) {
				if (!first) {
					sb.append(',');
				}
				sb.append(jsonString(String.valueOf(e.getKey()))).append(':').append(toJson(e.getValue()));
				first = false;
			}
			return sb.append('}').toString();
		}
		if (obj instanceof List) {
			List<?> list = (List<?>) obj;
			StringBuilder sb = new StringBuilder("[");
			for (int i = 0; i < list.size(); i++) {
				if (i > 0) {
					sb.append(',');
				}
				sb.append(toJson(list.get(i)));
			}
			return sb.append(']').toString();
		}
		// fallback — treat as string
		return jsonString(obj.toString());
	}

	private static String jsonString(String s) {
		StringBuilder sb = new StringBuilder("\"");
		for (char c : s.toCharArray()) {
			switch (c) {
			case '"':
				sb.append("\\\"");
				break;
			case '\\':
				sb.append("\\\\");
				break;
			case '\n':
				sb.append("\\n");
				break;
			case '\r':
				sb.append("\\r");
				break;
			case '\t':
				sb.append("\\t");
				break;
			default:
				if (c < 0x20) {
					sb.append(String.format("\\u%04x", (int) c));
				} else {
					sb.append(c);
				}
			}
		}
		return sb.append('"').toString();
	}

	// ── Misc helpers ───────────────────────────────────────────────

	private static double round2(double v) {
		return Math.round(v * 100) / 100.0;
	}

	private int intParam(HttpServletRequest req, String name, int def) {
		try {
			return Integer.parseInt(req.getParameter(name));
		} catch (Exception e) {
			return def;
		}
	}

	private void sendError(HttpServletResponse res, int code, String msg) throws IOException {
		res.setStatus(code);
		res.setContentType("application/json;charset=UTF-8");
		try (PrintWriter out = res.getWriter()) {
			out.print("{\"error\":" + jsonString(msg) + "}");
		}
	}
}