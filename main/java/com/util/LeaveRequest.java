package com.util;

import java.sql.Date;
import java.sql.Timestamp;
import java.math.BigDecimal;

/**
 * POJO representing a row in leave_requests + joined fields.
 */
public class LeaveRequest {

    // ── Core fields ───────────────────────────────────────────
    private int       id;
    private String    username;
    private int       leaveTypeId;
    private String    leaveTypeName;   // joined from leave_types
    private boolean   isPaid;          // joined from leave_types

    private Date      fromDate;
    private Date      toDate;
    private BigDecimal totalDays;
    private String    sessionType;     // full_day / first_half / second_half

    private String    reason;
    private String    contactDuringLeave;
    private String    workHandover;
    private String    coveringPerson;
    private String    documentPath;

    private String    status;          // pending / approved / rejected / cancelled / revoked
    private Timestamp appliedOn;

    // ── Review fields ─────────────────────────────────────────
    private String    reviewedBy;
    private Timestamp reviewedOn;
    private String    reviewerNote;

    // ── Cancellation fields ───────────────────────────────────
    private Timestamp cancelledOn;
    private String    cancelReason;

    // ── Balance snapshot (transient — shown on form) ──────────
    private BigDecimal balanceAvailable;

    // ─────────────────────────────────────────────────────────
    //  Getters & Setters
    // ─────────────────────────────────────────────────────────

    public int getId() { return id; }
    public void setId(int id) { this.id = id; }

    public String getUsername() { return username; }
    public void setUsername(String username) { this.username = username; }

    public int getLeaveTypeId() { return leaveTypeId; }
    public void setLeaveTypeId(int leaveTypeId) { this.leaveTypeId = leaveTypeId; }

    public String getLeaveTypeName() { return leaveTypeName; }
    public void setLeaveTypeName(String leaveTypeName) { this.leaveTypeName = leaveTypeName; }

    public boolean isPaid() { return isPaid; }
    public void setPaid(boolean paid) { isPaid = paid; }

    public Date getFromDate() { return fromDate; }
    public void setFromDate(Date fromDate) { this.fromDate = fromDate; }

    public Date getToDate() { return toDate; }
    public void setToDate(Date toDate) { this.toDate = toDate; }

    public BigDecimal getTotalDays() { return totalDays; }
    public void setTotalDays(BigDecimal totalDays) { this.totalDays = totalDays; }

    public String getSessionType() { return sessionType; }
    public void setSessionType(String sessionType) { this.sessionType = sessionType; }

    public String getReason() { return reason; }
    public void setReason(String reason) { this.reason = reason; }

    public String getContactDuringLeave() { return contactDuringLeave; }
    public void setContactDuringLeave(String contactDuringLeave) { this.contactDuringLeave = contactDuringLeave; }

    public String getWorkHandover() { return workHandover; }
    public void setWorkHandover(String workHandover) { this.workHandover = workHandover; }

    public String getCoveringPerson() { return coveringPerson; }
    public void setCoveringPerson(String coveringPerson) { this.coveringPerson = coveringPerson; }

    public String getDocumentPath() { return documentPath; }
    public void setDocumentPath(String documentPath) { this.documentPath = documentPath; }

    public String getStatus() { return status; }
    public void setStatus(String status) { this.status = status; }

    public Timestamp getAppliedOn() { return appliedOn; }
    public void setAppliedOn(Timestamp appliedOn) { this.appliedOn = appliedOn; }

    public String getReviewedBy() { return reviewedBy; }
    public void setReviewedBy(String reviewedBy) { this.reviewedBy = reviewedBy; }

    public Timestamp getReviewedOn() { return reviewedOn; }
    public void setReviewedOn(Timestamp reviewedOn) { this.reviewedOn = reviewedOn; }

    public String getReviewerNote() { return reviewerNote; }
    public void setReviewerNote(String reviewerNote) { this.reviewerNote = reviewerNote; }

    public Timestamp getCancelledOn() { return cancelledOn; }
    public void setCancelledOn(Timestamp cancelledOn) { this.cancelledOn = cancelledOn; }

    public String getCancelReason() { return cancelReason; }
    public void setCancelReason(String cancelReason) { this.cancelReason = cancelReason; }

    public BigDecimal getBalanceAvailable() { return balanceAvailable; }
    public void setBalanceAvailable(BigDecimal balanceAvailable) { this.balanceAvailable = balanceAvailable; }

    /** Convenience: number of working days calculated server-side */
    public String getStatusBadgeClass() {
        if (status == null) return "badge-pending";
        return switch (status.toLowerCase()) {
            case "approved"  -> "badge-approved";
            case "rejected"  -> "badge-rejected";
            case "cancelled" -> "badge-cancelled";
            case "revoked"   -> "badge-revoked";
            default          -> "badge-pending";
        };
    }
}
