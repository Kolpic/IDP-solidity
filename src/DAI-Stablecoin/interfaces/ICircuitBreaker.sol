// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

abstract contract ICircuitBreaker {
    // Events
    event Stop();

    // Errors
    error NotLive();

    // Functions
    function _stop() internal virtual;
}