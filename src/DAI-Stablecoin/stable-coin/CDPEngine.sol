// SPDX-License-Identifier: MIT
/// vat.sol -- Dai CDP database
pragma solidity 0.8.24;

import {Auth} from "../lib/Auth.sol";
import {CircuitBreaker} from "../lib/CircuitBreaker.sol";
import {Math} from "../lib/Math.sol";
import {ICDPEngineContract} from "../interfaces/ICDPEngineContract.sol";
import {RAY} from "../lib/Math.sol";

contract CDPEngine is Auth, CircuitBreaker, ICDPEngineContract {
    uint256 public sys_max_debt;  // Total Debt Ceiling  [rad]
    // old name -> Ilk 
    struct Collateral {
        // old name -> Art -> Total Normalised Debt     [wad]
        // what means normalised debt?
        // normalised debt is the debt of the user divided by the rate accumation when debt is changed
        // di = delta debt at time i
        // ri = rate_acc at time i
        // Art = d0 / r0 + d1 / r1 + ... + di / ri
        uint256 debt;   
        // old name -> rate -> Accumulated Rates         [ray]
        uint256 rate_acc;  
        // old name -> spot -> Price with Safety Margin  [ray]
        // To prevent uncoverable debt when user is liquidated
        uint256 spot;  
        // old name -> line -> Debt Ceiling              [rad]
        uint256 max_debt;  
        // old name -> dust -> Urn Debt Floor            [rad]
        // Minimum debt that have to be borrowed when creating a CDP
        // To prevet users for crating a small debt, that a liquidator won't have insentive to liquidate it, 
        // because he will loss money doing so 
        uint256 min_debt;  
    }
    // old name -> Urn - vault (CDP)
    struct Position {
        // old name -> ink -> Locked Collateral  [wad]
        uint256 collateral;   
        // old name -> art -> Normalised Debt    [wad]
        uint256 debt;   
    }

    // old name -> ilks
    // id if the collateral => information about the collateral
    mapping (bytes32 => Collateral)                     public collaterals;
    // old name -> urns
    // Ilk id (Collateral id) => owner => information about the position
    mapping (bytes32 => mapping (address => Position )) public positions;
    // id if the collateral => user => balance of collateral in units of [wad] (1e18)
    // collateral_type => user => balance of collateral in units of [wad] (1e18)
    mapping (bytes32 => mapping (address => uint)) public gem;  // [wad]
    // owener => user => bool, whether the user can modify the owners account
    mapping(address => mapping (address => bool)) public can;
    // owner => balance of dai in units of
    mapping(address => uint256) public coin;
    // old name -> debt - total debt in the system 
    uint256 public sys_debt;


    // --- Administration ---
    function init(bytes32 collateral_type_id) external override auth {
        if (collaterals[collateral_type_id].rate_acc != 0) {
            revert CollateralIsAlreadyInitialized();
        }
        collaterals[collateral_type_id].rate_acc = 10 ** 27;
    }

    /**
     * Sets the total debt ceiling
     * @param key The key to set
     * @param value The value to set
     * @notice old function -> file
     */
    function set(bytes32 key, uint value) external override auth not_stopped {
        if (key == "sys_max_debt") sys_max_debt = value;
        else revert KeyNotRecognized();
    }

    /**
     * Overloading the set function to set the collateral. Called by the oracle contract to set the spot price of the collateral
     * @param collateral_type_id The id of the collateral
     * @param key The what to set
     * @param value The value to set
     * @notice old function -> file
     */
    function set(bytes32 collateral_type_id, bytes32 key, uint value) external override auth not_stopped {
        if (key == "spot") collaterals[collateral_type_id].spot = value;
        else if (key == "line") collaterals[collateral_type_id].max_debt = value;
        else if (key == "dust") collaterals[collateral_type_id].min_debt = value;
        else revert KeyNotRecognized();
    }

    function stop() external override auth {
        _stop();
    }

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

    /**
    * @dev --- CDP Manipulation ---
    * @notice This function allows users to: borrow DAI, lock collateral, free collateral and repay DAI
    * @param col_type The ideantifier of the gem(collateral)
    * @param cdp Modify a cdp position for the user u
    * @param gem_src Using gem(collateral) for user v
    * @param coin_dst Creating coin(dai) for user w 
    * @param delta_col The change in amount of collateral
    * @param delta_debt The change in amount of debt
    * 
    * @notice old function -> frob
    */
    function modify_cdp(
        // old name i - collateral id
        bytes32 col_type, 
        // old name u - address that maps to CDP - positions(urns), owner of the CDP
        address cdp, 
        // old name v -source of gem
        address gem_src, 
        // old name w - destination of coin
        address coin_dst, 
        // old name dink -delta collateral 
        int256 delta_col, 
        // old name dart -delta debt
        int256 delta_debt
    ) external override not_stopped {
        Position memory pos = positions[col_type][cdp];
        Collateral memory col = collaterals[col_type];
        // ilk has been initialised
        if (col.rate_acc == 0) {
            revert VatIlkNotInitialized();
        }

        pos.collateral = Math._add(pos.collateral, delta_col);
        pos.debt = Math._add(pos.debt, delta_debt);
        col.debt = Math._add(col.debt, delta_debt);

        // coin [rad] = col.rate_acc [ray] * debt [wad]

        // debt that will be added to the global system debt
        int256 delta_coin = Math._mul(col.rate_acc, delta_debt);
        // total amount of dai that is owed to the cdp position. 
        // The total amount of coin that this cdp position owes to the maker dao stablecoin system
        uint256 coin_debt = col.rate_acc * pos.debt;
        sys_debt = Math._add(sys_debt, delta_coin);

        // either debt has decreased, or debt ceilings are not exceeded
        require(
            delta_debt <= 0 || 
                (col.debt * col.rate_acc <= col.max_debt && sys_debt <= sys_max_debt), 
            "Vat/ceiling-exceeded"
        );

        // urn is either less risky than before, or it is safe
        require(
            (delta_debt <= 0 && delta_col >= 0) ||
                coin_debt <= pos.collateral * col.spot, 
            "Vat/not-safe"
        );

        // urn is either more safe, or the owner consents
        require(
            (delta_debt <= 0 && delta_col >= 0) || 
                can_modify_account(cdp, msg.sender), 
            "Vat/not-allowed-cdp"
        );

        // collateral src consents
        require(
            // delta_col <= 0 means that we are removing the collateral from gem_src
            delta_col <= 0 || can_modify_account(gem_src, msg.sender), 
            "Vat/not-allowed-gem_src"
        );
        // debt dst consents
        require(
            delta_col >= 0 || can_modify_account(coin_dst, msg.sender), 
            "Vat/not-allowed-coin_dst"
        );

        // urn has no debt, or a non-dusty amount
        require(
            pos.debt == 0 || coin_debt >= col.min_debt, 
            "Vat/dust"
        );

        // Moving the collateral from gem to position, hence opposite sign
        // if we lock collateral -> - gem, + pos (delta_debt >= 0)
        // if we free collateral -> + gem, - pos (delta_debt <= 0)
        gem[col_type][gem_src] = Math._sub(gem[col_type][gem_src], delta_col);
        coin[coin_dst]    = Math._add(coin[coin_dst],    delta_coin);

        positions[col_type][cdp] = pos;
        collaterals[col_type]    = col;
    }
}