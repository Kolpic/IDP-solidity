// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

interface ILiquidationEngine {
   // structs

   // Ilk
    struct Collateral {
        // clip
        address auction;  // The address of the collateral auction.
        // chop
        uint256 penalty;  // Liquidation Penalty [wad]
        // hole
        uint256 max_coin;  // Max DAI needed to cover debt+fees of active auctions per collateral [rad]
        // dirt
        uint256 coin_amount;  // Amt DAI needed to cover debt+fees of active auctions per collateral [rad]
    }

   // events
   event Rely(address indexed usr);
   event Deny(address indexed usr);

   event File(bytes32 indexed what, uint256 data);
   event File(bytes32 indexed what, address data);
   event File(bytes32 indexed col_type, bytes32 indexed what, uint256 data);
   event File(bytes32 indexed col_type, bytes32 indexed what, address clip);

   // Bark
    event Liquidate(
        bytes32 indexed col_type,
        address indexed cdp,
        uint256 delta_col,
        uint256 delta_debt,
        uint256 due,
        address auction,
        uint256 indexed id
    );
    event Remove(bytes32 indexed col_type, uint256 rad);

   // errors
   error DogNotUnsafe();
   error DogLiquidationLimitHit();
   error DogDustyAuctionFromPartialLiquidation();
   error DogNullAuction();
   error DogOverflow();

   // functions
   function cdp_engine() external view returns (address);
   function collaterals(bytes32 col_type) external view returns (address, uint256, uint256, uint256);
   function ds_engine() external view returns (address);
   function max_coin() external view returns (uint256);
   function total_coin() external view returns (uint256);

   function penalty(bytes32 col_type) external view returns (uint256);
   function liquidate(bytes32 col_type, address cdp, address keeper) external returns (uint256);
   function remove_coin_from_auction(bytes32 col_type, uint256 rad) external;
   function stop() external;
}