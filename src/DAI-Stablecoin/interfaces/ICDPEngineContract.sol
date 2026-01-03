// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

abstract contract ICDPEngineContract {
    // structs
    
    // Ilk 
    struct Collateral {
        // Art -> Total Normalised Debt     [wad]
        // what means normalised debt?
        // normalised debt is the debt of the user divided by the rate accumation when debt is changed
        // di = delta debt at time i
        // ri = rate_acc at time i
        // Art = d0 / r0 + d1 / r1 + ... + di / ri
        uint256 debt;   
        // rate -> Accumulated Rates         [ray]
        uint256 rate_acc;  
        // spot -> Price with Safety Margin  [ray]
        // To prevent uncoverable debt when user is liquidated
        uint256 spot;  
        // line -> Debt Ceiling              [rad]
        uint256 max_debt;  
        // dust -> Urn Debt Floor            [rad]
        // Minimum debt that have to be borrowed when creating a CDP
        // To prevet users for crating a small debt, that a liquidator won't have insentive to liquidate it, 
        // because he will loss money doing so 
        uint256 min_debt;  
    }
    // old name -> Urn - vault (CDP)
    struct Position {
        // ink -> Locked Collateral  [wad]
        uint256 collateral;   
        // art -> Normalised Debt    [wad]
        uint256 debt;   
    }
    // Events

    // Errors
    error TransferNotAllowed();
    error CollateralIsAlreadyInitialized();
    error KeyNotRecognized();
    error VatIlkNotInitialized();
    error VatCeilingExceeded();
    error VatNotSafe();
    error VatNotAllowedCdp();
    error VatNotAllowedGemSrc();
    error VatNotAllowedCoinDst();
    error VatDust();

    // Functions
    function sys_max_debt() external view virtual returns (uint256);
    function collaterals(bytes32 col_type) external view virtual returns (uint256, uint256, uint256, uint256, uint256);
    function positions(bytes32 col_type, address _cdp) external view virtual returns (uint256, uint256);
    function gem(bytes32 col_type, address user) external view virtual returns (uint256);
    function can(address owner, address usr) external view virtual returns (bool);
    function coin(address owner) external view virtual returns (uint256);
    function sys_debt() external view virtual returns (uint256);
    function unbacked_debts(address user) external view virtual returns (uint256);
    function sys_unbacked_debt() external view virtual returns (uint256);

    function init(bytes32 collateral_type_id) external virtual;
    function set(bytes32 key, uint value) external virtual;
    function set(bytes32 collateral_type_id, bytes32 key, uint value) external virtual;
    function stop() external virtual;
    function allow_account_modification(address usr) external virtual;
    function deny_account_modification(address usr) external virtual;
    function can_modify_account(address owner, address usr) internal view virtual returns (bool);
    function transfer_coin(address src, address dst, uint256 rad) external virtual;
    function modify_collateral_balance(bytes32 collateral_type, address user, int256 wad) external virtual;
    function modify_cdp(bytes32 col_type, address cdp, address gem_src, address coin_dst, int256 delta_col, int256 delta_debt) external virtual;
    function update_rate_acc(bytes32 col_type, address coin_dst, int delta_rate) external virtual;
    function burn(uint rad) external virtual;
    function mint(address debt_dst, address coin_dst, uint rad) external virtual;
}