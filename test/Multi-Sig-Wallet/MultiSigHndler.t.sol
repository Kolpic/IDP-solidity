// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "forge-std/Test.sol";
import "../../src/Multi-Sig-Wallet/MultiSigWallet.sol";

contract MultiSigHandler is Test {
    MultiSigWallet public wallet;
    address[] public owners;

    // Ghost variables to track expected state
    uint256 public ghost_transactionCount;

    constructor(MultiSigWallet _wallet) {
        wallet = _wallet;
        owners.push(wallet.owners(0));
        owners.push(wallet.owners(1));
        owners.push(wallet.owners(2));
    }

    // Proxy for submit
    function submit(uint256 ownerIndex, address _to, uint256 _value, bytes calldata _data) public {
        address owner = _getOwner(ownerIndex);

        vm.prank(owner);
        wallet.submit(_to, _value, _data);

        ghost_transactionCount++;
    }

    // Proxy for approve
    function approve(uint256 ownerIndex, uint256 txId) public {
        if (ghost_transactionCount == 0) return;
        txId = bound(txId, 0, ghost_transactionCount - 1);
        address owner = _getOwner(ownerIndex);

        // We can't easily check if already approved or executed here without reading state,
        // so we just try calling it. If it reverts, the fuzzer ignores it.
        // To make it more effective, we try to call it only if likely valid.
        (,,, bool executed) = wallet.transactions(txId);
        if (executed) return;

        try wallet.approve(txId) {
        // success
        }
            catch {
            // ignore expected reverts
        }
    }

    // Proxy for execute
    function execute(uint256 txId) public {
        if (ghost_transactionCount == 0) return;
        txId = bound(txId, 0, ghost_transactionCount - 1);

        // Ensure contract has ETH if the tx sends value
        vm.deal(address(wallet), 100 ether);

        try wallet.execute(txId) {
        // success
        }
            catch {
            // ignore
        }
    }

    // Helper to pick a random owner
    function _getOwner(uint256 i) internal view returns (address) {
        return owners[i % owners.length];
    }
}
