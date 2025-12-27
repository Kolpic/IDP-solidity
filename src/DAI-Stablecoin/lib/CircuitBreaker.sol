// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import { ICircuitBreaker } from "../interfaces/ICircuitBreaker.sol";

// Contract that will be used to stop the contract from being called
contract CircuitBreaker is ICircuitBreaker {
    bool public live;  // Indicates wheather this contract can be called or not

    modifier not_stopped() {
        if (!live) {
            revert NotLive();
        }
        _;
    }

    constructor () {
        live = true;
    }
 
    function _stop() internal override {
        live = false;
        emit Stop();
    }
}