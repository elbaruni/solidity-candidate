# 🛡️ Solidity technical assessment — PaymentProcessor

![Foundry](https://img.shields.io/badge/built%20with-Foundry-orange)
![Solidity](https://img.shields.io/badge/solidity-%5E0.8.29-lightgrey)

## Purpose

This repository is a **take-home technical test** for candidates. It evaluates your ability to write **secure, well-tested Solidity** using the **Foundry** toolchain. Complete the requirements below, then submit your work as described in **Submission**.

---

## Assessment overview

You will implement a `PaymentProcessor` contract that supports ETH deposits and withdrawals with correct per-user accounting, appropriate events, and defenses against common vulnerabilities. You will supply a **Foundry** test suite that demonstrates correct behavior and meaningful failure cases.

---

## Requirements

### Objective

Create `src/PaymentProcessor.sol` implementing the following. It must **implement `IPaymentLedger`** from `src/interfaces/IPaymentLedger.sol` (same function signatures and events). Optional helpers ship with the scaffold: `src/errors/PaymentErrors.sol`, `src/libraries/EthTransfers.sol`, and `src/mocks/ReentrantCaller.sol`—use them in your contract or tests if they save time.

### 1. Core functionality

- **Deposit:** Users can deposit ETH; the contract tracks each user’s balance separately.
- **Withdraw:** Users can withdraw up to their own balance (partial or full).
- **Balance query:** A function to read the current balance for the caller or a given address.

### 2. Events

Emit at least:

- `Deposit(address indexed user, uint256 amount)` on a successful deposit.
- `Withdraw(address indexed user, uint256 amount)` on a successful withdrawal.

### 3. Security

- **Reentrancy:** Use checks-effects-interactions or OpenZeppelin `ReentrancyGuard` (or equivalent sound pattern).
- **Arithmetic:** Rely on Solidity 0.8+ overflow checks; keep balance logic explicit and correct.
- **Access control:** Users must only be able to withdraw **their own** funds.

### 4. Testing (Foundry)

Add `tests/PaymentProcessor.t.sol` that covers at least:

- Successful deposits and balance updates.
- Successful withdrawals and balance updates.
- Reverts when withdrawing more than balance.
- Edge cases you consider relevant (for example, zero-value behavior if you treat it as invalid).
- Reentrancy-focused tests are **recommended** but optional.

All tests you rely on for the assessment should pass (`forge test`).

---

## Setup

### Prerequisites

- [Bun](https://bun.sh/) — package manager for Node-based remappings (OpenZeppelin, Forge Std).
- [Foundry](https://book.getfoundry.sh/) — `forge`, `cast`, etc.

### Install

1. Clone the repository and open the project directory.

   ```bash
   git clone <repository-url>
   cd <project-directory>
   ```

2. Install dependencies:

   ```bash
   bun install
   ```

### Configuration

Review `foundry.toml` for compiler and path settings.

---

## Commands

**Build**

```bash
bun run build
# or
forge build
```

**Tests**

```bash
bun run test
# or
forge test
```

For verbose traces: `forge test -vvvv`.

**Coverage (optional)**

```bash
forge coverage
```

---

## Evaluation criteria

1. **Correctness** — Implementation matches specification and behaves consistently across edge cases.
2. **Security** — No obvious vulnerabilities (e.g. reentrancy, improper state updates, unsafe external calls).
3. **Testing** — Tests are comprehensive, readable, and cover success paths and meaningful failures.
4. **Code quality** — Contract and test code are clear, consistent, and maintainable.
5. **Handoff** — Repository is clean, reproducible, and passes `forge test` from a fresh clone. Commit history should be clear, incremental, and professional.
