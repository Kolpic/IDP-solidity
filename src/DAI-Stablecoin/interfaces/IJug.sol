// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

interface IJug {
    // structs
    
    // Ilk
    struct Collateral {
        // Collateral-specific, per-second stability fee contribution [ray]
        // duty
        uint256 fee;
        // Time of last drip [unix epoch time]
        // rho
        uint256  updated_at;
    }

    // events

    // errors
    error JugCollateralAlreadyInitialized();
    error JugUpdatedAtNotUpdated();
    error JugUnrecognizedParam();
    error JugInvalidNow();

    // functions
    function collaterals(bytes32 col_type) external view returns (uint256, uint256);
    function cdp_engine() external view returns (address);
    function debt_surplus_engine() external view returns (address);
    function base_fee() external view returns (uint256);

    function init(bytes32 col_type) external;
    function set(bytes32 col_type, bytes32 key, uint data) external;
    function set(bytes32 key, uint data) external;
    function set(bytes32 key, address data) external;
    function drip(bytes32 col_type) external returns (uint rate);
}