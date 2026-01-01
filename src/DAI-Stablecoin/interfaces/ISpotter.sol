// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

interface ISpotter {
    // Events
    //                                  [wad]        [ray]
    event Poke(bytes32 col_type, uint256 val, uint256 spot);

    // Errors
    error SpotterUnrecognizedParam();

    // Functions
    function set(bytes32 col_type, bytes32 key, address pip) external;
    function set(bytes32 key, uint data) external;
    function set(bytes32 col_type, bytes32 key, uint data) external;
    function poke(bytes32 col_type) external;
    function stop() external;
}