// SPDX-License-Identifier: MIT
/// vat.sol -- Dai CDP database
pragma solidity 0.8.24;

import {Auth} from "../lib/Auth.sol";
import {CircuitBreaker} from "../lib/CircuitBreaker.sol";
import {Math} from "../lib/Math.sol";
import {ICDPEngineContract} from "../interfaces/ICDPEngineContract.sol";

contract CDPEngine is Auth, CircuitBreaker, ICDPEngineContract {
    // collateral_type => user => balance of collateral in units of [wad] (1e18)
    mapping (bytes32 => mapping (address => uint)) public gem;  // [wad]
    // owener => user => bool, whether the user can modify the owners account
    mapping(address => mapping (address => bool)) public can;
    // owner => balance of dai in units of
    mapping(address => uint256) public coin;

    // Something like the erc-20 allowance function. It approves users to spend tokens on their behalf
    // old function -> hope
    function allow_account_modification(address usr) external override { 
        can[msg.sender][usr] = true; 
    }

    // old function -> nope
    function deny_account_modification(address usr) external override { 
        can[msg.sender][usr] = false; 
    }

    // Checks of the owner can modify the user's account
    // old function -> wish
    function can_modify_account(address owner, address usr) internal view override returns (bool) {
        return owner == usr || can[owner][usr];
    }

    // Update the internal balance of the dai that is recorded in the Vat (CDPEngine) contract
    // old function -> move
    function transfer_coin(address src, address dst, uint256 rad) external override {
        // checks if the msg.sender is the owner of the account or if msg.sender is approved to modify the account
        if (!can_modify_account(dst, msg.sender)) {
            revert TransferNotAllowed();
        }
        coin[src] -= rad;
        coin[dst] += rad;
    }

    // old function -> slip
    function modify_collateral_balance(bytes32 collateral_type, address user, int256 wad) external override auth {
        gem[collateral_type][user] = Math._add(gem[collateral_type][user], wad);
    }
}