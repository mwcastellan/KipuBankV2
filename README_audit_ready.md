# 🏦 KipuBankV2 – Smart Contract in Solidity (Audit-Ready Version)
[![Solidity](https://img.shields.io/badge/Solidity-^0.8.30-363636?style=flat-square&logo=solidity)](https://soliditylang.org/)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg?style=flat-square)](https://opensource.org/licenses/MIT)
[![OpenZeppelin](https://img.shields.io/badge/OpenZeppelin-5.0-4E5EE4?style=flat-square&logo=openzeppelin)](https://openzeppelin.com/)
[![Chainlink](https://img.shields.io/badge/Chainlink-Oracle-375BD2?style=flat-square&logo=chainlink)](https://chain.link/)

**Author:** Marcelo Walter Castellan  
**Date:** 02/11/2025

---

## 📘 Project Description
KipuBankV2 is an upgraded and audit-ready version of the decentralized banking system that supports multiple ERC-20 tokens, integrates Chainlink price feeds for USD conversion, and provides administrative control for secure management of assets and limits.

---

## 🚀 Major Enhancements (Version 2.1)

### 🔒 1. Security & Audit Improvements
- **receive() now respects Pausable:** ETH deposits are rejected while the contract is paused (`KipuBank__Paused`).
- **Chainlink Oracle validation:**  
  - Normalizes all prices to **18 decimals**.  
  - Checks for **round validity** and **freshness (max 2 h)**.  
  - Raises specific custom errors:
    - `KipuBank__OracleStaleData()`
    - `KipuBank__OracleStaleRound()`
- **Extended error system:** new standardized custom errors for consistency (`KipuBank__InvalidAddress`, `KipuBank__AlreadySupported`, `KipuBank__NotSupported`).
- **Improved whitelist management:** duplicate- and zero-address protection.
- **NatSpec clarified:** paused state disables deposits but allows withdrawals for emergency draining.
- **Immutable price feed explicitly documented.**

> ✅ **Complies with standard audit recommendations (Chainlink + OpenZeppelin best practices).**

---

### 💰 2. Bank Cap & Withdrawal Limits (USD-based)
- Limits apply to **ETH deposits** (converted to USD using the Chainlink ETH/USD feed).  
- Tokens are accepted via whitelist; USD-based limits for tokens will arrive in v3.

---

### 🪙 3. Multi-Token Support
- Users can deposit and withdraw multiple ERC-20 assets.  
- Secure handling of tokens with transfer fees using **balance-difference pattern**.  
- Controlled via admin whitelist.

---

### ⚙️ 4. Administrative Features
- `pauseBank()` / `unpauseBank()` for emergency control.  
- `supportNewToken()` / `removeTokenSupport()` with full input validation.  
- Optional future extension for oracle updates.

---

### 📈 5. Oracle Integration (Chainlink)
- ETH/USD feed via Chainlink.  
- Normalized 18-decimal precision ensures consistent USD calculations.  
- Built-in stale data protection.

---

## 🧩 Contract Structure
| Section | Description |
|----------|--------------|
| Imports | OpenZeppelin + Chainlink |
| Interfaces | ERC-20 & AggregatorV3Interface |
| Libraries | SafeERC20, Pausable, ReentrancyGuard |
| Events | Deposit, Withdrawal, TokenSupported, etc. |
| Errors | Prefixed `KipuBank__` |
| Modifiers | whenNotPaused, onlyOwner, nonReentrant |
| Core Logic | Deposit / Withdraw (ETH + ERC-20) |
| Oracle Integration | Price normalization + stale data checks |

---

## 🧠 Security Highlights
| Protection | Description |
|-------------|-------------|
| ✅ `ReentrancyGuard` | Blocks re-entry attacks |
| ✅ `SafeERC20` | Safe token transfer handling |
| ✅ `Pausable` | Full stop on deposits in emergencies |
| ✅ Oracle freshness | Rejects outdated price data |
| ✅ Custom Errors | Gas-efficient, descriptive reverts |
| ✅ CEI Pattern | Strict order Checks → Effects → Interactions |
| ✅ Explicit Receive Logic | No forced ETH during pause |

---

## 🧪 Testing Summary
| Test | Expected Result |
|------|------------------|
| Deposit ETH over cap | Reverts → `KipuBank__BankCapExceeded` |
| Deposit 0 ETH | Reverts → `KipuBank__ZeroAmount` |
| Withdraw > limit | Reverts → `KipuBank__WithdrawalLimitExceeded` |
| Pause → Deposit | Reverts → `KipuBank__Paused` |
| Withdraw while paused | ✅ Allowed |
| Oracle stale (mocked) | Reverts → `KipuBank__OracleStaleData` |
| Whitelist management | ✅ Passes validation |

---

## ⚙️ Deployment (Remix + Sepolia)

**Constructor parameters**
```solidity
constructor(
    uint256 _bankCapUSD,
    uint256 _withdrawalLimitUSD,
    address _priceFeedAddress
)
```
**Example (Sepolia)**  
`_priceFeedAddress`: `0x694AA1769357215DE4FAC081bf1f309aDC325306`  
`_bankCapUSD`: `100000000000`  (≈ $1,000)  
`_withdrawalLimitUSD`: `10000000000`  (≈ $100)

---

## 🧩 Interaction Examples

```solidity
// Deposit native ETH
depositNative{value: 0.1 ether}();

// Deposit ERC-20 token
IERC20(token).approve(address(kipuBank), amount);
depositToken(token, amount);

// Withdraw native ETH
withdrawNative(0.05 ether);

// Pause / Unpause (owner only)
pauseBank();
unpauseBank();
```

---

## 📋 Limitations (v2.1)
- Cap / limit apply only to ETH (no per-token USD valuation yet).  
- Oracle address immutable – requires redeployment if feed changes.  
- Rebase tokens unsupported (documented).  

---

## 📅 Deployment Info
- **Network:** Sepolia Testnet  
- **Contract Address:** `0x8699706B02A6aa00876cF1050A373e6A63EbcDeE`  
- **Verified on Sourcify & Routescan**

---

## 🛠️ Tech Stack
- **Solidity ^0.8.30**
- **OpenZeppelin 5.x**
- **Chainlink Oracles**
- **Remix IDE + MetaMask**
- **Sepolia Testnet**

---

## 📧 Contact
**Developer:** Marcelo Walter Castellan  
**GitHub:** [mwcastellan](https://github.com/mwcastellan)  
**Email:** mcastellan@yahoo.com  
**Date:** November 2025  
**License:** MIT
