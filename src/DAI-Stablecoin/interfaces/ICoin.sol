// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

// This refers to dai contract 
interface ICoin {
    function mint(address,uint) external;
    function burn(address,uint) external;
}