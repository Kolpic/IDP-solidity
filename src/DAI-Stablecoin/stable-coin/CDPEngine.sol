// SPDX-License-Identifier: MIT
/// vat.sol -- Dai CDP database
pragma solidity 0.8.24;

import {Auth} from "../lib/Auth.sol";
import {CircuitBreaker} from "../lib/CircuitBreaker.sol";
import {Math} from "../lib/Math.sol";

contract CDPEngine is Auth, CircuitBreaker {
    // collateral_type => user => balance of collateral in units of [wad] (1e18)
    mapping (bytes32 => mapping (address => uint)) public gem;  // [wad]

    function modify_collateral_balance(bytes32 collateral_type, address user, int256 wad) external auth {
        gem[collateral_type][user] = Math._add(gem[collateral_type][user], wad);
    }
}