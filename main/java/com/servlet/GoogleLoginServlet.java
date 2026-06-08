package com.servlet;

import java.io.IOException;
import java.io.InputStream;
import java.io.OutputStream;
import java.net.HttpURLConnection;
import java.net.URL;
import java.net.URLEncoder;
import java.nio.charset.StandardCharsets;
import java.util.Scanner;

import org.json.JSONObject;

import com.DAO.CustomerDAO;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;

/**
 * GoogleLoginServlet
 *
 * Handles Google OAuth 2.0 login flow for Smart Inventory customers.
 *
 * Setup required: 1. Create a project at https://console.cloud.google.com/ 2.
 * Enable "Google+ API" or "Google Identity" API. 3. Create OAuth 2.0
 * credentials → Web application type. 4. Add Authorized Redirect URI:
 * http://localhost:8080/YourApp/GoogleCallback 5. Replace CLIENT_ID and
 * CLIENT_SECRET below with your actual credentials. 6. Store CLIENT_SECRET
 * securely (env variable or JNDI — NOT hardcoded in production).
 *
 * Dependencies (add to pom.xml or lib folder): - org.json:json:20231013 -
 * (Optional) Google OAuth client libraries for production use
 */
@WebServlet(urlPatterns = { "/GoogleLoginServlet", "/GoogleCallback" })
public class GoogleLoginServlet extends HttpServlet {

	// ─── CONFIGURATION ────────────────────────────────────────────────────────
	// Replace these with your actual Google OAuth credentials.
	// In production, load from environment variables or a secure config file.
	private static final String CLIENT_ID = System.getenv("GOOGLE_CLIENT_ID");
	private static final String CLIENT_SECRET = System.getenv("GOOGLE_CLIENT_SECRET");

	// This must match exactly what you registered in Google Cloud Console.
	private static final String REDIRECT_URI = "http://localhost:8085/SampleApp/GoogleCallback";

	// Google OAuth endpoints
	private static final String AUTH_URL = "https://accounts.google.com/o/oauth2/v2/auth";
	private static final String TOKEN_URL = "https://oauth2.googleapis.com/token";
	private static final String USERINFO_URL = "https://www.googleapis.com/oauth2/v3/userinfo";

	// Scopes: openid = authentication, email + profile = user info
	private static final String SCOPES = "openid email profile";

	// ─── STEP 1: Redirect user to Google's consent screen ────────────────────
	@Override
	protected void doGet(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {

		String path = req.getServletPath();

		// /GoogleCallback — handle the OAuth callback from Google
		if ("/GoogleCallback".equals(path)) {
			handleCallback(req, resp);
			return;
		}

		// /GoogleLoginServlet — initiate the Google login
		initiateGoogleLogin(req, resp);
	}

	/**
	 * Builds the Google authorization URL and redirects the user to it.
	 */
	private void initiateGoogleLogin(HttpServletRequest req, HttpServletResponse resp) throws IOException {

		// Generate a random state token to prevent CSRF
		String state = generateStateToken();
		req.getSession().setAttribute("oauth_state", state);

		String authUrl = AUTH_URL + "?client_id=" + URLEncoder.encode(CLIENT_ID, StandardCharsets.UTF_8)
				+ "&redirect_uri=" + URLEncoder.encode(REDIRECT_URI, StandardCharsets.UTF_8) + "&response_type=code"
				+ "&scope=" + URLEncoder.encode(SCOPES, StandardCharsets.UTF_8) + "&state="
				+ URLEncoder.encode(state, StandardCharsets.UTF_8) + "&access_type=offline" // get refresh token
				+ "&prompt=select_account"; // always show account picker

		resp.sendRedirect(authUrl);
	}

	// ─── STEP 2: Google redirects back here with an authorization code ────────
	/**
	 * Handles the OAuth callback: 1. Validates the state token (CSRF protection) 2.
	 * Exchanges the authorization code for an access token 3. Fetches the user's
	 * profile from Google 4. Creates or retrieves the user in the database 5.
	 * Creates a session and redirects to the dashboard
	 */
	private void handleCallback(HttpServletRequest req, HttpServletResponse resp) throws ServletException, IOException {

		// --- CSRF check ---
		String returnedState = req.getParameter("state");
		String savedState = (String) req.getSession().getAttribute("oauth_state");
		if (returnedState == null || !returnedState.equals(savedState)) {
			resp.sendRedirect("CustomerLogin.jsp?error=state_mismatch");
			return;
		}
		req.getSession().removeAttribute("oauth_state");

		// --- Check for errors from Google ---
		String error = req.getParameter("error");
		if (error != null) {
			// User denied access or another OAuth error occurred
			resp.sendRedirect("CustomerLogin.jsp?error=google_denied");
			return;
		}

		// --- Get the authorization code ---
		String code = req.getParameter("code");
		if (code == null || code.isEmpty()) {
			resp.sendRedirect("CustomerLogin.jsp?error=no_code");
			return;
		}

		// --- Exchange code for access token ---
		JSONObject tokenResponse = exchangeCodeForToken(code);
		if (tokenResponse == null || tokenResponse.has("error")) {
			resp.sendRedirect("CustomerLogin.jsp?error=token_exchange_failed");
			return;
		}

		String accessToken = tokenResponse.getString("access_token");

		// --- Fetch user profile from Google ---
		JSONObject userInfo = fetchUserInfo(accessToken);
		if (userInfo == null) {
			resp.sendRedirect("CustomerLogin.jsp?error=userinfo_failed");
			return;
		}

		// Extract user details
		String googleId = userInfo.optString("sub"); // Unique Google user ID
		String email = userInfo.optString("email");
		String name = userInfo.optString("name");
		String picture = userInfo.optString("picture");
		boolean emailVerified = userInfo.optBoolean("email_verified", false);

		if (!emailVerified) {
			resp.sendRedirect("CustomerLogin.jsp?error=email_not_verified");
			return;
		}

		// --- Find or create the user in DB ---
		// Replace this with your actual DAO call
		// CustomerDAO dao = new CustomerDAO();
		// Customer customer = dao.findOrCreateByGoogle(googleId, email, name, picture);
		//
		// Example stub — replace with real implementation:
		int customerId = findOrCreateGoogleUser(googleId, email, name, picture);

		if (customerId <= 0) {
			resp.sendRedirect("CustomerLogin.jsp?error=db_error");
			return;
		}

		// --- Create session ---
		HttpSession session = req.getSession(true);
		session.setAttribute("customerId", customerId);
		session.setAttribute("customerEmail", email);
		session.setAttribute("customerName", name);
		session.setAttribute("loginMethod", "google");
		session.setMaxInactiveInterval(30 * 60); // 30 minutes

		// --- Redirect to dashboard ---
		resp.sendRedirect("customerDashboard.jsp");
	}

	// ─── HELPER: Exchange authorization code for access token ────────────────
	private JSONObject exchangeCodeForToken(String code) throws IOException {
		String body = "code=" + URLEncoder.encode(code, StandardCharsets.UTF_8) + "&client_id="
				+ URLEncoder.encode(CLIENT_ID, StandardCharsets.UTF_8) + "&client_secret="
				+ URLEncoder.encode(CLIENT_SECRET, StandardCharsets.UTF_8) + "&redirect_uri="
				+ URLEncoder.encode(REDIRECT_URI, StandardCharsets.UTF_8) + "&grant_type=authorization_code";

		HttpURLConnection conn = (HttpURLConnection) new URL(TOKEN_URL).openConnection();
		conn.setRequestMethod("POST");
		conn.setDoOutput(true);
		conn.setRequestProperty("Content-Type", "application/x-www-form-urlencoded");
		conn.setConnectTimeout(5000);
		conn.setReadTimeout(5000);

		try (OutputStream os = conn.getOutputStream()) {
			os.write(body.getBytes(StandardCharsets.UTF_8));
		}

		int status = conn.getResponseCode();
		InputStream is = (status >= 200 && status < 300) ? conn.getInputStream() : conn.getErrorStream();

		try (Scanner scanner = new Scanner(is, StandardCharsets.UTF_8)) {
			String response = scanner.useDelimiter("\\A").next();
			return new JSONObject(response);
		} catch (Exception e) {
			e.printStackTrace();
			return null;
		}
	}

	// ─── HELPER: Fetch user profile from Google ───────────────────────────────
	private JSONObject fetchUserInfo(String accessToken) throws IOException {
		HttpURLConnection conn = (HttpURLConnection) new URL(USERINFO_URL).openConnection();
		conn.setRequestProperty("Authorization", "Bearer " + accessToken);
		conn.setConnectTimeout(5000);
		conn.setReadTimeout(5000);

		try (Scanner scanner = new Scanner(conn.getInputStream(), StandardCharsets.UTF_8)) {
			String response = scanner.useDelimiter("\\A").next();
			return new JSONObject(response);
		} catch (Exception e) {
			e.printStackTrace();
			return null;
		}
	}

	// ─── STUB: Find or create user in database ────────────────────────────────
	private int findOrCreateGoogleUser(String googleId, String email, String name, String picture) {
		try {
			// Assuming your CustomerDAO has a constructor that initializes the connection
			CustomerDAO dao = new CustomerDAO();

			// Call the new method we just added above
			return dao.findOrCreateGoogleUser(googleId, email, name, picture);

		} catch (Exception e) {
			System.err.println("[GoogleLogin] Database Error: " + e.getMessage());
			e.printStackTrace();
			return -1;
		}
	}

	// ─── HELPER: Generate a random state token for CSRF protection ───────────
	private String generateStateToken() {
		return java.util.UUID.randomUUID().toString().replace("-", "");
	}
}