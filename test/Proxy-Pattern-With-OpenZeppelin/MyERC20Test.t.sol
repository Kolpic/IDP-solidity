// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { Upgrades } from "openzeppelin-foundry-upgrades/Upgrades.sol";
import { Test, console } from "forge-std/Test.sol";

import { MyERC20 } from "../../src/Smart-Contract-Upgrades/Proxy-Pattern-With-OpenZeppelin/MyERC20.sol";
import { MyERC20v2 } from "../../src/Smart-Contract-Upgrades/Proxy-Pattern-With-OpenZeppelin/MyERC20v2.sol";

contract MyERC20Test is Test {
    address proxyAddress;
    address owner = makeAddr("owner");
    address user = makeAddr("user");

    function setUp() public {
        vm.prank(owner);
        proxyAddress = Upgrades.deployTransparentProxy("MyERC20.sol", owner, abi.encodeCall(MyERC20.initialize, ()));
    }

    function testDeployment() public view {
        MyERC20 proxy = MyERC20(proxyAddress);
        assertEq(proxy.name(), "UpgradableSmartContract");
        assertEq(proxy.symbol(), "USC");
    }

    function testIncrement() public {
        MyERC20 proxy = MyERC20(proxyAddress);

        vm.prank(user);
        proxy.increase();

        assertEq(proxy.counter(), 1);
    }

    function testUpgradeContract() public {
        MyERC20 proxy = MyERC20(proxyAddress);
        proxy.increase();
        assertEq(proxy.counter(), 1);

        vm.prank(owner);
        Upgrades.upgradeProxy(proxyAddress, "MyERC20v2Second.sol", "");
        vm.stopPrank();

        MyERC20v2 proxyV2 = MyERC20v2(proxyAddress);
        uint256 beforeCounterValue = proxyV2.counter();
        assertEq(beforeCounterValue, 1);

        vm.prank(user);
        proxyV2.increase();
        assertEq(proxyV2.counter(), beforeCounterValue + 2);
        assertEq(proxyV2.lastUser(), user);
    }
}