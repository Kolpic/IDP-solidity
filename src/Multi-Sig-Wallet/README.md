## MultiSigWallet

A secure, lightweight Multi-Signature Wallet implementation in Solidity (0.8.20). This contract requires multiple owners to approve a transaction before it can be executed, adding a layer of security against unauthorized fund movements.

## 📌 Overview

A MultiSig (Multi-Signature) wallet is a smart contract that requires a minimum number of approvals (signatures) from a set of predefined owners to execute a transaction.

For example, you can set up a wallet with 3 owners and a requirement of 2 approvals. This means if one owner's key is compromised, the attacker cannot steal funds without the cooperation of a second owner.

## Key Features

- Multiple Owners: Supports any number of owners (defined at deployment).

- Threshold Security: Configurable number of required approvals (\_required).

- Proposal System: Owners can submit transaction proposals (ETH transfers or arbitrary contract calls).

- Approval Workflow: Owners can approve or revoke approvals for pending transactions.

- Execution Guard: Transactions can only be executed once the approval threshold is met.

## 🏗 Architecture

**The project is structured into three main components:**

1. MultiSigWallet.sol: The core logic contract. It handles storage of owners, transactions, and the logic for the approval workflow.

2. IMultiSigWallet.sol: The interface definition. It allows other contracts to interact with the wallet easily and defines all Events and Custom Errors.

3. DataTypes.sol: A library defining the Transaction struct, ensuring data consistency across the project.

**Transaction Structure**

Each transaction proposal contains:

- `to`: The destination address.

- `value`: Amount of Ether (in wei) to send.

- `data`: Calldata (payload) for executing functions on other contracts.

- `executed`: A boolean flag tracking if the transaction has completed.

## 🚀 Usage Workflow

1. Deployment

Deploy the contract by passing an array of owner addresses and the number of required confirmations.

```bash
address[] memory owners = [0xAbc..., 0xDef..., 0x123...];
uint256 required = 2;
new MultiSigWallet(owners, required);
```

2. Submitting a Transaction

Any **Owner** can propose a transaction.

```bash
// Example: Send 1 ETH to address 0xXYZ...
wallet.submit(0xXYZ..., 1 ether, "");
```

3. Approving

Other **Owners** review the proposal and approve it if valid.

```bash
// Approve transaction at index 0
wallet.approve(0);
```

4. Executing

Once `approvals >= required`, anyone (usually an owner) can trigger the execution.

```bash
wallet.execute(0);
```

5. Revoking (Optional)

If an owner changes their mind before execution, they can revoke their approval.

```bash
wallet.revoke(0);
```

## 🛡️ Security & Validations

The contract utilizes custom errors for gas efficiency and clear debugging:

| Error                  | Description                                       |
| ---------------------- | ------------------------------------------------- |
| **NotOwner**           | Caller is not an authorized owner.                |
| **TxDoesNotExist**     | The transaction ID provided is invalid.           |
| **TxAlreadyApproved**  | The caller has already approved this transaction. |
| **TxAlreadyExecuted**  | The transaction has already been processed.       |
| **NotEnoughApprovals** | Execution attempted before threshold reached.     |
| **ExecutionFailed**    | The external call (low-level call) failed.        |

## 🧪 Testing

This project uses **Foundry** for robust testing, including Unit Tests, Fuzzing, and Invariant Tests.

**Prerequisites**

Ensure you have Foundry installed.

**Run Tests**

To run all unit and fuzz tests:

```bash
forge test
```

**Run Invariant Tests**

To run stateful invariant tests (checking logic consistency over random sequences of events):

```bash
forge test --match-path test/MultiSigWalletInvariants.t.sol
```
