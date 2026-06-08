<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8"%>
<%
    String _role  = (session != null) ? (String) session.getAttribute("role") : null;
    if (_role == null || !"admin".equalsIgnoreCase(_role)) {
        out.print("<p style='color:#e74c3c;font-family:Times New Roman;padding:2rem;'>"
                + "<i class='bi bi-lock me-2'></i>Access denied.</p>");
        return;
    }
%>
<%-- ═══════════════════════════════════════════════════════════════════════════
     productDashboard.jsp
     Loaded as an AJAX fragment into dashboard.jsp#mainContent — NO <html>/<body>.
     Uses CSS variables from dashboard.jsp :root block.
     Adds tooltips on all action buttons, full mobile layout, and polished theme.
═══════════════════════════════════════════════════════════════════════════ --%>

<style>
/* ── Fragment-scoped ─────────────────────────────────────────────────────── */

.pd-header {
    display: flex;
    align-items: flex-start;
    justify-content: space-between;
    flex-wrap: wrap;
    gap: 1rem;
    margin-bottom: 2rem;
    padding-bottom: 1.2rem;
    border-bottom: 2px solid var(--border);
}
.pd-title {
    font-family: 'Times New Roman', Times, serif;
    font-size: 1.5rem;
    font-weight: 700;
    color: var(--text-dark);
    margin: 0 0 0.25rem;
    display: flex;
    align-items: center;
    gap: 0.55rem;
}
.pd-title i { color: var(--accent); }
.pd-subtitle {
    font-family: 'Times New Roman', Times, serif;
    font-size: 0.83rem;
    color: var(--text-muted);
}

/* ── Grid ────────────────────────────────────────────────────────────────── */
.pd-grid {
    display: grid;
    grid-template-columns: repeat(3, 1fr);
    gap: 1.4rem;
}

/* ── Cards ───────────────────────────────────────────────────────────────── */
.pd-card {
    background: var(--bg-white);
    border: 1px solid var(--border);
    border-radius: 6px;
    padding: 2.2rem 1.6rem 1.8rem;
    text-align: center;
    position: relative;
    overflow: hidden;
    transition: transform 0.25s ease, box-shadow 0.25s ease;
    display: flex;
    flex-direction: column;
    align-items: center;
}
.pd-card::before {
    content: '';
    position: absolute;
    top: 0; left: 0; right: 0;
    height: 4px;
    transform: scaleX(0);
    transform-origin: left;
    transition: transform 0.3s ease;
}
.pd-card:hover {
    transform: translateY(-6px);
    box-shadow: 0 8px 28px rgba(26,26,46,0.13);
}
.pd-card:hover::before { transform: scaleX(1); }
.pd-card:hover .pd-icon { transform: scale(1.08); }

.pd-card.c-green::before  { background: #27ae60; }
.pd-card.c-teal::before   { background: #17a2b8; }
.pd-card.c-purple::before { background: #6f42c1; }

/* ── Icon circles ─────────────────────────────────────────────────────────── */
.pd-icon {
    width: 70px; height: 70px;
    border-radius: 50%;
    display: flex; align-items: center; justify-content: center;
    margin: 0 auto 1.3rem;
    font-size: 1.75rem;
    flex-shrink: 0;
    transition: transform 0.2s ease;
}
.pd-icon.g  { background: #e8f8f0; color: #27ae60; }
.pd-icon.t  { background: #e0f7fa; color: #17a2b8; }
.pd-icon.p  { background: #ede7f6; color: #6f42c1; }

.pd-card-title {
    font-family: 'Times New Roman', Times, serif;
    font-size: 1.08rem;
    font-weight: 700;
    color: var(--text-dark);
    margin-bottom: 0.55rem;
}
.pd-card-desc {
    font-family: 'Times New Roman', Times, serif;
    font-size: 0.86rem;
    color: var(--text-muted);
    line-height: 1.65;
    margin-bottom: 1.4rem;
    flex-grow: 1;
}

/* ── Buttons ─────────────────────────────────────────────────────────────── */
.pd-btn {
    font-family: 'Times New Roman', Times, serif;
    font-size: 0.77rem;
    letter-spacing: 1.1px;
    text-transform: uppercase;
    padding: 0.52rem 1.5rem;
    border-radius: 3px;
    text-decoration: none;
    display: inline-flex;
    align-items: center;
    gap: 0.4rem;
    transition: background 0.2s, color 0.2s, transform 0.15s;
    border: 2px solid transparent;
    cursor: pointer;
    white-space: nowrap;
    position: relative;
}
.pd-btn:hover { transform: translateY(-1px); }
.pd-btn:active { transform: translateY(0); }

.pd-btn.g  { background: #27ae60; color: #fff; border-color: #27ae60; }
.pd-btn.g:hover  { background: transparent; color: #27ae60; }
.pd-btn.t  { background: #17a2b8; color: #fff; border-color: #17a2b8; }
.pd-btn.t:hover  { background: transparent; color: #17a2b8; }
.pd-btn.p  { background: #6f42c1; color: #fff; border-color: #6f42c1; }
.pd-btn.p:hover  { background: transparent; color: #6f42c1; }

/* ── Tooltips ────────────────────────────────────────────────────────────── */
.pd-btn[data-tip] { position: relative; }
.pd-btn[data-tip]::after {
    content: attr(data-tip);
    position: absolute;
    bottom: calc(100% + 8px);
    left: 50%;
    transform: translateX(-50%) scale(0.9);
    background: var(--primary);
    color: #fff;
    font-family: 'Times New Roman', Times, serif;
    font-size: 0.72rem;
    white-space: nowrap;
    padding: 0.35rem 0.7rem;
    border-radius: 3px;
    pointer-events: none;
    opacity: 0;
    transition: opacity 0.18s ease, transform 0.18s ease;
    z-index: 99;
    text-transform: none;
    letter-spacing: 0.3px;
}
.pd-btn[data-tip]::before {
    content: '';
    position: absolute;
    bottom: calc(100% + 2px);
    left: 50%;
    transform: translateX(-50%) scale(0.9);
    border: 5px solid transparent;
    border-top-color: var(--primary);
    pointer-events: none;
    opacity: 0;
    transition: opacity 0.18s ease, transform 0.18s ease;
    z-index: 99;
}
.pd-btn[data-tip]:hover::after,
.pd-btn[data-tip]:hover::before {
    opacity: 1;
    transform: translateX(-50%) scale(1);
}

/* ── Responsive ──────────────────────────────────────────────────────────── */
@media (max-width: 900px) {
    .pd-grid { grid-template-columns: repeat(2, 1fr); }
}
@media (max-width: 560px) {
    .pd-grid { grid-template-columns: 1fr; }
    .pd-header { flex-direction: column; gap: 0.4rem; }
    .pd-btn { font-size: 0.72rem; padding: 0.48rem 1rem; }
}
</style>

<!-- ── Page Header ─────────────────────────────────────────────────────────── -->
<div class="pd-header">
    <div>
        <h1 class="pd-title">
            <i class="bi bi-box-seam"></i> Product Dashboard
        </h1>
        <p class="pd-subtitle">Manage your catalogue, inventory levels, and customer-facing product portal.</p>
    </div>
</div>

<!-- ── Cards ──────────────────────────────────────────────────────────────── -->
<div class="pd-grid">

    <!-- Add Product -->
    <div class="pd-card c-green">
        <div class="pd-icon g"><i class="bi bi-plus-circle-fill"></i></div>
        <h5 class="pd-card-title">Add Product</h5>
        <p class="pd-card-desc">Add a new item to the inventory with full details — pricing, category, stock quantity, and images.</p>
        <a href="ProductServlet?action=add" class="pd-btn g"
           data-tip="Open the add-product form">
            <i class="bi bi-plus-circle"></i> Add Product
        </a>
    </div>

    <!-- View Products -->
    <div class="pd-card c-teal">
        <div class="pd-icon t"><i class="bi bi-eye-fill"></i></div>
        <h5 class="pd-card-title">View Products</h5>
        <p class="pd-card-desc">Browse the full product catalogue, adjust stock levels, edit details, and manage availability.</p>
        <a href="ProductServlet" class="pd-btn t"
           data-tip="See all products in the catalogue">
            <i class="bi bi-list-ul"></i> View Products
        </a>
    </div>

    <!-- Customer Portal -->
    <div class="pd-card c-purple">
        <div class="pd-icon p"><i class="bi bi-people-fill"></i></div>
        <h5 class="pd-card-title">Customer Portal</h5>
        <p class="pd-card-desc">Open the customer-facing dashboard to manage orders, saved addresses, and account preferences.</p>
        <a href="customerDashboard.jsp" class="pd-btn p"
           data-tip="Switch to the customer-facing portal">
            <i class="bi bi-box-arrow-in-right"></i> Go to Portal
        </a>
    </div>

</div>
