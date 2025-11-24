// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

library DataTypes {
    struct Campaign {
        address creator;
        uint goal;
        uint pledged;
        uint32 startAt;
        uint32 endAt;
        bool claimed;
    }
}