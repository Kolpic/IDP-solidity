// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { Initializable } from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import { OwnableUpgradeable } from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import { UUPSUpgradeable } from "@openzeppelin/contracts-v2/proxy/utils/UUPSUpgradeable.sol";

contract TreasuryUUPSV1 is Initializable, UUPSUpgradeable, OwnableUpgradeable {
    uint256 public totalDeposits;
    mapping(address => uint256) public userBalances;
    bool public depositsEnabled;
    uint256[47] private __gap;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers(); 
    }

    /**
     * @dev Replaces the constructor. Sets up ownership and initial state.
     */
    function initialize() public initializer {
        __Ownable_init(msg.sender);
        depositsEnabled = true;
    }

    /**
     * @dev Required by UUPSUpgradeable. 
     * Restricts who can upgrade the contract to the owner.
     */
    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}

    // --- User Functions ---

    function deposit() external payable {
        require(depositsEnabled, "Deposits are currently disabled");
        userBalances[msg.sender] += msg.value;
        totalDeposits += msg.value;
    }

    function withdraw(uint256 _amount) external {
        require(userBalances[msg.sender] >= _amount, "Insufficient balance");
        userBalances[msg.sender] -= _amount;
        totalDeposits -= _amount;
        payable(msg.sender).transfer(_amount);
    }

    function getMyBalance() external view returns (uint256) {
        return userBalances[msg.sender];
    }

    // --- Admin Functions ---

    /**
     * @dev In UUPS, the owner can call this DIRECTLY through the proxy
     * without being blocked like in the Transparent pattern.
     */
    function toggleDeposits() external onlyOwner {
        depositsEnabled = !depositsEnabled;
    }
}