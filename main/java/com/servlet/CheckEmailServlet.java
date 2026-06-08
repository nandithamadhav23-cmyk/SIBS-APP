package com.servlet;

import java.io.IOException;
import java.sql.SQLException;

import com.DAO.UserDAO;

import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;

@WebServlet("/checkEmail")
public class CheckEmailServlet extends HttpServlet {
	@Override
	protected void doGet(HttpServletRequest req, HttpServletResponse resp) throws IOException {
		String email = req.getParameter("email");
		boolean exists = false;
		try {
			exists = new UserDAO().emailExists(email);

			req.setAttribute("status", "error");
			req.setAttribute("msg", "Email already registered");
		} catch (SQLException e) {
			// TODO Auto-generated catch block
			e.printStackTrace();
		}

		resp.setContentType("application/json");
		resp.getWriter().write("{\"exists\":" + exists + "}");
	}
}
