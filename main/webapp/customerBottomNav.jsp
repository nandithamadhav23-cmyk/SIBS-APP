<%-- =====================================================================
     customerBottomNav.jsp  —  Shared Mobile Bottom Navigation
     Include with:  <jsp:include page="customerBottomNav.jsp" />
     Pass   activePage="home|orders|cart|notifications|profile"
     via    <jsp:param name="activePage" value="home"/>
     ===================================================================== --%>
<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%
    String activePage = request.getParameter("activePage");
    if (activePage == null) activePage = "";
    Object cartCountObj = session.getAttribute("cartCount");
    int cartCount = (cartCountObj instanceof Integer) ? (Integer) cartCountObj : 0;
    Boolean loggedIn = (Boolean) session.getAttribute("loggedIn");

    Object unreadObj = session.getAttribute("unreadNotifCount");
    if (unreadObj == null) unreadObj = request.getAttribute("unreadNotifCount");
    int unreadNotif = (unreadObj instanceof Integer) ? (Integer) unreadObj : 0;
%>
<style>
/* ── BOTTOM NAV SHARED STYLES ── */
.cbn-nav {
  display: none;
  position: fixed; bottom: 0; left: 0; right: 0; z-index: 1050;
  background: #0f3460;
  border-top: 2px solid rgba(255,255,255,0.08);
  height: 62px;
  box-shadow: 0 -4px 24px rgba(0,0,0,0.22);
}
.cbn-inner {
  display: grid;
  grid-template-columns: repeat(5, 1fr);
  height: 100%;
  align-items: stretch;
}
.cbn-item {
  display: flex; flex-direction: column; align-items: center; justify-content: center;
  gap: 2px; text-decoration: none; color: rgba(255,255,255,0.55);
  font-size: 0.58rem; font-weight: 700; letter-spacing: 0.3px; text-transform: uppercase;
  border: none; background: none; cursor: pointer; padding: 0.25rem 0;
  transition: color 0.2s; position: relative;
}
.cbn-item i { font-size: 1.2rem; }
.cbn-item.active { color: #fff; }
.cbn-item.active i { color: #e94560; }
.cbn-badge {
  position: absolute; top: 3px; left: 50%; transform: translateX(4px);
  background: #e94560; color: #fff; font-size: 0.55rem; font-weight: 700;
  min-width: 15px; height: 15px; border-radius: 50%;
  display: flex; align-items: center; justify-content: center;
  border: 1.5px solid #0f3460;
  line-height: 1;
}
@media (max-width: 768px) { .cbn-nav { display: block; } }
</style>

<nav class="cbn-nav">
  <div class="cbn-inner">
    <a href="Customer" class="cbn-item <%= "home".equals(activePage) ? "active" : "" %>">
      <i class="bi bi-house-fill"></i>Home
    </a>
    <a href="CustomerOrdersServlet" class="cbn-item <%= "orders".equals(activePage) ? "active" : "" %>">
      <i class="bi bi-box-seam-fill"></i>Orders
    </a>
    <a href="CartServlet?action=view" class="cbn-item <%= "cart".equals(activePage) ? "active" : "" %>">
      <i class="bi bi-bag-fill"></i>Cart
      <% if (cartCount > 0) { %>
      <span class="cbn-badge"><%= cartCount > 9 ? "9+" : cartCount %></span>
      <% } %>
    </a>
    <a href="CustomerNotifications" class="cbn-item <%= "notifications".equals(activePage) ? "active" : "" %>">
      <i class="bi bi-bell-fill"></i>Alerts
      <% if (unreadNotif > 0) { %>
      <span class="cbn-badge"><%= unreadNotif > 9 ? "9+" : unreadNotif %></span>
      <% } %>
    </a>
    <% if (Boolean.TRUE.equals(loggedIn)) { %>
    <a href="CustomerProfile" class="cbn-item <%= "profile".equals(activePage) ? "active" : "" %>">
      <i class="bi bi-person-circle"></i>Me
    </a>
    <% } else { %>
    <a href="CustomerLogin.jsp" class="cbn-item">
      <i class="bi bi-box-arrow-in-right"></i>Login
    </a>
    <% } %>
  </div>
</nav>
