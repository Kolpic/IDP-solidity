// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Auth} from "../lib/Auth.sol";
import {CircuitBreaker} from "../lib/CircuitBreaker.sol";
import {ICDPEngineContract} from "../interfaces/ICDPEngineContract.sol";
import {Math, WAD} from "../lib/Math.sol";
import {ILiquidationEngine} from "../interfaces/ILiquidationEngine.sol";

// ClipperLike
interface ICollateralAuction {
    function collateral_type() external view returns (bytes32);
    function start(
        // tab
        uint256 coin_amount,
        // lot
        uint256 collateral_amount,
        // usr
        address user,
        // kpr
        address keeper
    ) external returns (uint256);
}

// VowLike
interface IDSEngine {
    // fess
    function push_debt_to_queue(uint256 debt) external;
}

// Dog
contract LiquidationEngine is Auth, CircuitBreaker, ILiquidationEngine {
    address immutable public override cdp_engine;

    // ICDPEngine
    mapping (bytes32 => Collateral) public override collaterals;

    // IDSEngine
    // vow
    address public override ds_engine;   // Debt Engine
    uint256 public override max_coin;  // Max DAI needed to cover debt+fees of active auctions [rad]
    uint256 public override total_coin;  // Amt DAI needed to cover debt+fees of active auctions [rad]

    // --- Init ---
    constructor(address _cdp_engine) {
        cdp_engine = _cdp_engine;
    }

    // chop
    function penalty(bytes32 col_type) external override view returns (uint256) {
        return collaterals[col_type].penalty;
    }

    // --- CDP Liquidation: all bark and no bite ---
    //
    // Liquidate a Vault and start a Dutch auction to sell its collateral for DAI.
    //
    // The third argument is the address that will receive the liquidation reward, if any.
    //
    // The entire Vault will be liquidated except when the target amount of DAI to be raised in
    // the resulting auction (debt of Vault + liquidation penalty) causes either Dirt to exceed
    // Hole or ilk.dirt to exceed ilk.hole by an economically significant amount. In that
    // case, a partial liquidation is performed to respect the global and per-ilk limits on
    // outstanding DAI target. The one exception is if the resulting auction would likely
    // have too little collateral to be interesting to Keepers (debt taken from Vault < ilk.dust),
    // in which case the function reverts. Please refer to the code and comments within if
    // more detail is desired.

    // bark
    function liquidate(
        // ilk
        bytes32 col_type,
        // urn
        address cdp, 
        // kpr
        address keeper
    ) external override not_stopped returns (uint256 id) {
        // ink - collateral
        // art - debt
        (uint256 collateral, uint256 debt) = ICDPEngineContract(cdp_engine).positions(col_type, cdp);
        ICDPEngineContract.Position memory pos = ICDPEngineContract.Position({
            collateral: collateral,
            debt: debt
        });
        
        // rate - rate accumulator
        // spot - spot price with some safety margine
        // dust - min debt that must be borrowed
        // ICDPEngineContract.Collateral memory c = cdp_engine.collaterals(col_type);
        (, uint256 rate_acc, uint256 spot, , uint256 min_debt) = ICDPEngineContract(cdp_engine).collaterals(col_type);
        ICDPEngineContract.Collateral memory c = ICDPEngineContract.Collateral({
            debt: 0,
            rate_acc: rate_acc,
            spot: spot,
            max_debt: 0,
            min_debt: min_debt
        });
        Collateral memory col = collaterals[col_type];
        uint256 delta_debt;
        {
            // spot for the collateral is greater than zero and it's initialized
            // checks that the amount of collateral locked multiplied by the spot,
            // which will give the value for the collateral for this cdp position is less than
            // the position's debt multiplied by the rate accumulator,
            // which will give us the amount of DAI + the fees that the user borrowed
            // aka checks if the position is undercollateralized
            if (!(c.spot > 0 && pos.collateral * c.spot < pos.debt * c.rate_acc)) {
                revert DogNotUnsafe();
            }

            // require(
            //     c.spot > 0 && 
            //     pos.collateral * c.spot < pos.debt * c.rate_acc, 
            //     "Dog/not-unsafe"
            // );

            // Get the minimum value between:
            // 1) Remaining space in the general Hole
            // 2) Remaining space in the collateral hole
            // Here we are making sure that the total amount of debt
            // that is in all of the auctions is less than what is set as a max 
            // and the debt inside of collateral auction is less that what is set as a max
            if (!(max_coin > total_coin && col.max_coin > col.coin_amount)) {
                revert DogLiquidationLimitHit();
            }
            // require(
            //     max_coin > total_coin && 
            //     col.max_coin > col.coin_amount, 
            //     "Dog/liquidation-limit-hit"
            // );

            // room - the maximum amount of debt, that can be sold for this collateral auction
            uint256 room = Math._min(max_coin - total_coin, col.max_coin - col.coin_amount);

            // uint256.max()/(RAD*WAD) = 115,792,089,237,316
            // the amount of debt that to be sold for the auction
            // target coin for auction = debt * rate acc * penalty
            // traget coin for auction / rate_acc / penalty = room
            delta_debt = Math._min(pos.debt, room * WAD / c.rate_acc / col.penalty);

            // Partial liquidation edge case logic
            if (pos.debt > delta_debt) {
                if ((pos.debt - delta_debt) * c.rate_acc < c.min_debt) {

                    // If the leftover Vault would be dusty, just liquidate it entirely.
                    // This will result in at least one of dirt_i > hole_i or Dirt > Hole becoming true.
                    // The amount of excess will be bounded above by ceiling(dust_i * chop_i / WAD).
                    // This deviation is assumed to be small compared to both hole_i and Hole, so that
                    // the extra amount of target DAI over the limits intended is not of economic concern.
                    delta_debt = pos.debt;
                } else {

                    // In a partial liquidation, the resulting auction should also be non-dusty.
                    if (delta_debt * c.rate_acc < c.min_debt) {
                        revert DogDustyAuctionFromPartialLiquidation();
                    }
                }
            }
        }

        uint256 delta_col = pos.collateral * delta_debt / pos.debt;

        if (delta_col == 0) {
            revert DogNullAuction();
        }

        if (delta_debt > 2**255 || delta_col > 2**255) {
            revert DogOverflow();
        }

        // cdp engine will grab the collateral of the cdp,
        // send it over to the auction and the current debt will be registered over ds engine
        ICDPEngineContract(cdp_engine).grab({
            col_type: col_type, 
            cdp: cdp, 
            gem_dst: col.auction, 
            debt_dst: address(ds_engine), 
            delta_col: -int256(delta_col), 
            delta_debt: -int256(delta_debt)
        });

        // calculate the amount of DAI to be raised 
        uint256 due = delta_debt * c.rate_acc;
        IDSEngine(ds_engine).push_debt_to_queue(due);

        {   // Avoid stack too deep
            // This calcuation will overflow if dart*rate exceeds ~10^14
            uint256 target_coin_amount = due * col.penalty / WAD;
            total_coin += target_coin_amount;
            collaterals[col_type].coin_amount += target_coin_amount;

            id = ICollateralAuction(col.auction).start({
                coin_amount: target_coin_amount,
                collateral_amount: delta_col,
                user: cdp,
                keeper: keeper
            });
        }

        emit Liquidate(col_type, cdp, delta_col, delta_debt, due, col.auction, id);
    }

    // digs
    function remove_coin_from_auction(bytes32 col_type, uint256 rad) external override auth {
        total_coin -= rad;
        collaterals[col_type].coin_amount -= rad;
        emit Remove(col_type, rad);
    }

    // cage
    function stop() external override auth {
        _stop();
    }
}