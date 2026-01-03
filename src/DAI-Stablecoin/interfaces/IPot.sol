// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

interface IPot {
    // Events
    
    // Errors
    error PotNotUpdated();
    error PotUnrecognizedParam();
    error PotInvalidBlockTimestamp();

    // Functions
    function pie(address user) external view returns (uint256);
    function total_pie() external view returns (uint256);
    function savings_rate() external view returns (uint256);
    function rate_acc() external view returns (uint256);
    function cdp_engine() external view returns (address);
    function ds_engine() external view returns (address);
    function updated_at() external view returns (uint256);

    function set(bytes32 key, uint256 data) external;
    function set(bytes32 key, address addr) external;
    function stop() external;
    function collect_stability_fee() external returns (uint256);
    function join(uint wad) external;
    function exit(uint wad) external;
}