// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

// VatLike
import {ICDPEngineContract} from "../interfaces/ICDPEngineContract.sol";
import {ISpotter, IPriceFeed} from "../interfaces/ISpotter.sol";
import {Auth} from "../lib/Auth.sol";
import {CircuitBreaker} from "../lib/CircuitBreaker.sol";
import {Math} from "../lib/Math.sol";

// spotter
contract Spotter is Auth, CircuitBreaker, ISpotter {
    // Ilk
    mapping (bytes32 => Collateral) public override collaterals;
    // vat
    address public override cdp_engine;
    // par [ray] - value of DAI in the reference asset (e.g $1 per BEI)
    // par
    uint256 public override par;  // ref per dai [ray]

    // --- Init ---
    constructor(address _cdp_engine) {
        cdp_engine = _cdp_engine;
        par = 10 ** 27;
    }

    // --- Administration ---
    /**
     * @notice Sets the address of the price feed for a collateral type
     * @param col_type The collateral type
     * @param key The key to set
     * @param pip_ The price feed
     * 
     * @notice file
     */
    function set(bytes32 col_type, bytes32 key, address pip_) external override auth not_stopped{
        if (key == "pip") collaterals[col_type].pip = IPriceFeed(pip_);
        else revert SpotterUnrecognizedParam();
    }

    /**
     * @notice Sets the par value
     * @param key The key to set
     * @param data The par value
     * 
     * @notice file
     */
    function set(bytes32 key, uint data) external override auth not_stopped{
        if (key == "par") par = data;
        else revert SpotterUnrecognizedParam();
    }

    /**
     * @notice Sets the liquidation ratio for a collateral type
     * @param col_type The collateral type
     * @param key The key to set
     * @param data The liquidation ratio
     * 
     * @notice file
     */
    function set(bytes32 col_type, bytes32 key, uint data) external override auth not_stopped{
        if (key == "liquidation_ratio") collaterals[col_type].liquidation_ratio = data;
        else revert SpotterUnrecognizedParam();
    }

    // --- Update value ---
    /**
     * @notice Pokes the price feed for a collateral type, can be called by any user
     * @param col_type The collateral type
     * 
     * @notice poke
     */
    function poke(bytes32 col_type) external override {
        (uint256 val, bool ok) = collaterals[col_type].pip.peek();
        //        [wad] * 10 ** 9 / [ray] / liquidation ratio
        // spot = (val * 10 ** 9 / par) / liquidation_ratio -> the formula below
        uint256 spot = ok ? 
            Math.rdiv(
                Math.rdiv(val * 10 ** 9, par), 
                collaterals[col_type].liquidation_ratio
            ) : 0;
        ICDPEngineContract(cdp_engine).set(col_type, "spot", spot);
        emit Poke(col_type, val, spot);
    }

    function stop() external override auth {
        _stop();
    }
}