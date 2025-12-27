// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

interface ICDPEngine {
    function modify_collateral_balance(bytes32,address,int) external;
    // transfers the dai that was recoredered in the CDPEngine (Vat).It is like the erc20 transferFrom function
    // it takes the address from, address to and amount of token to send
    function transfer_coin(address src, address dst, uint wad) external;
}