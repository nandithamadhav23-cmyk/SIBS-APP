<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%@ page import="com.util.*" %>
<%
    // BUG FIX: duplicate <%@ page  declaration removed (was in original)
    // All values come from PlaceOrderServlet session/request attributes — never from form params.
    String razorpayOrderId = (String) request.getAttribute("razorpayOrderId");
    String razorpayKey     = (String) request.getAttribute("razorpayKey");
    String grandTotal      = (String) request.getAttribute("grandTotal");
    Integer orderId        = (Integer) request.getAttribute("orderId");
    Customer customer      = (Customer) request.getAttribute("customer");
    String deliveryDate    = (String) request.getAttribute("delivery_date");
    String paymentMethod   = (String) request.getAttribute("paymentMethod");
%>
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Secure Payment — SIBS STORE</title>
  <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.2/dist/css/bootstrap.min.css" rel="stylesheet">
  <link href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.11.1/font/bootstrap-icons.css" rel="stylesheet">
  <link href="https://fonts.googleapis.com/css2?family=DM+Sans:wght@400;600;700&display=swap" rel="stylesheet">

  <!-- Razorpay SDK — load BEFORE the page script -->
  <script src="https://checkout.razorpay.com/v1/checkout.js"></script>

  <style>
    body { font-family: 'DM Sans', sans-serif; background: #f5f6fa; }
    .pay-card {
      max-width: 520px; margin: 40px auto; background: #fff;
      border-radius: 16px; box-shadow: 0 8px 32px rgba(0,0,0,.10); padding: 40px;
    }
    .secure-badge { font-size: .8rem; color: #6c757d; }
    #payBtn { width: 100%; font-size: 1.1rem; font-weight: 700; letter-spacing: .5px; }
    #retryBtn { display: none; }
    .spinner-wrap { display: none; text-align: center; margin-top: 16px; }

    @media(max-width:560px){
      .pay-card {
        margin: 0; border-radius: 0; min-height: 100vh;
        padding: 1.75rem 1.25rem;
        box-shadow: none;
      }
      #payBtn, #retryBtn { font-size: 1rem; padding: .85rem; }
      body { background: #fff; }
    }
  </style>
</head>
<body>

<div class="pay-card">
  <h4 class="mb-1 fw-bold"><i class="bi bi-lock-fill text-success me-2"></i>Secure Payment</h4>
  <p class="text-muted mb-4 secure-badge">256-bit SSL · Powered by Razorpay</p>

  <div class="mb-3 p-3 bg-light rounded-3">
    <div class="d-flex justify-content-between"><span>Order ID</span><strong>#<%= orderId %></strong></div>
    <div class="d-flex justify-content-between mt-1"><span>Amount</span><strong class="text-success">₹<%= grandTotal %></strong></div>
    <div class="d-flex justify-content-between mt-1"><span>Payment method</span><strong><%= paymentMethod %></strong></div>
    <% if (deliveryDate != null) { %>
    <div class="d-flex justify-content-between mt-1"><span>Est. delivery</span><strong><%= deliveryDate %></strong></div>
    <% } %>
  </div>

  <!-- Alert area — shows errors/messages to user -->
  <div id="alertArea"></div>

  <button id="payBtn" class="btn btn-success py-3 mt-2 rounded-pill">
    <i class="bi bi-credit-card me-2"></i>Pay ₹<%= grandTotal %> Now
  </button>

  <button id="retryBtn" class="btn btn-warning py-3 mt-2 rounded-pill w-100" onclick="openRazorpay()">
    <i class="bi bi-arrow-clockwise me-2"></i>Retry Payment
  </button>

  <div class="spinner-wrap" id="spinner">
    <div class="spinner-border text-success" role="status"></div>
    <p class="mt-2 text-muted">Verifying payment…</p>
  </div>

  <div class="text-center mt-4">
    <a href="CartServlet?action=view" class="text-muted" style="font-size:.85rem;">
      <i class="bi bi-arrow-left me-1"></i>Cancel & return to cart
    </a>
  </div>
</div>

<script>
  // ── All sensitive values injected server-side — nothing comes from the URL ──
  const RZP_KEY         = "<%= razorpayKey %>";
  const RZP_ORDER_ID    = "<%= razorpayOrderId %>";
  // Amount in paise (integer) — computed server-side to avoid JS float issues
  const AMOUNT_PAISE    = <%= (int)(Double.parseDouble(grandTotal) * 100) %>;
  const DB_ORDER_ID     = "<%= orderId %>";
  const CUSTOMER_NAME   = "<%= customer != null ? customer.getName().replace("\"","\\\"") : "" %>";
  const CUSTOMER_EMAIL  = "<%= customer != null ? customer.getEmail().replace("\"","\\\"") : "" %>";
  const CUSTOMER_PHONE  = "<%= customer != null ? customer.getPhone().replace("\"","\\\"") : "" %>";

  function showAlert(msg, type) {
    document.getElementById("alertArea").innerHTML =
      `<div class="alert alert-${type} mt-2">${msg}</div>`;
  }

  function openRazorpay() {
    document.getElementById("retryBtn").style.display = "none";
    document.getElementById("alertArea").innerHTML = "";

    var options = {
      key:         RZP_KEY,
      amount:      AMOUNT_PAISE,
      currency:    "INR",
      name:        "SIBS STORE",
      description: "Order #" + DB_ORDER_ID,
      order_id:    RZP_ORDER_ID,
     
      // ── Prefill customer info ──────────────────────────────────────────────
      prefill: {
    	  name:    "<%= request.getAttribute("customerName") %>",
          email:   "<%= request.getAttribute("customerEmail") %>",
          contact: "<%= request.getAttribute("customerPhone") %>"
      },

      // ── Theme ──────────────────────────────────────────────────────────────
      theme: { color: "#198754" },

      // ── Notes stored with the Razorpay transaction ─────────────────────────
      notes: { db_order_id: DB_ORDER_ID },

      // ── SUCCESS handler ────────────────────────────────────────────────────
      handler: function(response) {
        document.getElementById("payBtn").disabled = true;
        document.getElementById("spinner").style.display = "block";

        // Build a hidden form and POST to PaymentServlet
        // orderId is intentionally NOT sent from the form — PaymentServlet reads from session
        var form = document.createElement("form");
        form.method = "POST";
        form.action = "PaymentServlet";

        var fields = {
          razorpay_payment_id : response.razorpay_payment_id,
          razorpay_order_id   : response.razorpay_order_id,
          razorpay_signature  : response.razorpay_signature
        };

        Object.entries(fields).forEach(([k, v]) => {
          var inp = document.createElement("input");
          inp.type  = "hidden";
          inp.name  = k;
          inp.value = v;
          form.appendChild(inp);
        });

        document.body.appendChild(form);
        form.submit();
      },

      // ── MODAL DISMISSED (user closed the popup) ────────────────────────────
      modal: {
        ondismiss: function() {
          showAlert(
            "⚠️ Payment window closed. Your order is saved — you can retry payment.",
            "warning"
          );
          document.getElementById("retryBtn").style.display = "block";
        }
      }
    };

    // ── Razorpay payment failure callback ─────────────────────────────────────
    var rzp = new Razorpay(options);

    rzp.on("payment.failed", function(response) {
      var code = response.error.code || "UNKNOWN";
      var desc = response.error.description || "Payment failed.";

      // User-friendly messages for common failure codes
      var userMsg = {
        "BAD_REQUEST_ERROR"  : "Payment details were invalid. Please check and try again.",
        "GATEWAY_ERROR"      : "There was a gateway issue. Please retry or use a different method.",
        "SERVER_ERROR"       : "A server error occurred. Please try after a few minutes.",
        "NETWORK_ERROR"      : "Network error. Please check your connection and retry."
      }[code] || desc;

      showAlert("❌ " + userMsg, "danger");
      document.getElementById("retryBtn").style.display = "block";

      // Optionally log to server for tracking
      fetch("PaymentServlet?orderId=" + DB_ORDER_ID + "&status=failed&code=" + code, {
        method: "GET", credentials: "same-origin"
      }).catch(() => {});
    });

    rzp.open();
  }

  document.getElementById("payBtn").onclick = function() {
    this.disabled = true;
    openRazorpay();
  };

  // Auto-open on page load (UX improvement — no extra click needed)
  window.addEventListener("load", function() {
    setTimeout(openRazorpay, 1000);
  });
</script>

</body>
</html>
