// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

// PipLike
interface IPriceFeed {
    // [wad]
    function peek() external returns (uint256, bool);
}

interface ISpotter {
    // structs

    // Ilk
    struct Collateral {
        IPriceFeed pip;  // Price Feed
        // spot = val / mat
        // mat
        uint256 liquidation_ratio;  // Liquidation ratio [ray]
    }


    // Events
    //                                  [wad]        [ray]
    event Poke(bytes32 col_type, uint256 val, uint256 spot);

    // Errors
    error SpotterUnrecognizedParam();

    // Functions
    function collaterals(bytes32 col_type) external view returns (IPriceFeed, uint256);
    function cdp_engine() external view returns (address);
    function par() external view returns (uint256);
    
    function set(bytes32 col_type, bytes32 key, address pip) external;
    function set(bytes32 key, uint data) external;
    function set(bytes32 col_type, bytes32 key, uint data) external;
    function poke(bytes32 col_type) external;
    function stop() external;
}