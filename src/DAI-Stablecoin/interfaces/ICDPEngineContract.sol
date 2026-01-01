// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

abstract contract ICDPEngineContract {
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
    function allow_account_modification(address usr) external virtual;
    function deny_account_modification(address usr) external virtual;
    function can_modify_account(address owner, address usr) internal view virtual returns (bool);
    function transfer_coin(address src, address dst, uint256 rad) external virtual;
    function modify_collateral_balance(bytes32 collateral_type, address user, int256 wad) external virtual;
    function modify_cdp(bytes32 col_type, address cdp, address gem_src, address coin_dst, int256 delta_col, int256 delta_debt) external virtual;
    function init(bytes32 collateral_type_id) external virtual;
    function set(bytes32 key, uint value) external virtual;
    function set(bytes32 collateral_type_id, bytes32 key, uint value) external virtual;
    function stop() external virtual;
    function fold(bytes32 col_type, address coin_dst, int delta_rate) external virtual;
}