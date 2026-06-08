package com.util;

import java.sql.Timestamp;

/**
 * SupportTicket — bean matching the support_tickets table.
 * Includes transient enrichment fields (customerName/Email/Phone)
 * populated by TicketDAO.getOpenTickets() JOIN.
 */
public class SupportTicket {

    private int       ticketId;
    private int       customerId;
    private int       chatSessionId;
    private String    category;
    private String    subject;
    private String    description;
    private String    status;       // open | in_progress | waiting_customer | resolved | closed
    private String    priority;     // low | normal | high | urgent
    private String    assignedTo;
    private String    staffReply;
    private int       refOrderId;
    private Timestamp createdAt;
    private Timestamp updatedAt;
    private Timestamp resolvedAt;

    // Transient — populated by JOIN query in staff view
    private String customerName;
    private String customerEmail;
    private String customerPhone;

    // ── Getters & Setters ────────────────────────────────────────────────────

    public int getTicketId() { return ticketId; }
    public void setTicketId(int v) { ticketId = v; }

    public int getCustomerId() { return customerId; }
    public void setCustomerId(int v) { customerId = v; }

    public int getChatSessionId() { return chatSessionId; }
    public void setChatSessionId(int v) { chatSessionId = v; }

    public String getCategory() { return category; }
    public void setCategory(String v) { category = v; }

    public String getSubject() { return subject; }
    public void setSubject(String v) { subject = v; }

    public String getDescription() { return description; }
    public void setDescription(String v) { description = v; }

    public String getStatus() { return status; }
    public void setStatus(String v) { status = v; }

    public String getPriority() { return priority; }
    public void setPriority(String v) { priority = v; }

    public String getAssignedTo() { return assignedTo; }
    public void setAssignedTo(String v) { assignedTo = v; }

    public String getStaffReply() { return staffReply; }
    public void setStaffReply(String v) { staffReply = v; }

    public int getRefOrderId() { return refOrderId; }
    public void setRefOrderId(int v) { refOrderId = v; }

    public Timestamp getCreatedAt() { return createdAt; }
    public void setCreatedAt(Timestamp v) { createdAt = v; }

    public Timestamp getUpdatedAt() { return updatedAt; }
    public void setUpdatedAt(Timestamp v) { updatedAt = v; }

    public Timestamp getResolvedAt() { return resolvedAt; }
    public void setResolvedAt(Timestamp v) { resolvedAt = v; }

    public String getCustomerName() { return customerName; }
    public void setCustomerName(String v) { customerName = v; }

    public String getCustomerEmail() { return customerEmail; }
    public void setCustomerEmail(String v) { customerEmail = v; }

    public String getCustomerPhone() { return customerPhone; }
    public void setCustomerPhone(String v) { customerPhone = v; }

    // ── Helpers ──────────────────────────────────────────────────────────────

    /** Display label for the category enum value. */
    public String getCategoryLabel() {
        if (category == null) return "Other";
        return switch (category) {
            case "order"        -> "📦 Order issue";
            case "cancellation" -> "✕ Cancel / Refund";
            case "return"       -> "↩ Return / Replace";
            case "payment"      -> "💳 Payment";
            case "delivery"     -> "🚚 Delivery";
            case "product"      -> "🛍 Product quality";
            case "account"      -> "👤 My account";
            default             -> "💬 Other";
        };
    }

    /** Human-readable status for display in JSP. */
    public String getStatusLabel() {
        if (status == null) return "Open";
        return switch (status) {
            case "open"             -> "Open";
            case "in_progress"      -> "In progress";
            case "waiting_customer" -> "Staff replied";
            case "resolved"         -> "Resolved";
            case "closed"           -> "Closed";
            default                 -> status;
        };
    }

    /** CSS class suffix for status badge colouring in JSP. */
    public String getStatusCss() {
        if (status == null) return "open";
        return switch (status) {
            case "resolved", "closed"   -> "resolved";
            case "waiting_customer"     -> "replied";
            case "in_progress"          -> "inprogress";
            default                     -> "open";
        };
    }

    public boolean isResolved() {
        return "resolved".equals(status) || "closed".equals(status);
    }
}
