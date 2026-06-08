package com.servlet;

import java.io.IOException;
import java.sql.Connection;

import com.DAO.DeliveryPersonDAO;
import com.DAO.DeliverySlotDAO;
import com.util.DBConnection;
import com.util.DeliverySlot;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;

@WebServlet("/AssignDeliveryServlet")
public class AssignDeliveryServlet extends HttpServlet {
	@Override
	protected void doPost(HttpServletRequest request, HttpServletResponse response)
			throws ServletException, IOException {
		String orderId = request.getParameter("orderId");
		String dpId = request.getParameter("deliveryPersonId");

		try (Connection conn = DBConnection.getConnection()) {
			DeliveryPersonDAO dao = new DeliveryPersonDAO(conn);
			boolean success = dao.assignDeliveryPerson(Integer.parseInt(orderId), Integer.parseInt(dpId));

			if (success) {
				// ── Link order to the agent's active/booked slot so slot counters and
				// slot_id on the order row are set correctly from assignment time.
				// This means updateSlotCounters(), releaseAgentIfSlotDone(), and
				// recordOrderEarning() in OrderServlet all work without a missing slotId.
				try (Connection slotConn = DBConnection.getConnection()) {
					DeliverySlotDAO slotDao = new DeliverySlotDAO(slotConn);
					DeliverySlot todaySlot = slotDao.getTodaySlot(Integer.parseInt(dpId));
					if (todaySlot != null && !"COMPLETED".equals(todaySlot.getStatus())
							&& !"INACTIVE".equals(todaySlot.getStatus())) {
						slotDao.assignOrderToSlot(Integer.parseInt(orderId), Integer.parseInt(dpId));
					}
				} catch (Exception slotEx) {
					// Non-fatal — order is assigned, slot linkage failed (agent has no slot today).
					// The slot guard in OrderServlet will block the agent from picking up
					// until they book and start a shift.
					System.err.println("[AssignDeliveryServlet] Slot linkage skipped for order " + orderId + ": "
							+ slotEx.getMessage());
				}
				// FIX 1: JSP calls res.json() and checks data.success — must return JSON
				response.setContentType("application/json");
				response.setCharacterEncoding("UTF-8");
				response.setStatus(HttpServletResponse.SC_OK);
				response.getWriter().write("{\"success\":true,\"message\":\"Agent assigned successfully.\"}");
			} else {
				response.setContentType("application/json");
				response.setCharacterEncoding("UTF-8");
				response.setStatus(HttpServletResponse.SC_INTERNAL_SERVER_ERROR);
				response.getWriter().write("{\"success\":false,\"message\":\"DAO failed to update database.\"}");
			}
		} catch (Exception e) {
			e.printStackTrace();
			response.setContentType("application/json");
			response.setCharacterEncoding("UTF-8");
			response.setStatus(HttpServletResponse.SC_INTERNAL_SERVER_ERROR);
			response.getWriter().write(
					"{\"success\":false,\"message\":\"Server error: " + e.getMessage().replace("\"", "'") + "\"}");
		}
	}
}