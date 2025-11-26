// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

interface IMultiSigWallet {
    // events
    event Deposit(address indexed sender, uint amount);
    event Submit(uint indexed txId);
    event Approve(address indexed owner, uint indexed txId);
    event Revoke(address indexed owner, uint indexed txId);
    event Execute(uint indexed txId);

    // errors
    error OwnerIsRequired();
    error InvalidReqiredNumberOfOwners();
    error InvalidOwner();
    error OwnerMustBeUnique();
    error NotOwner();
    error TxNotApproved();
    error TxDoesNotExist();
    error TxAlreadyApproved();
    error TxAlreadyExecuted();
    error NotEnoughApprovals();
    error ExecutionFailed();

    // functions
    function submit(address _to, uint256 _value, bytes calldata _data) external;
    function approve(uint256 _txId) external;
    function execute(uint256 _txId) external;
    function revoke(uint256 _txId) external;
}