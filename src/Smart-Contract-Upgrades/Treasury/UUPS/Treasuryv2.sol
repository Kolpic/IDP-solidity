// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { Initializable } from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import { OwnableUpgradeable } from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import { UUPSUpgradeable } from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

/// @custom:oz-upgrades-from TreasuryUUPSV1
contract TreasuryUUPSV2 is Initializable, UUPSUpgradeable, OwnableUpgradeable {
    uint256 public totalDeposits;
    mapping(address => uint256) public userBalances;
    bool public depositsEnabled;
    // NEW VARIABLES
    mapping(address => bool) public blacklisted;
    uint256 public yieldBonus; 
    uint256[45] private __gap; 

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers(); 
    }

    // V2 doesn't need an initialize function if V1 was already called, 
    // but it MUST keep _authorizeUpgrade to remain upgradeable.
    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}

    // --- User Function ---
    function deposit(uint256 amount) external payable {
        require(!blacklisted[msg.sender], "User is blacklisted");
        require(depositsEnabled, "Deposits are currently disabled");
        userBalances[msg.sender] += amount;
        totalDeposits += amount;
    }

    // --- New Admin Functions ---
    function toggleBlacklist(address _user) external onlyOwner {
        blacklisted[_user] = !blacklisted[_user];
    }

    function addYieldPool() external payable onlyOwner {
        yieldBonus += msg.value;
        totalDeposits += msg.value;
    }
}