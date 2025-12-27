// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

abstract contract ICDPEngineContract {
    // Events

    // Errors
    error TransferNotAllowed();

    // Functions
    function allow_account_modification(address usr) external virtual;
    function deny_account_modification(address usr) external virtual;
    function can_modify_account(address owner, address usr) internal view virtual returns (bool);
    function transfer_coin(address src, address dst, uint256 rad) external virtual;
    function modify_collateral_balance(bytes32 collateral_type, address user, int256 wad) external virtual;
}