// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "forge-std/Test.sol";
import "../../src/Multi-Sig-Wallet/MultiSigWallet.sol";
import "../../src/Multi-Sig-Wallet/libs/DataTypes.sol";
import "../../src/Multi-Sig-Wallet/interfaces/IMultiSigWallet.sol";

contract MultiSigWalletTest is Test {
    MultiSigWallet public wallet;

    address[] public owners;
    address public owner1 = address(0x1);
    address public owner2 = address(0x2);
    address public owner3 = address(0x3);
    address public nonOwner = address(0x4);

    uint256 public required = 2;

    event Deposit(address indexed sender, uint256 amount);
    event Submit(uint256 indexed txId);
    event Approve(address indexed owner, uint256 indexed txId);
    event Revoke(address indexed owner, uint256 indexed txId);
    event Execute(uint256 indexed txId);

    function setUp() public {
        owners.push(owner1);
        owners.push(owner2);
        owners.push(owner3);

        // Label addresses for better traces
        vm.label(owner1, "Owner 1");
        vm.label(owner2, "Owner 2");
        vm.label(owner3, "Owner 3");
        vm.label(nonOwner, "Non Owner");

        wallet = new MultiSigWallet(owners, required);
    }

    /* =========================
       UNIT TESTS
    ========================= */

    function test_Constructor() public {
        assertEq(wallet.owners(0), owner1);
        assertEq(wallet.required(), 2);
        assertTrue(wallet.isOwner(owner1));
        assertFalse(wallet.isOwner(nonOwner));
    }

    function testRevert_ConstructorEmptyOwners() public {
        address[] memory emptyOwners;
        vm.expectRevert(IMultiSigWallet.OwnerIsRequired.selector);
        new MultiSigWallet(emptyOwners, 1);
    }

    function testRevert_ConstructorInvalidOwnerAddress() public {
        address[] memory badOwners = new address[](1);
        badOwners[0] = address(0);
        vm.expectRevert(IMultiSigWallet.InvalidOwner.selector);
        new MultiSigWallet(badOwners, 1);
    }

    function testRevert_ConstructorUniqueOwners() public {
        address[] memory dupOwners = new address[](2);
        dupOwners[0] = owner1;
        dupOwners[1] = owner1;
        vm.expectRevert(IMultiSigWallet.OwnerMustBeUnique.selector);
        new MultiSigWallet(dupOwners, 1);
    }

    function test_Receive() public {
        vm.deal(nonOwner, 1 ether);
        vm.prank(nonOwner);

        vm.expectEmit(true, false, false, true);
        emit Deposit(nonOwner, 1 ether);

        (bool success,) = address(wallet).call{value: 1 ether}("");
        assertTrue(success);
        assertEq(address(wallet).balance, 1 ether);
    }

    function test_Submit() public {
        vm.prank(owner1);
        vm.expectEmit(true, false, false, false);
        emit Submit(0);

        wallet.submit(nonOwner, 1 ether, "");

        (address to, uint256 value, bytes memory data, bool executed) = wallet.transactions(0);
        assertEq(to, nonOwner);
        assertEq(value, 1 ether);
        assertEq(data, "");
        assertFalse(executed);
    }

    function testRevert_SubmitNotOwner() public {
        vm.prank(nonOwner);
        vm.expectRevert(IMultiSigWallet.NotOwner.selector);
        wallet.submit(nonOwner, 1 ether, "");
    }

    function test_Approve() public {
        // Submit first
        vm.prank(owner1);
        wallet.submit(nonOwner, 0, "");

        // Approve
        vm.prank(owner1);
        vm.expectEmit(true, true, false, false);
        emit Approve(owner1, 0);
        wallet.approve(0);

        assertTrue(wallet.approved(0, owner1));
    }

    function testRevert_ApproveTxDoesNotExist() public {
        vm.prank(owner1);
        vm.expectRevert(IMultiSigWallet.TxDoesNotExist.selector);
        wallet.approve(99);
    }

    function testRevert_ApproveAlreadyApproved() public {
        vm.startPrank(owner1);
        wallet.submit(nonOwner, 0, "");
        wallet.approve(0);

        vm.expectRevert(IMultiSigWallet.TxAlreadyApproved.selector);
        wallet.approve(0);
        vm.stopPrank();
    }

    function test_Revoke() public {
        vm.startPrank(owner1);
        wallet.submit(nonOwner, 0, "");
        wallet.approve(0);

        vm.expectEmit(true, true, false, false);
        emit Revoke(owner1, 0);
        wallet.revoke(0);
        vm.stopPrank();

        assertFalse(wallet.approved(0, owner1));
    }

    function test_Execute() public {
        // Send money to wallet so it can send it out
        vm.deal(address(wallet), 2 ether);

        vm.prank(owner1);
        wallet.submit(nonOwner, 1 ether, ""); // tx 0

        // Owner 1 approves
        vm.prank(owner1);
        wallet.approve(0);

        // Owner 2 approves
        vm.prank(owner2);
        wallet.approve(0);

        // Execute
        vm.prank(owner1);
        vm.expectEmit(true, false, false, false);
        emit Execute(0);
        wallet.execute(0);

        (,,, bool executed) = wallet.transactions(0);
        assertTrue(executed);
        assertEq(nonOwner.balance, 1 ether);
    }

    function testRevert_ExecuteInsufficientApprovals() public {
        vm.prank(owner1);
        wallet.submit(nonOwner, 0, "");

        vm.prank(owner1);
        wallet.approve(0);

        vm.prank(owner1);
        vm.expectRevert(IMultiSigWallet.NotEnoughApprovals.selector);
        wallet.execute(0);
    }

    function testRevert_ExecuteAlreadyExecuted() public {
        vm.deal(address(wallet), 1 ether);

        // Setup valid execution
        vm.prank(owner1);
        wallet.submit(nonOwner, 1 ether, "");
        vm.prank(owner1);
        wallet.approve(0);
        vm.prank(owner2);
        wallet.approve(0);

        wallet.execute(0);

        // Try again
        vm.expectRevert(IMultiSigWallet.TxAlreadyExecuted.selector);
        wallet.execute(0);
    }

    /* =========================
       FUZZ TESTS
    ========================= */

    function testFuzz_Submit(address _to, uint256 _value, bytes calldata _data) public {
        // Filter likely invalid params if contract had checks, but it doesn't
        // Just checking basic array push logic
        vm.prank(owner1);
        wallet.submit(_to, _value, _data);

        (address to, uint256 value, bytes memory data, bool executed) = wallet.transactions(0);
        assertEq(to, _to);
        assertEq(value, _value);
        assertEq(data, _data);
        assertFalse(executed);
    }
}
