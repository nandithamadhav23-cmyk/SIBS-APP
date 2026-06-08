package com.servlet;

import java.io.IOException;
import java.util.List;

import com.DAO.UserDAO;
import com.util.User;

import jakarta.servlet.RequestDispatcher;
import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;

@WebServlet("/userList")
public class UserListServlet extends HttpServlet {
	private UserDAO userDAO = new UserDAO();

	@Override
	protected void doGet(HttpServletRequest request, HttpServletResponse response)
			throws ServletException, IOException {
		try {
			// Fetch users from DAO
			List<User> users = userDAO.getAllUsers();

			// Set as request attribute
			request.setAttribute("users", users);

			// Forward to JSP
			RequestDispatcher dispatcher = request.getRequestDispatcher("userList.jsp");
			dispatcher.forward(request, response);
		} catch (Exception e) {
			throw new ServletException(e);
		}
	}
}
