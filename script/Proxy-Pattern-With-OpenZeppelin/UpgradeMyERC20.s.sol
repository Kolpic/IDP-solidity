// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { Upgrades } from "openzeppelin-foundry-upgrades/Upgrades.sol";
import { Script, console } from "forge-std/Script.sol";

import { MyERC20v2 } from "../../src/Smart-Contract-Upgrades/Proxy-Pattern-With-OpenZeppelin/MyERC20v2.sol";

contract UpgradeMyERC20Script is Script {
    function setUp() public {}

    function run() public {
        uint256 privateKey = vm.envUint("PRIVATE_KEY");
        address proxyAddress = vm.envAddress("PROXY_ADDRESS");

        vm.startBroadcast(privateKey);
        Upgrades.upgradeProxy(proxyAddress, "MyERC20v2.sol", "");
        vm.stopBroadcast();
    }
}