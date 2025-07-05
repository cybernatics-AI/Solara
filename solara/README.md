# 🌞 Solara

**Solara** is a Clarity smart contract for managing decentralized, fractional ownership of solar farms. It enables cooperative investment in solar energy infrastructure, revenue sharing among contributors, and a transparent governance system for upgrades and proposals.

---

## 🔆 Key Features

* **Farm Installation:** Grid operators can install and register new solar farms with predefined parameters like location, number of panels, price per panel, and expected monthly revenue.
* **Fractional Ownership:** Members can buy solar panels and own a share of a farm’s revenue.
* **Automated Revenue Sharing:** Monthly energy revenue is distributed proportionally to each member’s ownership.
* **Claim Mechanism:** Members can claim their revenue share for any active farm and valid month.
* **Upgrade Proposals:** Panel holders can propose and vote on farm upgrades (e.g., hardware or efficiency improvements).
* **Voting Power by Stake:** Upgrade votes are weighted by the number of panels owned.
* **Governance Transparency:** Voting deadlines, counts, and upgrade implementation status are tracked on-chain.

---

## 📦 Contract Architecture

| Component        | Description                                                            |
| ---------------- | ---------------------------------------------------------------------- |
| `solar-farms`    | Stores metadata about each solar farm                                  |
| `member-panels`  | Tracks number of panels owned by each member per farm                  |
| `revenue-claims` | Prevents double-claiming of revenue for a given farm and month         |
| `farm-upgrades`  | Stores upgrade proposals and their voting states                       |
| `upgrade-votes`  | Tracks each voter’s decision to ensure one vote per member per upgrade |

---

## 🛠 Functions Overview

### Public Functions

* `install-farm(...)` — Add a new solar farm (only callable by `GRID_OPERATOR`)
* `buy-panels(...)` — Purchase panels in a given farm
* `distribute-revenue(...)` — Record revenue distribution event (only by farm’s chief engineer)
* `claim-revenue(...)` — Claim a share of revenue based on ownership
* `create-upgrade(...)` — Propose a farm upgrade (requires panel ownership)
* `vote-upgrade(...)` — Cast a vote on an upgrade proposal

### Read-Only Functions

* `get-farm(...)` — Retrieve farm details
* `get-panel-balance(...)` — Check member’s panel balance
* `get-upgrade(...)` — Get details of an upgrade proposal
* `calculate-revenue-share(...)` — Estimate revenue share for a member

---

## 🛡️ Access Control

* Only the `GRID_OPERATOR` (contract deployer) can install new farms.
* Only farm `chief-engineers` can trigger `distribute-revenue`.
* Upgrade voting and proposals are restricted to panel holders.

---

## 🧪 Error Codes

| Code   | Meaning                       |
| ------ | ----------------------------- |
| `u700` | Unauthorized member           |
| `u701` | Insufficient panel balance    |
| `u702` | Farm not found                |
| `u703` | Invalid panel amount or price |
| `u704` | Upgrade not found             |
| `u705` | Already voted                 |

---

## 🚀 Use Cases

* **Green Energy Cooperatives:** Launch solar projects where community members co-own energy production.
* **DAO-Based Energy Farms:** Enable governance for decentralized solar infrastructure.
* **Sustainable Investment Platforms:** Tokenize clean energy investment with verifiable returns.
