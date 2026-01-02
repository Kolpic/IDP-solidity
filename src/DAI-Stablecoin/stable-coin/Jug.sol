// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Auth} from "../lib/Auth.sol";
import {CircuitBreaker} from "../lib/CircuitBreaker.sol";
import {ICDPEngineContract} from "../interfaces/ICDPEngineContract.sol";
import {IJug} from "../interfaces/IJug.sol";
import {Math} from "../lib/Math.sol";
import {RAY} from "../lib/Math.sol";

contract Jug is Auth, CircuitBreaker, IJug {
    // ilks
    mapping (bytes32 => Collateral) public override collaterals;
    // vat
    address public override cdp_engine; // CDP Engine
    // vow
    address public override debt_surplus_engine; // Debt Surplus Engine
    // base
    uint256 public override base_fee; // Global, per-second stability fee contribution [ray]

    // --- Init ---
    constructor(address _cdp_engine) auth{
        cdp_engine = _cdp_engine;
    }

    // --- Administration ---
    function init(bytes32 col_type) external override auth {
        Collateral storage col = collaterals[col_type];
        if (col.fee != 0) {
            revert JugCollateralAlreadyInitialized();
        }
        col.fee = RAY;
        col.updated_at  = block.timestamp;
    }
    /**
     * @notice Updates the fee for a collateral type
     * @param col_type The collateral type
     * @param key The key to set
     * @param data The fee
     */
    function set(bytes32 col_type, bytes32 key, uint data) external override auth {
        if (block.timestamp != collaterals[col_type].updated_at) {
            revert JugUpdatedAtNotUpdated();
        }
        if (key == "fee") collaterals[col_type].fee = data;
        else revert JugUnrecognizedParam();
    }

    /**
     * @notice Updates the base fee
     * @param key The key to set
     * @param data The base fee
     */
    function set(bytes32 key, uint data) external override auth {
        if (key == "base_fee") base_fee = data;
        else revert JugUnrecognizedParam();
    }

    /**
     * @notice Updates the debt surplus engine (DS Engine)
     * @param key The key to set
     * @param data The debt surplus engine
     */
    function set(bytes32 key, address data) external override auth {
        if (key == "debt_surplus_engine") debt_surplus_engine = data;
        else revert JugUnrecognizedParam();
    }

    // --- Stability Fee Collection ---

    /**
     * @notice Calculate the compounded interest for the stability fee and then calls function fold
     * @param col_type The collateral type
     * @return rate The stability fee
     */
    function drip(bytes32 col_type) external override returns (uint rate) {
        if (block.timestamp < collaterals[col_type].updated_at) {
            revert JugInvalidNow();
        }
        (,, uint256 rate_ac, , ) = ICDPEngineContract(cdp_engine).collaterals(col_type);
        rate = Math._rmul(
            // (x/b) ** n * b
                Math._rpow(
                    // x
                    base_fee + collaterals[col_type].fee, 
                    // n
                    block.timestamp - collaterals[col_type].updated_at, 
                    // b
                    10 ** 27
                ),
                rate_ac);
        // stablity fee inside the vat contract update
        ICDPEngineContract(cdp_engine).update_rate_acc(col_type, debt_surplus_engine, Math._diff(rate, rate_ac));
        // update timestamp
        collaterals[col_type].updated_at = block.timestamp;
    }
}