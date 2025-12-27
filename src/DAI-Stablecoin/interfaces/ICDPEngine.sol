// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

interface ICDPEngine {
    function modify_collateral_balance(bytes32,address,int) external;
}