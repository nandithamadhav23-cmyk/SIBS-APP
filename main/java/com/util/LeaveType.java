package com.util;

import java.math.BigDecimal;

/**
 * Represents a row in leave_types, with the employee's current balance merged in.
 */
public class LeaveType {
    private int     id;
    private String  typeName;
    private int     maxDays;
    private boolean isPaid;
    private boolean requiresDoc;
    private boolean carryForward;
    private String  description;

    // Employee-specific balance (populated per user from leave_balances)
    private BigDecimal totalAllotted;
    private BigDecimal usedDays;
    private BigDecimal carriedDays;

    // ── Getters & Setters ──────────────────────────────────────
    public int getId() { return id; }
    public void setId(int id) { this.id = id; }

    public String getTypeName() { return typeName; }
    public void setTypeName(String typeName) { this.typeName = typeName; }

    public int getMaxDays() { return maxDays; }
    public void setMaxDays(int maxDays) { this.maxDays = maxDays; }

    public boolean isPaid() { return isPaid; }
    public void setPaid(boolean paid) { isPaid = paid; }

    public boolean isRequiresDoc() { return requiresDoc; }
    public void setRequiresDoc(boolean requiresDoc) { this.requiresDoc = requiresDoc; }

    public boolean isCarryForward() { return carryForward; }
    public void setCarryForward(boolean carryForward) { this.carryForward = carryForward; }

    public String getDescription() { return description; }
    public void setDescription(String description) { this.description = description; }

    public BigDecimal getTotalAllotted() { return totalAllotted; }
    public void setTotalAllotted(BigDecimal totalAllotted) { this.totalAllotted = totalAllotted; }

    public BigDecimal getUsedDays() { return usedDays; }
    public void setUsedDays(BigDecimal usedDays) { this.usedDays = usedDays; }

    public BigDecimal getCarriedDays() { return carriedDays; }
    public void setCarriedDays(BigDecimal carriedDays) { this.carriedDays = carriedDays; }

    /** Available = total + carry − used */
    public BigDecimal getAvailable() {
        BigDecimal total   = totalAllotted  != null ? totalAllotted  : BigDecimal.ZERO;
        BigDecimal used    = usedDays       != null ? usedDays       : BigDecimal.ZERO;
        BigDecimal carried = carriedDays    != null ? carriedDays    : BigDecimal.ZERO;
        return total.add(carried).subtract(used);
    }
}
