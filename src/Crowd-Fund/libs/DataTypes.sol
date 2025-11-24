// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

library DataTypes {
    struct Campaign {
        address creator;
        uint256 goal;
        uint256 pledged;
        uint32 startAt;
        uint32 endAt;
        bool claimed;
    }
}
