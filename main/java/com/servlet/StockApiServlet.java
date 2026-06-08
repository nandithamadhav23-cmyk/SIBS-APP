package com.servlet;

import java.io.IOException;
import java.io.PrintWriter;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

import com.util.DBConnection;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;

/**
 * StockApiServlet — Zero-dependency JSON API for the Stock Dashboard.
 *
 * Actions:
 *   GET ?action=overview        — KPI summary counts
 *   GET ?action=all_products    — full product list with stock details
 *   GET ?action=out_of_stock    — products with stock = 0
 *   GET ?action=low_stock       — products with 0 < stock <= threshold (default 10)
 *   GET ?action=category_stock  — stock grouped by category
 *   GET ?action=stock_trend     — top overstocked products (stock > 50)
 *   POST ?action=update_stock   — update stock for a single product (id, stock params)
 */
@WebServlet("/StockApiServlet")
public class StockApiServlet extends HttpServlet {

    private static final long serialVersionUID = 1L;
    private static final int LOW_STOCK_THRESHOLD = 10;

    // ── Auth guard shared by GET and POST ──────────────────────────────
    private boolean checkAuth(HttpServletRequest req, HttpServletResponse res) throws IOException {
        HttpSession session = req.getSession(false);
        String role = (session != null) ? (String) session.getAttribute("role") : null;
        if (role == null || !("admin".equalsIgnoreCase(role) || "staff".equalsIgnoreCase(role))) {
            sendError(res, HttpServletResponse.SC_UNAUTHORIZED, "Unauthorized");
            return false;
        }
        return true;
    }

    // ── GET ────────────────────────────────────────────────────────────
    @Override
    protected void doGet(HttpServletRequest req, HttpServletResponse res)
            throws ServletException, IOException {

        if (!checkAuth(req, res)) return;

        res.setContentType("application/json;charset=UTF-8");
        res.setHeader("Cache-Control", "no-cache");

        String action = req.getParameter("action");
        if (action == null) action = "overview";

        int threshold = intParam(req, "threshold", LOW_STOCK_THRESHOLD);

        try (PrintWriter out = res.getWriter()) {
            switch (action) {

                case "overview":
                    out.print(toJson(buildOverview(threshold)));
                    break;

                case "all_products":
                    out.print(toJson(getAllProducts()));
                    break;

                case "out_of_stock":
                    out.print(toJson(getProductsByStockRange(0, 0)));
                    break;

                case "low_stock":
                    out.print(toJson(getProductsByStockRange(1, threshold)));
                    break;

                case "category_stock":
                    out.print(toJson(getCategoryStock()));
                    break;

                case "stock_trend":
                    out.print(toJson(getStockDistribution(threshold)));
                    break;

                case "all":
                    Map<String, Object> all = new LinkedHashMap<>();
                    all.put("overview",       buildOverview(threshold));
                    all.put("all_products",   getAllProducts());
                    all.put("category_stock", getCategoryStock());
                    all.put("stock_trend",    getStockDistribution(threshold));
                    out.print(toJson(all));
                    break;

                default:
                    sendError(res, HttpServletResponse.SC_BAD_REQUEST, "Unknown action: " + action);
            }
        } catch (SQLException e) {
            e.printStackTrace();
            sendError(res, HttpServletResponse.SC_INTERNAL_SERVER_ERROR, "Database error: " + e.getMessage());
        }
    }

    // ── POST ───────────────────────────────────────────────────────────
    @Override
    protected void doPost(HttpServletRequest req, HttpServletResponse res)
            throws ServletException, IOException {

        if (!checkAuth(req, res)) return;

        res.setContentType("application/json;charset=UTF-8");
        String action = req.getParameter("action");

        try (PrintWriter out = res.getWriter()) {
            if ("update_stock".equalsIgnoreCase(action)) {
                int id    = intParam(req, "id", -1);
                int stock = intParam(req, "stock", -1);
                if (id <= 0 || stock < 0) {
                    sendError(res, HttpServletResponse.SC_BAD_REQUEST, "Invalid id or stock value");
                    return;
                }
                updateStock(id, stock);
                Map<String, Object> r = new LinkedHashMap<>();
                r.put("ok", true);
                r.put("id", id);
                r.put("stock", stock);
                out.print(toJson(r));
            } else {
                sendError(res, HttpServletResponse.SC_BAD_REQUEST, "Unknown action");
            }
        } catch (SQLException e) {
            e.printStackTrace();
            sendError(res, HttpServletResponse.SC_INTERNAL_SERVER_ERROR, "Database error: " + e.getMessage());
        }
    }

    // ── Business logic ─────────────────────────────────────────────────

    private Map<String, Object> buildOverview(int threshold) throws SQLException {
        String sql =
            "SELECT " +
            "  COUNT(*)                                               AS total, " +
            "  SUM(CASE WHEN deleted_at IS NULL AND status='active' THEN 1 ELSE 0 END) AS active, " +
            "  SUM(CASE WHEN stock = 0 THEN 1 ELSE 0 END)            AS out_of_stock, " +
            "  SUM(CASE WHEN stock > 0 AND stock <= ? THEN 1 ELSE 0 END) AS low_stock, " +
            "  SUM(CASE WHEN stock > ? THEN 1 ELSE 0 END)            AS in_stock, " +
            "  COALESCE(SUM(stock), 0)                               AS total_units, " +
            "  COUNT(DISTINCT category)                              AS categories " +
            "FROM products WHERE deleted_at IS NULL";
        Map<String, Object> m = new LinkedHashMap<>();
        try (Connection con = DBConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(sql)) {
            ps.setInt(1, threshold);
            ps.setInt(2, threshold);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) {
                    m.put("total",       rs.getInt("total"));
                    m.put("active",      rs.getInt("active"));
                    m.put("out_of_stock",rs.getInt("out_of_stock"));
                    m.put("low_stock",   rs.getInt("low_stock"));
                    m.put("in_stock",    rs.getInt("in_stock"));
                    m.put("total_units", rs.getInt("total_units"));
                    m.put("categories",  rs.getInt("categories"));
                    m.put("threshold",   threshold);
                }
            }
        }
        return m;
    }

    private List<Map<String, Object>> getAllProducts() throws SQLException {
        String sql =
            "SELECT product_id, name, category, mrp, final_price, discount, stock, " +
            "       quantity, unit, status, imageUrl, addedDate " +
            "FROM products WHERE deleted_at IS NULL " +
            "ORDER BY stock ASC, name ASC";
        return queryProducts(sql);
    }

    private List<Map<String, Object>> getProductsByStockRange(int min, int max) throws SQLException {
        String sql;
        if (min == 0 && max == 0) {
            sql = "SELECT product_id, name, category, mrp, final_price, discount, stock, " +
                  "quantity, unit, status, imageUrl, addedDate " +
                  "FROM products WHERE deleted_at IS NULL AND stock = 0 ORDER BY name ASC";
        } else {
            sql = "SELECT product_id, name, category, mrp, final_price, discount, stock, " +
                  "quantity, unit, status, imageUrl, addedDate " +
                  "FROM products WHERE deleted_at IS NULL AND stock >= " + min +
                  " AND stock <= " + max + " ORDER BY stock ASC, name ASC";
        }
        return queryProducts(sql);
    }

    private List<Map<String, Object>> getCategoryStock() throws SQLException {
        String sql =
            "SELECT COALESCE(category,'Uncategorised') AS category, " +
            "       COUNT(*) AS product_count, " +
            "       COALESCE(SUM(stock), 0) AS total_stock, " +
            "       SUM(CASE WHEN stock = 0 THEN 1 ELSE 0 END) AS out_of_stock, " +
            "       SUM(CASE WHEN stock > 0 AND stock <= 10 THEN 1 ELSE 0 END) AS low_stock, " +
            "       SUM(CASE WHEN stock > 10 THEN 1 ELSE 0 END) AS healthy " +
            "FROM products WHERE deleted_at IS NULL " +
            "GROUP BY category ORDER BY total_stock DESC";
        List<Map<String, Object>> list = new ArrayList<>();
        try (Connection con = DBConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {
            while (rs.next()) {
                Map<String, Object> row = new LinkedHashMap<>();
                row.put("category",      rs.getString("category"));
                row.put("product_count", rs.getInt("product_count"));
                row.put("total_stock",   rs.getInt("total_stock"));
                row.put("out_of_stock",  rs.getInt("out_of_stock"));
                row.put("low_stock",     rs.getInt("low_stock"));
                row.put("healthy",       rs.getInt("healthy"));
                list.add(row);
            }
        }
        return list;
    }

    private List<Map<String, Object>> getStockDistribution(int threshold) throws SQLException {
        // Returns buckets: out, low, healthy, overstocked
        String sql =
            "SELECT " +
            "  SUM(CASE WHEN stock = 0             THEN 1 ELSE 0 END) AS out_of_stock, " +
            "  SUM(CASE WHEN stock > 0  AND stock <= ? THEN 1 ELSE 0 END) AS low_stock, " +
            "  SUM(CASE WHEN stock > ?  AND stock <= 50 THEN 1 ELSE 0 END) AS healthy, " +
            "  SUM(CASE WHEN stock > 50              THEN 1 ELSE 0 END) AS overstocked " +
            "FROM products WHERE deleted_at IS NULL";
        List<Map<String, Object>> list = new ArrayList<>();
        try (Connection con = DBConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(sql)) {
            ps.setInt(1, threshold);
            ps.setInt(2, threshold);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) {
                    addBucket(list, "Out of Stock", rs.getInt("out_of_stock"), "#dc2626");
                    addBucket(list, "Low Stock",    rs.getInt("low_stock"),    "#d97706");
                    addBucket(list, "Healthy",      rs.getInt("healthy"),      "#16a34a");
                    addBucket(list, "Overstocked",  rs.getInt("overstocked"),  "#7c3aed");
                }
            }
        }
        return list;
    }

    private void addBucket(List<Map<String, Object>> list, String label, int count, String color) {
        Map<String, Object> m = new LinkedHashMap<>();
        m.put("label", label);
        m.put("count", count);
        m.put("color", color);
        list.add(m);
    }

    private List<Map<String, Object>> queryProducts(String sql) throws SQLException {
        List<Map<String, Object>> list = new ArrayList<>();
        try (Connection con = DBConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {
            while (rs.next()) {
                Map<String, Object> row = new LinkedHashMap<>();
                row.put("id",          rs.getInt("product_id"));
                row.put("name",        rs.getString("name"));
                row.put("category",    rs.getString("category") != null ? rs.getString("category") : "Uncategorised");
                row.put("mrp",         rs.getDouble("mrp"));
                row.put("final_price", rs.getDouble("final_price"));
                row.put("discount",    rs.getDouble("discount"));
                row.put("stock",       rs.getInt("stock"));
                row.put("quantity",    rs.getInt("quantity"));
                row.put("unit",        rs.getString("unit") != null ? rs.getString("unit") : "");
                row.put("status",      rs.getString("status"));
                row.put("image",       rs.getString("imageUrl") != null ? rs.getString("imageUrl") : "");
                row.put("added",       rs.getTimestamp("addedDate") != null
                                       ? rs.getTimestamp("addedDate").toString().substring(0, 10) : "");
                list.add(row);
            }
        }
        return list;
    }

    private void updateStock(int id, int stock) throws SQLException {
        String status = stock == 0 ? "inactive" : "active";
        String sql = "UPDATE products SET stock=?, status=? WHERE product_id=? AND deleted_at IS NULL";
        try (Connection con = DBConnection.getConnection();
             PreparedStatement ps = con.prepareStatement(sql)) {
            ps.setInt(1, stock);
            ps.setString(2, status);
            ps.setInt(3, id);
            ps.executeUpdate();
        }
    }

    // ── Zero-dependency JSON serialiser ────────────────────────────────
    @SuppressWarnings("unchecked")
    static String toJson(Object obj) {
        if (obj == null) return "null";
        if (obj instanceof Boolean) return obj.toString();
        if (obj instanceof Number) {
            double d = ((Number) obj).doubleValue();
            if (Double.isNaN(d) || Double.isInfinite(d)) return "0";
            if (d == Math.floor(d) && !Double.isInfinite(d) && Math.abs(d) < 1e15)
                return String.valueOf(((Number) obj).longValue());
            return String.valueOf(d);
        }
        if (obj instanceof String) return jsonStr((String) obj);
        if (obj instanceof Map) {
            Map<?, ?> map = (Map<?, ?>) obj;
            StringBuilder sb = new StringBuilder("{");
            boolean first = true;
            for (Map.Entry<?, ?> e : map.entrySet()) {
                if (!first) sb.append(',');
                sb.append(jsonStr(String.valueOf(e.getKey()))).append(':').append(toJson(e.getValue()));
                first = false;
            }
            return sb.append('}').toString();
        }
        if (obj instanceof List) {
            List<?> list = (List<?>) obj;
            StringBuilder sb = new StringBuilder("[");
            for (int i = 0; i < list.size(); i++) {
                if (i > 0) sb.append(',');
                sb.append(toJson(list.get(i)));
            }
            return sb.append(']').toString();
        }
        return jsonStr(obj.toString());
    }

    private static String jsonStr(String s) {
        StringBuilder sb = new StringBuilder("\"");
        for (char c : s.toCharArray()) {
            switch (c) {
                case '"':  sb.append("\\\""); break;
                case '\\': sb.append("\\\\"); break;
                case '\n': sb.append("\\n");  break;
                case '\r': sb.append("\\r");  break;
                case '\t': sb.append("\\t");  break;
                default:
                    if (c < 0x20) sb.append(String.format("\\u%04x", (int) c));
                    else sb.append(c);
            }
        }
        return sb.append('"').toString();
    }

    // ── Helpers ────────────────────────────────────────────────────────
    private int intParam(HttpServletRequest req, String name, int def) {
        try { return Integer.parseInt(req.getParameter(name)); }
        catch (Exception e) { return def; }
    }

    private void sendError(HttpServletResponse res, int code, String msg) throws IOException {
        res.setStatus(code);
        res.setContentType("application/json;charset=UTF-8");
        try (PrintWriter out = res.getWriter()) {
            out.print("{\"error\":" + jsonStr(msg) + "}");
        }
    }
}
