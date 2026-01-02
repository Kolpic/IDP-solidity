// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

interface ICoinJoin {
    // Events
    event Join(address indexed usr, uint256 wad);
    event Exit(address indexed usr, uint256 wad);

    // Errors

    // Functions
    function cdp_engine() external view returns(address);
    function coin() external view returns(address);
    
    function stop() external;
    function join(address usr, uint wad) external;
    function exit(address usr, uint wad) external;
}