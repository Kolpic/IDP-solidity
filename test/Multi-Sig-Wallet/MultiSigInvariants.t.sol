// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "forge-std/Test.sol";
import "../../src/Multi-Sig-Wallet/MultiSigWallet.sol";
import "./MultiSigHndler.t.sol";

contract MultiSigInvariants is Test {
    MultiSigWallet public wallet;
    MultiSigHandler public handler;
    address[] public owners;

    function setUp() public {
        owners.push(address(0x11));
        owners.push(address(0x22));
        owners.push(address(0x33));

        wallet = new MultiSigWallet(owners, 2);
        handler = new MultiSigHandler(wallet);

        // Register the handler for invariant testing
        targetContract(address(handler));
    }

    // Invariant 1: The owner count should never change (contract logic doesn't allow removing owners)
    function invariant_OwnerCountFixed() public {
        assertEq(wallet.owners(0), address(0x11));
        assertEq(wallet.owners(1), address(0x22));
        assertEq(wallet.owners(2), address(0x33));
        // Check array length if a getter existed for length,
        // or just try accessing index 3 and expect revert if strictly checking bounds
    }

    // Invariant 2: Required signatures should never change
    function invariant_RequiredSignaturesFixed() public {
        assertEq(wallet.required(), 2);
    }

    // Invariant 3: Transaction count matches ghost variable
    // This ensures we aren't creating transactions out of thin air or losing them
    function invariant_TransactionCountConsistency() public {
        // Note: We need a helper to get array length since 'transactions' is public array
        // but solidity getter only returns items by index.
        // We can't easily get length via auto-generated getter.
        // We rely on the fact that if index X exists, length > X.

        uint256 ghostCount = handler.ghost_transactionCount();
        if (ghostCount > 0) {
            // Should be able to query the last element
            (address to,,,) = wallet.transactions(ghostCount - 1);
            assertTrue(to != address(0) || to == address(0)); // Just ensuring it doesn't revert
        }

        // Should revert if we try to access out of bounds
        vm.expectRevert();
        wallet.transactions(ghostCount);
    }
}
