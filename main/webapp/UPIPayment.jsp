<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="java.util.*" %>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>UPI Payment - SIBS Logistics</title>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.2/dist/css/bootstrap.min.css" rel="stylesheet">
    <script src="https://checkout.razorpay.com/v1/checkout.js"></script>
</head>
<body class="bg-light">

<!-- Navbar -->
<nav class="navbar navbar-dark bg-dark shadow-sm">
    <div class="container-fluid">
        <a class="navbar-brand fw-bold" href="#">SIBS Logistics</a>
    </div>
</nav>

<div class="container mt-5">
    <div class="card shadow-sm">
        <div class="card-header bg-primary text-white">
            <h5 class="mb-0">Pay with UPI</h5>
        </div>
        <div class="card-body text-center">
            <p class="lead">Order #<%= request.getAttribute("orderId") %></p>
            <p>Total Amount: <strong>₹<%= request.getAttribute("amount") %></strong></p>

            <!-- Razorpay Checkout Trigger -->
            <button id="payBtn" class="btn btn-success btn-lg">
                <i class="bi bi-upc-scan"></i> Pay Now via UPI
            </button>

            <p class="mt-3 text-muted">You can pay using UPI apps like Google Pay, PhonePe, Paytm, or BHIM.</p>
        </div>
    </div>
</div>

<script>
    var options = {
        "key": "<%= application.getInitParameter("razorpay.key_id") %>", // from web.xml
        "amount": "<%= (int)((Double)request.getAttribute("amount") * 100) %>", // paise
        "currency": "INR",
        "name": "SIBS Logistics",
        "description": "Order Payment",
        "order_id": "<%= request.getAttribute("razorpayOrderId") %>", // Razorpay order ID
        "handler": function (response){
            // Post back to PaymentServlet for verification
            var form = document.createElement("form");
            form.method = "post";
            form.action = "PaymentServlet";
            form.innerHTML = `
                <input type="hidden" name="razorpay_payment_id" value="${response.razorpay_payment_id}">
                <input type="hidden" name="razorpay_order_id" value="${response.razorpay_order_id}">
                <input type="hidden" name="razorpay_signature" value="${response.razorpay_signature}">
            `;
            document.body.appendChild(form);
            form.submit();
        },
        "prefill": {
            "email": "<%= request.getAttribute("customerEmail") %>",
            "contact": "<%= request.getAttribute("customerPhone") %>"
        },
        "theme": {
            "color": "#3399cc"
        }
    };
    document.getElementById('payBtn').onclick = function(e){
        var rzp1 = new Razorpay(options);
        rzp1.open();
        e.preventDefault();
    }
</script>

</body>
</html>
