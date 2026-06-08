package com.servlet;

import java.io.IOException;
import java.io.PrintWriter;
import java.util.List;

import com.DAO.AddressDAO;
import com.DAO.OrderDAO;
import com.util.CustomerAddress;
import com.util.Order;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;

/**
 * AddressServlet
 *
 * New action: changeForOrder POST /Address?action=changeForOrder Params:
 * orderId, addressId, street, city, district, state, country, pincode
 *
 * Updates ONLY the snap_* columns on the specific order row. Does NOT touch
 * customer_address.is_default. Enforces: 1. Order must belong to the logged-in
 * customer (session customerId) 2. Order must be in a pre-shipment stage
 * (Ordered/Pending/Confirmed) 3. Address must belong to the same customer
 *
 * Returns JSON: { "success": true } or { "success": false, "error": "..." }
 */
@WebServlet("/Address")
public class AddressServlet extends HttpServlet {

	private static final long serialVersionUID = 1L;
	private AddressDAO addressDAO = new AddressDAO();
	private OrderDAO orderDAO = new OrderDAO();

	@Override
	protected void doGet(HttpServletRequest request, HttpServletResponse response)
			throws ServletException, IOException {
		String action = request.getParameter("action");
		int customerId = (int) request.getSession().getAttribute("customerId");

		try {
			if ("update".equals(action)) {
				int id = Integer.parseInt(request.getParameter("addressId"));
				CustomerAddress addr = addressDAO.getAddressById(id);
				request.setAttribute("address", addr);
				request.getRequestDispatcher("UpdateAddress.jsp").forward(request, response);

			} else if ("new".equals(action)) {
				request.setAttribute("customerId", customerId);
				request.getRequestDispatcher("NewAddress.jsp").forward(request, response);

			} else if ("delete".equals(action)) {
				int id = Integer.parseInt(request.getParameter("addressId"));
				boolean wasDefault = addressDAO.deleteAddress(id, customerId);
				List<CustomerAddress> addresses = addressDAO.getAddressesByCustomer(customerId);
				if (wasDefault) {
					if (!addresses.isEmpty()) {
						request.setAttribute("addresses", addresses);
						request.setAttribute("customerId", customerId);
						request.getRequestDispatcher("ChooseDefaultAddress.jsp").forward(request, response);
					} else {
						request.setAttribute("error", "❌ Cannot delete your only address.");
						request.getRequestDispatcher("Error.jsp").forward(request, response);
					}
				} else {
					request.setAttribute("addresses", addresses);
					request.getRequestDispatcher("AddressSnippet.jsp").forward(request, response);
				}

			} else if ("setDefault".equals(action)) {
				int addressId = Integer.parseInt(request.getParameter("addressId"));
				addressDAO.setDefaultAddress(customerId, addressId);
				List<CustomerAddress> addresses = addressDAO.getAddressesByCustomer(customerId);
				request.setAttribute("addresses", addresses);
				request.getRequestDispatcher("AddressSnippet.jsp").forward(request, response);
			}
		} catch (Exception e) {
			throw new ServletException(e);
		}
	}

	@Override
	protected void doPost(HttpServletRequest request, HttpServletResponse response)
			throws ServletException, IOException {
		String action = request.getParameter("action");
		int customerId = (int) request.getSession().getAttribute("customerId");

		try {

			// ── NEW: per-order address change ─────────────────────────────────
			if ("changeForOrder".equals(action)) {
				response.setContentType("application/json;charset=UTF-8");
				PrintWriter out = response.getWriter();
				try {
					String rawOid = request.getParameter("orderId");
					String rawAid = request.getParameter("addressId");

					if (rawOid == null || rawAid == null) {
						out.write("{\"success\":false,\"error\":\"Missing orderId or addressId\"}");
						return;
					}

					int orderId = Integer.parseInt(rawOid.replaceAll("[^0-9]", "").trim());
					int addressId = Integer.parseInt(rawAid.trim());

					// Security: verify the address belongs to this customer
					CustomerAddress newAddr = addressDAO.getAddressById(addressId);
					if (newAddr == null || newAddr.getCustomerId() != customerId) {
						out.write("{\"success\":false,\"error\":\"Address not found\"}");
						return;
					}

					// Allow form to pass explicit field overrides (e.g. from Kira chat)
					String street = nvl(request.getParameter("street"), newAddr.getLandmarkStreet());
					String city = nvl(request.getParameter("city"), newAddr.getCity());
					String district = nvl(request.getParameter("district"), newAddr.getDistrict());
					String state = nvl(request.getParameter("state"), newAddr.getState());
					String country = nvl(request.getParameter("country"), newAddr.getCountry());
					String pincode = nvl(request.getParameter("pincode"), newAddr.getPincode());

					// updateOrderAddress enforces ownership + stage gate
					boolean updated = orderDAO.updateOrderAddress(orderId, customerId, addressId, street, city,
							district, state, country, pincode);

					if (updated) {
						out.write("{\"success\":true}");
					} else {
						// Could be wrong customer OR already shipped
						Order order = orderDAO.getOrderById(orderId);
						if (order == null || order.getCustomerId() != customerId) {
							out.write("{\"success\":false,\"error\":\"Order not found\"}");
						} else {
							out.write(
									"{\"success\":false,\"error\":\"Address cannot be changed after shipment (status: "
											+ esc(order.getStatus()) + ")\"}");
						}
					}
				} catch (NumberFormatException e) {
					out.write("{\"success\":false,\"error\":\"Invalid ID\"}");
				} catch (Exception e) {
					out.write("{\"success\":false,\"error\":\"" + esc(e.getMessage()) + "\"}");
				}
				return;
			}

			// ── existing actions ──────────────────────────────────────────────
			if ("saveNew".equals(action)) {
				CustomerAddress addr = new CustomerAddress();
				addr.setCustomerId(Integer.parseInt(request.getParameter("customerId")));
				addr.setLandmarkStreet(request.getParameter("landmarkStreet"));
				addr.setCity(request.getParameter("city"));
				addr.setDistrict(request.getParameter("district"));
				addr.setState(request.getParameter("state"));
				addr.setCountry(request.getParameter("country"));
				addr.setPincode(request.getParameter("pincode"));
				addr.setDefault("true".equals(request.getParameter("isDefault")));
				addressDAO.addAddress(addr);
				List<CustomerAddress> addresses = addressDAO.getAddressesByCustomer(addr.getCustomerId());
				request.setAttribute("addresses", addresses);
				request.getRequestDispatcher("AddressSnippet.jsp").forward(request, response);

			} else if ("saveUpdate".equals(action)) {
				CustomerAddress addr = new CustomerAddress();
				addr.setAddressId(Integer.parseInt(request.getParameter("addressId")));
				addr.setCustomerId(Integer.parseInt(request.getParameter("customerId")));
				addr.setLandmarkStreet(request.getParameter("landmarkStreet"));
				addr.setCity(request.getParameter("city"));
				addr.setDistrict(request.getParameter("district"));
				addr.setState(request.getParameter("state"));
				addr.setCountry(request.getParameter("country"));
				addr.setPincode(request.getParameter("pincode"));
				addr.setDefault("true".equals(request.getParameter("isDefault")));
				addressDAO.updateAddress(addr);
				List<CustomerAddress> addresses = addressDAO.getAddressesByCustomer(addr.getCustomerId());
				request.setAttribute("addresses", addresses);
				request.getRequestDispatcher("AddressSnippet.jsp").forward(request, response);

			} else if ("delete".equals(action)) {
				int id = Integer.parseInt(request.getParameter("addressId"));
				int cid = Integer.parseInt(request.getParameter("customerId"));
				boolean wasDefault = addressDAO.deleteAddress(id, cid);
				List<CustomerAddress> addresses = addressDAO.getAddressesByCustomer(cid);
				if (wasDefault) {
					if (!addresses.isEmpty()) {
						request.setAttribute("addresses", addresses);
						request.setAttribute("customerId", cid);
						request.getRequestDispatcher("ChooseDefaultAddress.jsp").forward(request, response);
					} else {
						request.setAttribute("error", "❌ Cannot delete your only address.");
						request.getRequestDispatcher("Error.jsp").forward(request, response);
					}
				} else {
					request.setAttribute("addresses", addresses);
					request.getRequestDispatcher("AddressSnippet.jsp").forward(request, response);
				}

			} else if ("setDefault".equals(action)) {
				int addressId = Integer.parseInt(request.getParameter("addressId"));
				int cid = Integer.parseInt(request.getParameter("customerId"));
				addressDAO.setDefaultAddress(cid, addressId);
				List<CustomerAddress> addresses = addressDAO.getAddressesByCustomer(cid);
				request.setAttribute("addresses", addresses);
				request.getRequestDispatcher("AddressSnippet.jsp").forward(request, response);
			}

		} catch (Exception e) {
			throw new ServletException(e);
		}
	}

	private String nvl(String a, String b) {
		return (a != null && !a.isBlank()) ? a : b;
	}

	private String esc(String s) {
		if (s == null) {
			return "";
		}
		return s.replace("\\", "\\\\").replace("\"", "\\\"");
	}
}
