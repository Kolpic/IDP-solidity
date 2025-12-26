## 🧪 Note

All contracts are in one file and old requires instead of if revert for easier testing in remix ide.

## 🔄 Smart Contract Upgrades

This folder contains implementations and examples of various **Upgradeable Smart Contract** patterns in Solidity. Smart contract upgrades allow developers to fix bugs, add features, and improve contracts after deployment while preserving state and the contract address.

### 📖 Overview

Ethereum smart contracts are immutable by default. However, using the **Proxy Pattern**, we can separate the contract's logic from its storage, enabling upgrades. All patterns in this folder use the **EIP-1967** standard for storing proxy state in specific storage slots to avoid collisions.

### 📁 Folder Structure

```
Smart-Contract-Upgrades/
├── Proxy-Pattern-Transparent/     # Manual transparent proxy implementation
├── Proxy-Pattern-With-OpenZeppelin/  # UUPS proxy with OpenZeppelin libraries
└── Treasury/
    ├── Transparent/               # Treasury example using Transparent Proxy
    └── UUPS/                      # Treasury example using UUPS Proxy
```

---

## 📂 Proxy-Pattern-Transparent

**Pattern:** Transparent Proxy Pattern (Manual Implementation)

A **from-scratch** implementation of the Transparent Proxy Pattern demonstrating the core concepts without external libraries.

### Key Components

| Contract        | Description                                               |
| --------------- | --------------------------------------------------------- |
| **CounterV1**   | First implementation with basic `inc()` function          |
| **CounterV2**   | Upgraded implementation adding `dec()` function           |
| **Proxy**       | The proxy contract handling delegatecalls and admin logic |
| **ProxyAdmin**  | Admin contract for managing proxy upgrades                |
| **StorageSlot** | Library for reading/writing to arbitrary storage slots    |

### How It Works

- The Proxy stores the implementation address in a specific storage slot (EIP-1967)
- Admin functions (`upgradeTo`, `changeAdmin`) are only callable by the admin
- User calls are delegated to the implementation contract
- The `ifAdmin` modifier ensures admin calls don't accidentally trigger business logic

---

## 📂 Proxy-Pattern-With-OpenZeppelin

**Pattern:** UUPS (Universal Upgradeable Proxy Standard)

An upgradeable **ERC20 token** implementation using OpenZeppelin's upgradeable contracts and the UUPS pattern.

### Key Components

| Contract      | Description                                                    |
| ------------- | -------------------------------------------------------------- |
| **MyERC20**   | V1 implementation with `increase()` function that mints tokens |
| **MyERC20v2** | V2 implementation adding `lastUser` tracking                   |

### Features

- Uses `Initializable` pattern (replaces constructor)
- `_disableInitializers()` in constructor prevents initialization of implementation
- `__gap` storage slots reserved for future upgrades
- Owner-restricted upgrades via `_authorizeUpgrade`

### Key Differences from Transparent Pattern

| Feature       | Transparent Proxy                  | UUPS                                                 |
| ------------- | ---------------------------------- | ---------------------------------------------------- |
| Upgrade Logic | In Proxy contract                  | In Implementation contract                           |
| Gas Cost      | Higher (admin check on every call) | Lower                                                |
| Risk          | Lower                              | Higher (can brick contract if upgrade logic removed) |

---

## 📂 Treasury

A real-world **Treasury** contract example implemented with both upgrade patterns for comparison.

### Transparent (`Treasury/Transparent/`)

**Pattern:** Transparent Proxy Pattern (Manual Implementation)

| Contract       | Description                                              |
| -------------- | -------------------------------------------------------- |
| **TreasuryV1** | Basic deposit/withdraw functionality with owner controls |
| **TreasuryV2** | Adds blacklist feature and yield bonus pool              |
| **Proxy**      | Transparent proxy implementation                         |
| **ProxyAdmin** | Admin contract with treasury-specific functions          |

#### TreasuryV1 Features

- Deposit/withdraw ETH
- Toggle deposits (owner only)
- Track user balances

#### TreasuryV2 Additions

- User blacklisting
- Yield bonus pool functionality
- Blacklist check on deposits

---

### UUPS (`Treasury/UUPS/`)

**Pattern:** UUPS (Universal Upgradeable Proxy Standard)

| Contract           | Description                                        |
| ------------------ | -------------------------------------------------- |
| **TreasuryUUPSV1** | Treasury with OpenZeppelin UUPS pattern            |
| **TreasuryUUPSV2** | Upgraded version with blacklist and yield features |

#### Key Features

- Uses OpenZeppelin's `UUPSUpgradeable`, `Initializable`, and `OwnableUpgradeable`
- Owner can call admin functions directly (no admin/user separation like Transparent)
- `__gap` pattern for safe storage upgrades
- `_authorizeUpgrade` restricts upgrades to owner

---

## 🔑 Key Concepts

### Storage Slot Pattern (EIP-1967)

```solidity
bytes32 private constant IMPLEMENTATION_SLOT =
    bytes32(uint256(keccak256("eip1967.proxy.implementation")) - 1);
```

### Delegatecall

The proxy forwards all calls to the implementation using `delegatecall`, executing the implementation's code in the proxy's storage context.

### Initializers vs Constructors

Upgradeable contracts use `initialize()` functions instead of constructors because the proxy (not the implementation) holds the state.

---

## 📚 Resources

- [Building Upgradeable Smart Contracts with Foundry & OpenZeppelin](https://medium.com/coinmonks/building-upgradeable-smart-contracts-with-foundry-openzeppelin-an-erc20-step-by-step-guide-045337eb1559)
- [The State of Smart Contract Upgrades (OpenZeppelin)](https://www.openzeppelin.com/news/the-state-of-smart-contract-upgrades#diamonds)
- [How to Abuse Delegatecall (Ethernaut)](https://medium.com/coinmonks/ethernaut-lvl-6-walkthrough-how-to-abuse-the-delicate-delegatecall-466b26c429e4)
- [Ethereum In Depth - Part 1](https://www.openzeppelin.com/news/ethereum-in-depth-part-1-968981e6f833)
- [Transparent Upgradeable Proxy (RareSkills)](https://rareskills.io/post/transparent-upgradeable-proxy)
