package com.filter;

import java.io.IOException;

import jakarta.servlet.Filter;
import jakarta.servlet.FilterChain;
import jakarta.servlet.FilterConfig;
import jakarta.servlet.ServletException;
import jakarta.servlet.ServletRequest;
import jakarta.servlet.ServletResponse;
import jakarta.servlet.annotation.WebFilter;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;

@WebFilter({ "/dashboard.jsp", "/userDashboard.jsp" })
public class AuthFilter implements Filter {

	@Override
	public void doFilter(ServletRequest request, ServletResponse response, FilterChain chain)
			throws IOException, ServletException {

		HttpServletRequest req = (HttpServletRequest) request;
		HttpServletResponse res = (HttpServletResponse) response;
		HttpSession session = req.getSession(false);

		String role = (session != null) ? (String) session.getAttribute("role") : null;
		String uri = req.getRequestURI();

		if (role == null) {
			res.sendRedirect("index.jsp?error=Please login first.");
			return;
		}

		if (uri.endsWith("dashboard.jsp") && !"admin".equalsIgnoreCase(role)) {
			res.sendRedirect("index.jsp?error=Access denied. Admin only.");
			return;
		}

		if (uri.endsWith("userDashboard.jsp") && !"staff".equalsIgnoreCase(role) && !"admin".equalsIgnoreCase(role)) {
			res.sendRedirect("index.jsp?error=Access denied. Staff only.");
			return;
		}

		// If checks pass, continue request
		chain.doFilter(request, response);
	}

	@Override
	public void init(FilterConfig filterConfig) throws ServletException {
	}

	@Override
	public void destroy() {
	}
}
