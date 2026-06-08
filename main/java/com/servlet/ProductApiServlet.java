package com.servlet;

import java.io.IOException;
import java.io.PrintWriter;
import java.sql.SQLException;
import java.util.List;

import com.DAO.ProductDAO;
import com.util.Product;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;

@WebServlet("/api/products")
public class ProductApiServlet extends HttpServlet {
	private ProductDAO productDAO;

	@Override
	public void init() throws ServletException {

		productDAO = new ProductDAO();

	}

	@Override
	protected void doGet(HttpServletRequest req, HttpServletResponse res) throws IOException {
		res.setContentType("application/json");
		List<Product> products;
		try {
			products = productDAO.getAllProducts();
			PrintWriter out = res.getWriter();
			out.print(toJson(products));
			out.flush();
		} catch (SQLException e) {
			res.setStatus(HttpServletResponse.SC_INTERNAL_SERVER_ERROR);
			res.getWriter().print("{\"error\":\"Database error\"}");
		}
	}

	private String toJson(List<Product> products) {
		StringBuilder sb = new StringBuilder("[");
		for (int i = 0; i < products.size(); i++) {
			Product p = products.get(i);
			sb.append("{").append("\"id\":").append(p.getId()).append(",").append("\"name\":\"").append(p.getName())
					.append("\",").append("\"price\":").append(p.getMrp()).append(",").append("\"quantity\":")
					.append(p.getQuantity()).append(",").append("\"discount\":").append(p.getDiscount()).append(",")
					.append("\"category\":\"").append(p.getCategory()).append("\",").append("\"description\":\"")
					.append(p.getDescription()).append("\",").append("\"imageUrl\":\"").append(p.getImageUrl())
					.append("\"").append("}");
			if (i < products.size() - 1) {
				sb.append(",");
			}
		}
		sb.append("]");
		return sb.toString();
	}
}
