// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { Script } from "forge-std/Script.sol";
import { console } from "forge-std/console.sol";
import { Upgrades } from "openzeppelin-foundry-upgrades/Upgrades.sol";

import { MyERC20 } from "../../src/Smart-Contract-Upgrades/Proxy-Pattern-With-OpenZeppelin/MyERC20.sol";

contract DeployMyERC20 is Script {
    MyERC20 public erc20;

    function setUp() public {}

    function run() public returns (address, address) {
        uint256 privateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(privateKey);

        address proxy = Upgrades.deployUUPSProxy("MyERC20.sol", abi.encodeCall(MyERC20.initialize, ()));
        address implementationAddress = Upgrades.getImplementationAddress(proxy);

        vm.stopBroadcast();

        console.log("Implementation Address: ", implementationAddress);
        console.log("Proxy Address: ", proxy);

        return (proxy, implementationAddress);
    }
}