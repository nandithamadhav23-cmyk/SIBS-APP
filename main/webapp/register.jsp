<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<!DOCTYPE html>
<html>
<head>
    <title>Admin Registration</title>
    <!-- Bootstrap CSS for alerts and buttons -->
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.2/dist/css/bootstrap.min.css" rel="stylesheet">
    <style>
        body {
            font-family: 'Poppins', sans-serif;
            background: linear-gradient(135deg, #a8edea, #fed6e3);
            display: flex;
            justify-content: center;
            align-items: center;
            min-height: 100vh;
            margin: 0;
        }
        .register-container {
            background: linear-gradient(135deg, #ffffff, #f9f9f9);
            padding: 35px 45px;
            border-radius: 15px;
            box-shadow: 0 10px 25px rgba(0,0,0,0.2);
            width: 540px;
            animation: fadeIn 1.2s ease-in;
        }
        .header {
            text-align: center;
            margin-bottom: 25px;
            display: flex;
            justify-content: center;
            align-items: center;
        }
        .header img {
            width: 70px;
            height: auto;
            margin-right: 12px;
        }
        .header h1 {
            font-size: 26px;
            font-weight: 700;
            color: #0077cc;
            margin: 0;
        }
        h2 {
            text-align: center;
            margin-bottom: 20px;
            color: #333;
            font-weight: 600;
        }
        .form-row {
            display: flex;
            align-items: center;
            margin-bottom: 18px;
        }
        .form-row label {
            flex: 1;
            font-weight: 600;
            color: #444;
        }
        .form-row input, .form-row select {
            flex: 2;
            padding: 12px;
            border: 1px solid #ccc;
            border-radius: 8px;
            outline: none;
            font-size: 14px;
            box-shadow: inset 0 2px 6px rgba(0,0,0,0.1);
            transition: border-color 0.3s, box-shadow 0.3s;
        }
        .form-row input:focus, .form-row select:focus {
            border-color: #ff7eb3;
            box-shadow: 0 0 8px rgba(255,126,179,0.4);
        }
        .inline-fields {
            display: flex;
            gap: 10px;
            flex: 2;
        }
        .inline-fields input {
            flex: 1;
        }
        button {
            width: 100%;
            padding: 14px;
            background: linear-gradient(90deg, #ff7eb3, #ff758c);
            border: none;
            border-radius: 8px;
            color: #fff;
            font-size: 16px;
            font-weight: 600;
            cursor: pointer;
            transition: transform 0.2s, box-shadow 0.3s;
        }
        button:hover {
            transform: translateY(-2px);
            box-shadow: 0 6px 15px rgba(0,0,0,0.2);
        }
        .back-btn {
            display: block;
            margin-top: 15px;
            text-align: center;
            text-decoration: none;
            color: #0077cc;
            font-weight: 600;
        }
        .back-btn:hover {
            text-decoration: underline;
        }
        .valid { color: #28a745; font-weight: 600; }
        .invalid { color: #dc3545; font-weight: 600; }
        #fullNumberPreview {
            font-size: 13px;
            color: #555;
            margin-top: -10px;
            margin-bottom: 10px;
            text-align: right;
        }
        @keyframes fadeIn {
            from { opacity: 0; transform: translateY(20px); }
            to { opacity: 1; transform: translateY(0); }
        }
    </style>
</head>
<body>
    <div class="register-container">
        <div class="header">
            <img src="images/logo.jpg" alt="Company Logo">
            <h1>SpeshWay Solutions</h1>
        </div>
        <h2>Admin Registration</h2>

        <!-- Alerts -->
        <% 
            String status = (String) request.getAttribute("status");
            String message = (String) request.getAttribute("message");
            if ("success".equals(status)) { %>
                <div class="alert alert-success alert-dismissible fade show" role="alert">
                    <%= message %>
                    <button type="button" class="btn-close" data-bs-dismiss="alert"></button>
                </div>
        <% } else if ("error".equals(status)) { %>
                <div class="alert alert-danger alert-dismissible fade show" role="alert">
                    <%= message %>
                    <button type="button" class="btn-close" data-bs-dismiss="alert"></button>
                </div>
        <% } %>

        <form action="register" method="post" target="_new">
            <div class="form-row">
                <label for="username">Username</label>
                <input id="username" name="username" type="text" placeholder="Enter your username" required autofocus>
            </div>
            <div class="form-row">
                <label for="password">Password</label>
                <input id="password" name="password" type="password" placeholder="Choose a strong password" required>
            </div>
            <div class="form-row">
                <label for="mobile">Mobile</label>
                <div class="inline-fields">
                    <input id="countryCode" name="countryCode" type="text" placeholder="+91" maxlength="4" required size="3">
                    <input id="mobile" name="mobile" type="text" placeholder="9876543210" maxlength="10" required>
                </div>
            </div>
            <div id="fullNumberPreview"></div>
            <small id="mobileFeedback"></small>
            <div class="form-row">
                <label for="gender">Gender</label>
                <select id="gender" name="gender" required>
                    <option value="" disabled selected>Select Gender</option>
                    <option value="Male">Male</option>
                    <option value="Female">Female</option>
                    <option value="Other">Other</option>
                </select>
            </div>
            <div>
                <button type="submit">Register</button>
            </div>
        </form>

        <!-- Back button -->
        <a href="index.jsp" class="back-btn">← Back to Home</a>
    </div>

    <!-- Bootstrap JS for alerts -->
    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.2/dist/js/bootstrap.bundle.min.js"></script>

    <!-- Live Validation Script -->
    <script>
    const countryCodeField = document.getElementById("countryCode");
    const mobileField = document.getElementById("mobile");
    const feedback = document.getElementById("mobileFeedback");
    const preview = document.getElementById("fullNumberPreview");

    const countryRegex = /^\+[0-9]{1,3}$/;   
    const mobileRegex = /^[0-9]{10}$/;      
    function validateMobile() {
        const countryCode = countryCodeField.value.trim();
        const mobileValue = mobileField.value.trim();

        // Live preview
        if (countryCode || mobileValue) {
            preview.textContent = "Full Number: " + countryCode + " " + mobileValue;
        } else {
            preview.textContent = "";
        }

        // Validation
        if (countryRegex.test(countryCode) && mobileRegex.test(mobileValue)) {
            feedback.textContent = "✔ Valid number";
            feedback.className = "valid";
        } else {
            feedback.textContent = "✖ Invalid number";
            feedback.className = "invalid";
        }
    }

    countryCodeField.addEventListener("input", validateMobile);
    mobileField.addEventListener("input", validateMobile);
    </script>
</body>
</html>
