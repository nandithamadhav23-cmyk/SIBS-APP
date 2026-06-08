package com.servlet;

import java.io.IOException;
import java.sql.SQLException;
import java.util.List;

import com.DAO.AttendanceDAO;
import com.DAO.LeaveDAO;
import com.DAO.OrderDAO;
import com.DAO.ProductDAO;
import com.DAO.StaffNotificationDAO;
import com.DAO.UserDAO;
import com.util.LeaveRequest;
import com.util.LeaveType;
import com.util.OfficeShift;
import com.util.Order;
import com.util.Product;
import com.util.User;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;

@WebServlet("/UserDashboardServlet")
public class UserDashboardServlet extends HttpServlet {

	private final OrderDAO orderDAO = new OrderDAO();
	private final ProductDAO productDAO = new ProductDAO();
	private final UserDAO dao = new UserDAO();
	private final AttendanceDAO adao = new AttendanceDAO();
	private final LeaveDAO leaveDAO = new LeaveDAO(); // ← NEW
	private final StaffNotificationDAO notifDAO = new StaffNotificationDAO();

	@Override
	protected void doGet(HttpServletRequest req, HttpServletResponse res) throws ServletException, IOException {

		try {
			List<Order> orders = orderDAO.getAllOrders();
			List<Product> products = productDAO.getAllProducts();
			HttpSession session = req.getSession();
			User user = (User) session.getAttribute("user");
			String role = (session != null) ? (String) session.getAttribute("role") : null;
			if (role == null || !("staff".equalsIgnoreCase(role) || "admin".equalsIgnoreCase(role))) {
				req.setAttribute("error", "Access denied. Please login as staff or admin.");
				req.getRequestDispatcher("index.jsp").forward(req, res);
				return;
			}
			if (orders != null) {
				orders.sort((o1, o2) -> o2.getDate().compareTo(o1.getDate()));
			}

			OfficeShift shift = adao.getShiftById(user.getShiftId());
			session.setAttribute("orders", orders);
			session.setAttribute("products", products);
			session.setAttribute("userShift", shift);
			session.setAttribute("unreadNotifCount", notifDAO.countUnread());
			// ── Leave summary for dashboard widget ─────────────
			try {
				List<LeaveType> leaveTypes = leaveDAO.getLeaveTypesWithBalance(user.getUsername());
				List<LeaveRequest> leaveHistory = leaveDAO.getLeaveHistory(user.getUsername());

				long pendingLeaves = leaveHistory.stream().filter(r -> "pending".equalsIgnoreCase(r.getStatus()))
						.count();

				// Total available days across all paid leave types
				double totalAvail = leaveTypes.stream().filter(lt -> lt.isPaid())
						.mapToDouble(lt -> lt.getAvailable().doubleValue()).sum();

				session.setAttribute("leavePendingCount", pendingLeaves);
				session.setAttribute("leaveTotalAvail", totalAvail);
			} catch (Exception leaveEx) {
				// Leave feature failure must not break the main dashboard
				leaveEx.printStackTrace();
			}
			// ──────────────────────────────────────────────────

			req.getRequestDispatcher("userDashboard.jsp").forward(req, res);

		} catch (SQLException e) {
			throw new ServletException("Failed to load dashboard data", e);
		}
	}
}
