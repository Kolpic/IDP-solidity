// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

// In most cases the gem will be an erc20 token that will be used as collateral for the dai stablecoin system
interface IGem {
    function decimals() external view returns (uint8);
    function transfer(address,uint) external returns (bool);
    function transferFrom(address,address,uint) external returns (bool);
}