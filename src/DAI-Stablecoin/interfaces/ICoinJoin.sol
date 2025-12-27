// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

interface ICoinJoin {
    // Events
    event Join(address indexed usr, uint256 wad);
    event Exit(address indexed usr, uint256 wad);

    // Errors

    // Functions
    function join(address usr, uint wad) external;
    function exit(address usr, uint wad) external;
    function stop() external;
}