// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

interface IGemJoin {
    // Events
    event Join(address indexed usr, uint256 wad);
    event Exit(address indexed usr, uint256 wad);

    // Errors
    error JoinOverflow();
    error ExitOverflow();
    error JoinTransferFailed();
    error ExitTransferFailed();

    // Functions
    function join(address usr, uint wad) external;
    function exit(address usr, uint wad) external;
    function stop() external;
}