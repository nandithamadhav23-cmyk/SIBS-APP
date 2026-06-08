package com.util;

import java.math.BigDecimal;
import java.sql.Timestamp;

/**
 * AgentWalletTransaction — One row from agent_wallet_transactions.
 *
 * TYPE MEANINGS: credit = staff manually credited funds (top-up, bonus)
 * delivery_fee = automatic credit after order delivered cod_hold = COD amount
 * frozen when agent picks up COD order cod_release = COD hold unfrozen when
 * delivery confirmed cod_collected = informational: agent physically collected
 * cash from customer cod_remitted = agent deposited cash at hub (balance
 * reduced) withdrawal = agent withdrew earnings to bank account bonus =
 * performance bonus from staff adjustment = manual correction by staff
 */
public class AgentWalletTransaction {
	private int id;
	private int agentId;
	private int orderId; // 0 if not order-related
	private String type;
	private String typeLabel; // human-friendly label
	private double amount;
	private double balanceAfter;
	private BigDecimal codFloat;
	private String description;
	private Timestamp createdAt;
	private boolean credit; // true = money in, false = money out / freeze

	public int getId() {
		return id;
	}

	public void setId(int id) {
		this.id = id;
	}

	public int getAgentId() {
		return agentId;
	}

	public void setAgentId(int agentId) {
		this.agentId = agentId;
	}

	public int getOrderId() {
		return orderId;
	}

	public void setOrderId(int orderId) {
		this.orderId = orderId;
	}

	public String getType() {
		return type;
	}

	public void setType(String type) {
		this.type = type;
	}

	public String getTypeLabel() {
		return typeLabel;
	}

	public void setTypeLabel(String typeLabel) {
		this.typeLabel = typeLabel;
	}

	public double getAmount() {
		return amount;
	}

	public void setAmount(double amount) {
		this.amount = amount;
	}

	public double getBalanceAfter() {
		return balanceAfter;
	}

	public void setBalanceAfter(double balanceAfter) {
		this.balanceAfter = balanceAfter;
	}

	public String getDescription() {
		return description;
	}

	public void setDescription(String description) {
		this.description = description;
	}

	public Timestamp getCreatedAt() {
		return createdAt;
	}

	public void setCreatedAt(Timestamp createdAt) {
		this.createdAt = createdAt;
	}

	public boolean isCredit() {
		return credit;
	}

	public void setCredit(boolean credit) {
		this.credit = credit;
	}

	public BigDecimal getCodFloat() {
		return codFloat;
	}

	public void setCodFloat(BigDecimal codFloat) {
		this.codFloat = codFloat;
	}
}