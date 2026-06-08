package com.util;

import java.math.BigDecimal;

/**
 * AgentWallet — Represents an agent's wallet state.
 *
 * FIELDS EXPLAINED (real-world model):
 *
 * balance = total money sitting in the wallet (earned fees + staff top-ups)
 * Does NOT include COD cash that hasn't been remitted yet.
 *
 * codFloat = amount currently frozen because agent is holding COD cash. Agent
 * physically has this cash in hand; it's frozen in the wallet as a security
 * marker until they deposit it at the hub.
 *
 * availableBalance = balance - codFloat - minBalance The actual amount the
 * agent can withdraw or use. Always >= 0.
 *
 * minBalance = mandatory security deposit (e.g. ₹500). Agent must always
 * maintain this. Prevents them from fully draining the wallet and then
 * collecting COD cash and disappearing.
 *
 * totalEarned = cumulative delivery fees + bonuses since account creation.
 *
 * totalWithdrawn = cumulative withdrawals since account creation.
 *
 * healthy = true when (balance - codFloat) >= minBalance. Unhealthy agents
 * cannot accept new COD orders.
 */
public class AgentWallet {
	private int id;
	private int agentId;
	private BigDecimal balance;
	private BigDecimal codFloat;
	private double availableBalance;
	private BigDecimal minBalance;
	private BigDecimal totalEarned;
	private double totalWithdrawn;
	private boolean healthy;

	// Getters / Setters
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

	public BigDecimal getBalance() {
		return balance;
	}

	public void setBalance(BigDecimal bigDecimal) {
		this.balance = bigDecimal;
	}

	public BigDecimal getCodFloat() {
		return codFloat;
	}

	public void setCodFloat(BigDecimal codFloat) {
		this.codFloat = codFloat;
	}

	public double getAvailableBalance() {
		return availableBalance;
	}

	public void setAvailableBalance(double availableBalance) {
		this.availableBalance = availableBalance;
	}

	public BigDecimal getMinBalance() {
		return minBalance;
	}

	public void setMinBalance(BigDecimal minBalance) {
		this.minBalance = minBalance;
	}

	public BigDecimal getTotalEarned() {
		return totalEarned;
	}

	public void setTotalEarned(BigDecimal totalEarned) {
		this.totalEarned = totalEarned;
	}

	public double getTotalWithdrawn() {
		return totalWithdrawn;
	}

	public void setTotalWithdrawn(double totalWithdrawn) {
		this.totalWithdrawn = totalWithdrawn;
	}

	public boolean isHealthy() {
		return healthy;
	}

	public void setHealthy(boolean healthy) {
		this.healthy = healthy;
	}

	/**
	 * Cash in hand = codFloat (the agent physically holds this much COD cash to
	 * remit)
	 */
	public BigDecimal getCashInHand() {
		return codFloat;
	}

	/** Net earnings available to withdraw */
	public BigDecimal getWithdrawable() {
		// Ensures balance, codFloat, and minBalance are not null before computation
		BigDecimal currentBalance = (balance != null) ? balance : BigDecimal.ZERO;
		BigDecimal floatAmount = (codFloat != null) ? codFloat : BigDecimal.ZERO;
		BigDecimal minimumRequired = (minBalance != null) ? minBalance : BigDecimal.ZERO;

		// Formula: balance - codFloat - minBalance
		BigDecimal withdrawable = currentBalance.subtract(floatAmount).subtract(minimumRequired);

		// Returns the calculated amount, or BigDecimal.ZERO if it falls below zero
		// (Math.max logic)
		return withdrawable.compareTo(BigDecimal.ZERO) > 0 ? withdrawable : BigDecimal.ZERO;
	}
}