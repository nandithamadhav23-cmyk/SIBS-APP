package com.servlet;

import java.io.BufferedReader;
import java.io.IOException;
import java.io.InputStreamReader;
import java.io.OutputStream;
import java.net.HttpURLConnection;
import java.net.URL;
import java.util.Base64;

import org.json.JSONObject;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;

@WebServlet("/UPIQrCodeServlet")
public class UPIQrCodeServlet extends HttpServlet {

    private static final long serialVersionUID = 1L;

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        int    orderId   = Integer.parseInt(request.getParameter("orderId"));
        double amount    = Double.parseDouble(request.getParameter("amount"));
        String keyId     = getServletContext().getInitParameter("razorpay.key_id");
        String keySecret = getServletContext().getInitParameter("razorpay.key_secret");

        try {
            // ── Build QR Code request body ───────────────────────────────────
            JSONObject qrRequest = new JSONObject();
            qrRequest.put("type",           "upi_qr");
            qrRequest.put("name",           "Order #" + orderId);
            qrRequest.put("usage",          "single_use");
            qrRequest.put("fixed_amount",   true);
            qrRequest.put("payment_amount", (int)(amount * 100));   // paise
            qrRequest.put("description",    "UPI Payment for Order #" + orderId);

            // close_by: min 2 min ahead, max 2 hours — using 25 minutes
            long closeBy = (System.currentTimeMillis() / 1000L) + (25 * 60);
            qrRequest.put("close_by", closeBy);

            // ── FIX: correct Razorpay endpoint is /v1/payments/qr_codes ─────
            //    (NOT /v1/qr_codes — that returns 404 "no route matched")
            String apiUrl = "https://api.razorpay.com/v1/payments/qr_codes";

            HttpURLConnection conn = (HttpURLConnection) new URL(apiUrl).openConnection();
            conn.setRequestMethod("POST");
            conn.setRequestProperty("Content-Type", "application/json");
            conn.setRequestProperty("Accept",       "application/json");

            String auth        = keyId + ":" + keySecret;
            String encodedAuth = Base64.getEncoder().encodeToString(auth.getBytes("UTF-8"));
            conn.setRequestProperty("Authorization", "Basic " + encodedAuth);
            conn.setDoOutput(true);
            conn.setConnectTimeout(10000);
            conn.setReadTimeout(15000);

            // Write request body
            try (OutputStream os = conn.getOutputStream()) {
                os.write(qrRequest.toString().getBytes("UTF-8"));
                os.flush();
            }

            int httpStatus = conn.getResponseCode();

            // Read response or error body
            BufferedReader br;
            if (httpStatus == 200 || httpStatus == 201) {
                br = new BufferedReader(new InputStreamReader(conn.getInputStream(), "UTF-8"));
            } else {
                br = new BufferedReader(new InputStreamReader(conn.getErrorStream(), "UTF-8"));
            }

            StringBuilder sb = new StringBuilder();
            String line;
            try (br) {
                while ((line = br.readLine()) != null) sb.append(line);
            }

            if (httpStatus != 200 && httpStatus != 201) {
                throw new ServletException(
                    "Razorpay QR API error [" + httpStatus + "]: " + sb +
                    "\nRequest was: " + qrRequest.toString()
                );
            }

            JSONObject qrResponse = new JSONObject(sb.toString());

            // ── Forward to JSP ───────────────────────────────────────────────
            String qrImageUrl = qrResponse.getString("image_url");
            String qrCodeId   = qrResponse.getString("id");

            request.setAttribute("qrCodeId",   qrCodeId);
            request.setAttribute("qrImageUrl", qrImageUrl);
            request.setAttribute("amount",     amount);
            request.setAttribute("orderId",    orderId);

            request.getRequestDispatcher("UPIPayment.jsp").forward(request, response);

        } catch (ServletException se) {
            throw se;
        } catch (Exception e) {
            throw new ServletException("Failed to create Razorpay QR code: " + e.getMessage(), e);
        }
    }
}
