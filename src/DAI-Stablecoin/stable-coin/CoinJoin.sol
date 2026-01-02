// SPDX-License-Identifier: MIT

/// join.sol -- Basic token adapters
/// DaiJoin contract

pragma solidity 0.8.24;

import {Auth} from "../lib/Auth.sol";
import {CircuitBreaker} from "../lib/CircuitBreaker.sol";
import {RAY} from "../lib/Math.sol";
import {ICDPEngine} from "../interfaces/ICDPEngine.sol";
import {ICoin} from "../interfaces/ICoin.sol";
import {ICoinJoin} from "../interfaces/ICoinJoin.sol";

// DaiJoin contract renamed to CoinJoin
contract CoinJoin is Auth, CircuitBreaker, ICoinJoin {
    // vat
    address public override cdp_engine;      // CDP Engine
    // dai
    address public override coin;            // Stablecoin Token

    constructor(address _cdp_engine, address _coin) {
        cdp_engine = _cdp_engine;
        coin = _coin;
    }

    function stop() external override auth {
        _stop();
    }

    // Repay the dai
    function join(address usr, uint wad) external override{
        // vat.move
        ICDPEngine(cdp_engine).transfer_coin(address(this), usr, RAY * wad);
        ICoin(coin).burn(msg.sender, wad);
        emit Join(usr, wad);
    }

    // Borrow dai from the system
    function exit(address usr, uint wad) external override not_stopped{
        // vat.move
        ICDPEngine(cdp_engine).transfer_coin(msg.sender, address(this), RAY * wad);
        ICoin(coin).mint(usr, wad);
        emit Exit(usr, wad);
    }
}