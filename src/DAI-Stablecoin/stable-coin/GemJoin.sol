// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Auth} from "../lib/Auth.sol";
import {CircuitBreaker} from "../lib/CircuitBreaker.sol";
import {IGemJoin} from "../interfaces/IGemJoin.sol";
import {ICDPEngine} from "../interfaces/ICDPEngine.sol";
import {IGem} from "../interfaces/IGem.sol";

contract GemJoin is Auth, CircuitBreaker, IGemJoin {
    address public override cdp_engine;        // CDP Engine
    bytes32 public override collateral_type;   // Collateral Type
    address public override gem;               // The collateral that will be locked into the contract
    uint8 public override decimals;            // The number of decimals of the erc-20 token

    constructor(address _cdp_engine, bytes32 _collateral_type, address _gem) {
        cdp_engine = _cdp_engine;
        collateral_type = _collateral_type;
        gem = _gem;
        decimals = IGem(gem).decimals();
    }

    function stop() external override auth {
        _stop();
    }

    // wad = 1e18
    // ray = 1e27
    // rad = 1e45
    /**
     * @notice Allocates collateral to a user
     * @param usr The user to allocate collateral for
     * @param wad The amount of collateral to be locked
     * 
     * wad = 1e18
     * ray = 1e27
     * rad = 1e45
     * 
     * @notice with this function the msg.sender (user) is transferring the collateral (in wad) into this contract (address(this)),
     * but before it does that it calls cdp_engine.slip -> to modify the collateral balance 
     * (identified by collateral_type) for the user (usr) for amount (wad)
     */
    function join(address usr, uint wad) external override not_stopped{
        if (int(wad) < 0) {
            revert JoinOverflow();
        }
        // vat.slip
        ICDPEngine(cdp_engine).modify_collateral_balance(collateral_type, usr, int(wad));
        
        if (!IGem(gem).transferFrom(msg.sender, address(this), wad)) {
            revert JoinTransferFailed();
        }
        emit Join(usr, wad);
    }

    /**
     * @notice Releases collateral from the contract to a user
     * @param usr The user to release collateral for
     * @param wad The amount of collateral to be released
     */
    function exit(address usr, uint wad) external override not_stopped{
        // checks when wad is casted to int, it doesn't overflow
        if (wad > 2 ** 255) {
            revert ExitOverflow();
        }
        // vat.slip
        ICDPEngine(cdp_engine).modify_collateral_balance(collateral_type, msg.sender, -int(wad));
        
        if (!IGem(gem).transfer(usr, wad)) {
            revert ExitTransferFailed();
        }
        emit Exit(usr, wad);
    }
}