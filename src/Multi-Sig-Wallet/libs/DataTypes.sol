// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

library DataTypes {
    struct Transaction {
        address to;
        uint256 value;
        bytes data;
        bool executed;
    }
}
