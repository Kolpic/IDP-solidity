### 🚀 Decentralized CrowdFund Smart Contract

A secure, decentralized crowdfunding platform built on Ethereum. This contract allows users to launch fundraising campaigns, pledge ERC20 token, and claim funds or get refunds based on whether the campaign goal was met.

### 📖 Overview

The CrowdFund contract allows any user to become a creator and launch a campaign with a specific financial goal and a deadline.

- Trustless: Funds are held by the smart contract, not the creator.

- All-or-Nothing: If the goal is not met by the deadline, the creator gets nothing, and donors get a full refund.

- Flexible: Supports any standard ERC20 token (defined at deployment).

### 🔄 How It Works

```bash
A[Start] -->|User Calls| B(Launch Campaign)
B --> C{Campaign Active?}
C -- Yes --> D[Users Pledge Tokens]
D --> E[Contract Holds Funds]
C -- Yes --> F[Users Unpledge]
F --> D

E --> G{Time Up?}
G -- Yes --> H{Goal Reached?}

H -- Yes --> I[Creator Claims Funds]
H -- No --> J[Users Refund Tokens]
```

## The 4 Stages of a Campaign

1. Launch 🚀

   - A creator defines a goal, a startAt time, and an endAt time.

   - The campaign is assigned a unique ID.

2. Pledge Period 💸

   - Once the startAt time passes, users can pledge (deposit) tokens.

   - Users can also unpledge (withdraw) their tokens if they change their minds before the deadline.

3. Success (Goal Met) ✅

   - If the deadline passes and total pledged >= goal, the Creator calls claim().

   - The contract transfers all pledged tokens to the creator.

4. Failure (Goal Missed) ❌

   - If the deadline passes and total pledged < goal, the Backers call refund().

   - Users get their tokens back. The creator receives nothing.

### 🛠 Features & Functions

## Core functions

| Function     | Actor   | Description                                             |
| ------------ | ------- | ------------------------------------------------------- |
| **launch**   | Creator | Starts a new campaign with a goal and timeline.         |
| **cancel**   | Creator | Cancels a campaign before it has started.               |
| **pledge**   | Backer  | Deposits ERC20 tokens into an active campaign.          |
| **unpledge** | Backer  | Withdraws tokens from an active campaign.               |
| **claim**    | Creator | Withdraws total funds if the campaign succeeded.        |
| **refund**   | Backer  | Withdraws personal contribution if the campaign failed. |

### Security Features 🛡️

- SafeERC20: Utilizes OpenZeppelin's SafeERC20 wrapper to ensure token transfers do not fail silently.

- Time Constraints: Enforces strict checks on start times, end times, and maximum durations to prevent perpetual campaigns.

- State Checks: Prevents double claiming, pledging after end dates, or refunding from successful campaigns.

### ⚙️ Technical Details

## State Variables

- TOKEN: The immutable address of the ERC20 token used for funding (e.g., USDC, DAI, or a custom token).

- MAX_DURATION: The maximum time a campaign is allowed to run (e.g., 90 days).

## Events

The contract emits events for off-chain indexing (The Graph/Frontend):

- CampaignLaunched

- Pledged / Unpledged

- Claimed

- Refunded

### 💻 Installation & Testing

This project is built using Foundry.

1. Clone the Repo

```bash
git clone [https://github.com/your-username/your-repo.git](https://github.com/your-username/your-repo.git)
cd your-repo
```

2. Install Dependencies

```bash
forge install
```

3. Build

```bash
forge build
```

4. Run Tests

Run the comprehensive test suite (Unit, Fuzz, and Invariant tests).

```bash
forge test
```
