// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./TreasuryV1.sol";

contract TreasuryV2 is TreasuryV1 {
    mapping(address => bool) public blacklisted;
    uint256 public yieldBonus;

    // --- User Functions ---

    function deposit(uint256 amount) external payable override {
        require(!blacklisted[msg.sender], "User is blacklisted");
        require(depositsEnabled, "Deposits are currently disabled");

        userBalances[msg.sender] += amount;
        totalDeposits += amount;
    }

    function isEligibleForYield(address _user) external view returns (bool) {
        return userBalances[_user] > 0 && !blacklisted[_user];
    }

    // --- Admin Functions ---

    function toggleBlacklist(address _user) external onlyOwner {
        blacklisted[_user] = !blacklisted[_user];
    }

    function addYieldPool() external payable onlyOwner {
        yieldBonus += msg.value;
        totalDeposits += msg.value;
    }
}
