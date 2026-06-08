# SIBS-APP — Smart Inventory & Business System

A full-stack Java web application built with Jakarta Servlets and JSP, providing end-to-end management for an online store — covering customers, staff, inventory, orders, payments, delivery, and AI-assisted support.

---

## Table of Contents

- [Overview](#overview)
- [Features](#features)
- [Tech Stack](#tech-stack)
- [Project Structure](#project-structure)
- [Prerequisites](#prerequisites)
- [Setup & Installation](#setup--installation)
- [Environment Variables](#environment-variables)
- [Database Configuration](#database-configuration)
- [Running the Application](#running-the-application)
- [User Roles](#user-roles)
- [Key Modules](#key-modules)
- [API Integrations](#api-integrations)
- [Security Notes](#security-notes)

---

## Overview

SIBS-APP (Smart Inventory & Business System) is a multi-role web application for managing a retail business. It supports customers browsing and buying products, staff managing inventory and orders, delivery agents handling dispatches, and admins overseeing everything — all from a single platform.

---

## Features

### Customer-Facing
- Registration, login, and Google OAuth 2.0 sign-in
- OTP verification via Twilio SMS
- Product browsing, search, cart, wishlist, and quick view
- Multiple address management with default address selection
- Checkout with multiple payment options (Razorpay, UPI, COD, Wallet)
- Order tracking, invoices, and return requests
- Customer wallet with top-up and transaction history
- Notifications, help desk tickets, and AI chat support
- Loyalty points and referral system

### Staff / Admin
- Role-based dashboard for Admin, Staff, and Delivery agents
- Product management (add, edit, delete, image upload)
- Stock management and low-stock alerts
- Order management and assignment to delivery agents
- Delivery slot scheduling and management
- User management (add, edit, delete staff accounts)
- Leave requests and approval workflow
- Attendance tracking with punch-in/out and auto-sweep scheduler
- Staff wallet and COD deposit management
- Reports dashboard (sales, orders, attendance)
- AI chat assistant for staff queries
- Notification system for all roles
- Help desk / support ticket queue

---

## Tech Stack

| Layer | Technology |
|---|---|
| Language | Java 17+ |
| Web Framework | Jakarta Servlet 6.x / JSP |
| Server | Apache Tomcat 10+ |
| Database | MySQL 8.x |
| Frontend | HTML, CSS, JavaScript, Bootstrap |
| Build Tool | Maven (or manual classpath) |
| Authentication | Session-based + Google OAuth 2.0 |
| Payments | Razorpay, UPI QR Code |
| SMS | Twilio |
| Email | JavaMail (Gmail SMTP) |
| AI Chat | Anthropic Claude API |

---

## Project Structure

```
SIBS-APP/
├── .env                          # Local secrets — never commit
├── .env.example                  # Safe template to commit
├── .gitignore
└── main/
    ├── java/
    │   └── com/
    │       ├── DAO/              # Data Access Objects (one per entity)
    │       │   ├── UserDAO.java
    │       │   ├── CustomerDAO.java
    │       │   ├── OrderDAO.java
    │       │   ├── ProductDAO.java
    │       │   ├── AttendanceDAO.java
    │       │   ├── DeliverySlotDAO.java
    │       │   └── ...           # 20 DAO classes total
    │       ├── servlet/          # Jakarta Servlets (one per feature)
    │       │   ├── LoginServlet.java
    │       │   ├── GoogleLoginServlet.java
    │       │   ├── CustomerDashboardServlet.java
    │       │   ├── OrderServlet.java
    │       │   ├── AIChatServlet.java
    │       │   ├── AttendanceServlet.java
    │       │   └── ...           # 80+ servlet classes total
    │       ├── filter/
    │       │   └── AuthFilter.java       # Role-based access control
    │       ├── listener/
    │       │   ├── AttendanceSweepScheduler.java   # Auto punch-out scheduler
    │       │   └── MissedPunchOutListener.java
    │       └── util/             # Model classes and utility helpers
    │           ├── DBConnection.java
    │           ├── EmailUtil.java
    │           ├── OTPUtil.java
    │           ├── User.java
    │           ├── Order.java
    │           ├── Product.java
    │           └── ...           # 30 utility/model classes
    └── webapp/
        ├── WEB-INF/
        │   └── web.xml           # App config (uses env var placeholders)
        ├── index.jsp             # Landing page
        ├── login.jsp / register.jsp
        ├── CustomerLogin.jsp / CustomerRegistration.jsp
        ├── customerDashboard.jsp
        ├── dashboard.jsp         # Admin dashboard
        ├── staffDashboard.jsp
        ├── DeliveryPortal.jsp
        ├── stocksDashboard.jsp
        ├── reportsDashboard.jsp
        └── ...                   # 70+ JSP pages total
```

---

## Prerequisites

- Java 17 or higher
- Apache Tomcat 10.1+
- MySQL 8.0+
- Maven 3.8+ (if using Maven build)
- A Google Cloud project with OAuth 2.0 credentials
- Twilio account (for SMS OTP)
- Gmail account with an App Password (for email)
- Razorpay account (for payment processing)
- Anthropic API key (for AI chat)

---

## Setup & Installation

**1. Clone the repository**
```bash
git clone git@github.com:nandithamadhav23-cmyk/SIBS-APP.git
cd SIBS-APP
```

**2. Set up environment variables**
```bash
cp .env.example .env
# Edit .env and fill in all your real credentials
```

**3. Set up the database**
```bash
mysql -u root -p
CREATE DATABASE myapp;
USE myapp;
# Import the schema:
source schema.sql;
```

**4. Update DB credentials**

Open `main/java/com/util/DBConnection.java` and update the connection URL, username, and password to match your MySQL setup, or better yet, load them from environment variables:
```java
String URL      = System.getenv().getOrDefault("DB_URL",  "jdbc:mysql://localhost:3306/myapp");
String USER     = System.getenv().getOrDefault("DB_USER", "root");
String PASSWORD = System.getenv("DB_PASSWORD");
```

**5. Create persistent image directory**
```bash
mkdir -p /opt/sibs-store/product-images
```
Update `productImageDir` in `web.xml` if you use a different path.

**6. Build and deploy**

If using Maven:
```bash
mvn clean package
cp target/SampleApp.war /path/to/tomcat/webapps/
```

If using Eclipse:
- Import as a Dynamic Web Project
- Right-click → Run on Server → Select Tomcat 10

---

## Environment Variables

Copy `.env.example` to `.env` and fill in real values. The application reads these at runtime.

| Variable | Description |
|---|---|
| `GOOGLE_CLIENT_ID` | Google OAuth 2.0 Client ID |
| `GOOGLE_CLIENT_SECRET` | Google OAuth 2.0 Client Secret |
| `RAZORPAY_KEY_ID` | Razorpay API Key ID |
| `RAZORPAY_KEY_SECRET` | Razorpay API Key Secret |
| `MAIL_SMTP_HOST` | SMTP host (default: `smtp.gmail.com`) |
| `MAIL_SMTP_PORT` | SMTP port (default: `587`) |
| `MAIL_SMTP_USER` | Sender email address |
| `MAIL_SMTP_PASSWORD` | Gmail App Password (not your login password) |
| `TWILIO_ACCOUNT_SID` | Twilio Account SID |
| `TWILIO_AUTH_TOKEN` | Twilio Auth Token |
| `ANTHROPIC_API_KEY` | Anthropic Claude API key |

> ⚠️ **Never hardcode these values in source files.** The `.env` file is excluded from git via `.gitignore`.

---

## Database Configuration

The app connects to a MySQL database named `myapp` on `localhost:3306` by default. Connection is managed in `com/util/DBConnection.java`.

To use a different database name or host, update the JDBC URL:
```
jdbc:mysql://<host>:<port>/<dbname>?tinyInt1isBit=false
```

The `tinyInt1isBit=false` flag ensures `TINYINT(1)` columns are treated as integers, not booleans.

---

## Running the Application

Once deployed to Tomcat, navigate to:

```
http://localhost:8085/SampleApp/
```

Default routes:
- `/` or `/index.jsp` — Customer landing page
- `/login.jsp` — Staff/Admin login
- `/CustomerLogin.jsp` — Customer login
- `/deliveryLogin.jsp` — Delivery agent login
- `/register.jsp` — Staff registration
- `/CustomerRegistration.jsp` — Customer registration

---

## User Roles

| Role | Access |
|---|---|
| **Admin** | Full access — users, products, stock, reports, leaves, attendance, notifications |
| **Staff** | Product management, orders, stock, attendance, AI assistant |
| **Customer** | Browse, cart, checkout, orders, wallet, returns, help desk |
| **Delivery Agent** | Delivery portal, assigned orders, slot management, earnings wallet |

Role-based access is enforced by `AuthFilter.java`, which intercepts all requests and checks the session for the appropriate role attribute.

---

## Key Modules

### Authentication
- Session-based login for Staff, Admin, and Delivery agents
- Separate customer login with Google OAuth 2.0 support
- OTP verification via Twilio SMS on registration/forgot password
- Password reset via email link

### Order Management
- Full order lifecycle: place → assign → dispatch → deliver → return
- Delivery slot booking with time-window validation
- COD and prepaid payment flows
- Invoice generation and download

### Inventory & Stock
- Product CRUD with persistent image storage
- Stock dashboard with low-stock visibility
- Stock API endpoint for real-time checks

### Payments
- Razorpay integration for card/net banking/UPI
- UPI QR code generation
- Internal wallet system for customers and delivery agents
- COD deposit tracking for agents

### Attendance
- Punch-in/punch-out with shift window validation
- Auto-sweep scheduler to mark missed punch-outs
- Leave request and approval workflow with document upload
- Attendance reports per employee

### AI Chat
- Customer-facing AI chat powered by Anthropic Claude
- Staff AI assistant for internal queries
- Context-aware: passes cart, order, and profile data to the model

### Notifications
- Real-time unread count polling
- Role-specific notification feeds (Admin, Staff, Customer, Delivery)
- Mark-as-read support

---

## API Integrations

### Google OAuth 2.0
Handled by `GoogleLoginServlet.java`. The servlet initiates the authorization flow, handles the callback, exchanges the code for an access token, fetches the user profile, and creates or retrieves the customer record.

**Setup:**
1. Go to [console.cloud.google.com](https://console.cloud.google.com)
2. Create a project → Enable Google Identity API
3. Create OAuth 2.0 credentials → Web application
4. Add Authorized Redirect URI: `http://localhost:8085/SampleApp/GoogleCallback`
5. Set `GOOGLE_CLIENT_ID` and `GOOGLE_CLIENT_SECRET` in `.env`

### Razorpay
Used for card, net banking, and UPI payments. Orders are created server-side via `CreateRazorpayOrderServlet` and verified after payment in `PaymentServlet`.

### Twilio
Used to send OTP SMS during customer registration and password reset. Configured via `TWILIO_ACCOUNT_SID` and `TWILIO_AUTH_TOKEN`.

### Gmail SMTP
Transactional emails (OTPs, order confirmations, invoices) are sent via JavaMail using a Gmail App Password. See `EmailUtil.java`.

### Anthropic Claude
AI chat for customers and staff is powered by the Claude API. The `AIChatServlet` and `StaffAIChatServlet` send context-enriched prompts and stream responses back to the UI.

---

## Security Notes

- All secrets are stored in environment variables, never in source code
- The `.env` file is excluded from version control via `.gitignore`
- CSRF protection is implemented in the Google OAuth flow using a state token
- `AuthFilter` enforces role-based access on all protected routes
- Passwords are not stored in plaintext (ensure hashing is applied in `UserDAO`)
- SQL injection is prevented throughout via `PreparedStatement`

> If you are rotating credentials after a potential exposure, regenerate all keys listed in the [Environment Variables](#environment-variables) section before deploying.
