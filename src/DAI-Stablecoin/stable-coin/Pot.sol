// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Auth} from "../lib/Auth.sol";
import {CircuitBreaker} from "../lib/CircuitBreaker.sol";
import {ONE, RAY, Math} from "../lib/Math.sol";
import {IPot} from "../interfaces/IPot.sol";

interface ICDPEngine {
    // move
    function transfer_coin(address src, address dst, uint256 rad) external;
    // suck
    function mint(address debt_dest, address coin_dest, uint256 rad) external;
}

contract Pot is Auth, CircuitBreaker, IPot {
    // Normalised balance is whatever amount that the user deposited, devided by the current rate accumulator
    // balanceOf in erc-20
    // pie
    mapping (address => uint256) public override pie;  // Normalised Savings Dai [wad]

    // totalSupply in erc-20
    // Pie 
    uint256 public override total_pie;       // Total Normalised Savings Dai  [wad]
    // dsr
    uint256 public override savings_rate;    // The Dai Savings Rate          [ray]
    // chi
    uint256 public override rate_acc;        // The Rate Accumulator          [ray]
    // vat
    address public override cdp_engine;      // CDP Engine
    // vow
    address public override ds_engine;       // Debt Surplus Engine
    // rho
    uint256 public override updated_at;     // Time of last drip     [unix epoch time]

    // --- Init ---
    constructor(address _cdp_engine) {
        cdp_engine = _cdp_engine;
        savings_rate = RAY;
        rate_acc = RAY;
        updated_at = block.timestamp;
    }

    // --- Administration ---
    // file
    function set(bytes32 key, uint256 data) external override auth not_stopped {
        // if this check wasn't here we will be able to change the savings rate without updating the rate accumulator
        // and if we don't update the rate accumulator this means that we didn't claimed the DAI
        // we could have when we call the function drip
        if (block.timestamp != updated_at) {
            revert PotNotUpdated();
        }
        if (key == "savings_rate") savings_rate = data;
        else revert PotUnrecognizedParam();
    }

    // file
    function set(bytes32 key, address addr) external override auth {
        if (key == "ds_engine") ds_engine = addr;
        else revert PotUnrecognizedParam();
    }

    function stop() external override auth {
        _stop();
        savings_rate = RAY;
    }

    // --- Savings Rate Accumulation ---
    /**
    * @notice Updates the rate accumulator and whatever interest was earned from the last time drip was called
    * it will ask the vat(cdp engine) contract to mint that amount, send that amount to this contract and send 
    * the debt, the unbacked debt it was created to the vow(debt surplus engine) contract
    * @return delta_rate_acc The new rate accumulator
    *
    * @notice drip
    */
    function collect_stability_fee() external override returns (uint256) {
        if (block.timestamp < updated_at) {
            revert PotInvalidBlockTimestamp();
        }
        uint256 new_rate_acc = Math._rmul(
            //     (x/b) ** n * b
            // x = savings_rate
            // b = RAY
            // n = block.timestamp - updated_at
            Math._rpow(savings_rate, block.timestamp - updated_at, RAY), 
            rate_acc
        );
        uint256 delta_rate_acc = Math._sub(new_rate_acc, rate_acc);
        rate_acc = new_rate_acc;
        updated_at = block.timestamp;
        ICDPEngine(cdp_engine).mint(
            // debt destination
            address(ds_engine), 
            // coin destination
            address(this), 
            // old total DAI = total_pie * old rate_acc
            // new total DAI = total_pie * new rate_acc
            // amount of DAI to mint = total_pie * (new rate_acc - old rate_acc)
            total_pie * delta_rate_acc
        );

        return delta_rate_acc;
    }

    // --- Savings Dai Management ---
    /**
    * @notice This function is called by the user when he wants to deposit some DAI into the Pot contract
    * @param wad The amount of savings dai to join
    *
    * @notice join
    */
    function join(uint wad) external override {
        // check that before anyone call join, they have to call drip first to update the rate accumulator
        if (block.timestamp != updated_at) {
            revert PotNotUpdated();
        }
        pie[msg.sender] += wad;
        total_pie += wad;
        ICDPEngine(cdp_engine).transfer_coin(msg.sender, address(this), rate_acc * wad);
    }

    /**
    * @notice This function is called by the user when he wants to withdraw some DAI from the Pot contract
    * @param wad The amount of savings dai to withdraw
    *
    * @notice exit
    */
    function exit(uint wad) external override {
        // the check is missing, because if the user does not call drip first, he will lose DAI
        pie[msg.sender] -= wad;
        total_pie -= wad;
        ICDPEngine(cdp_engine).transfer_coin(address(this), msg.sender, rate_acc * wad);
    }
}