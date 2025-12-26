// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {IMultiSigWallet} from "./interfaces/IMultiSigWallet.sol";
import {DataTypes} from "./libs/DataTypes.sol";

contract MultiSigWallet is IMultiSigWallet {
    // state variables
    address[] public owners;
    mapping(address => bool) public isOwner;
    uint256 public required;

    DataTypes.Transaction[] public transactions;
    mapping(uint256 => mapping(address => bool)) public approved;

    // modifiers
    modifier onlyOwner() {
        if (!isOwner[msg.sender]) {
            revert NotOwner();
        }
        _;
    }

    modifier txExists(uint256 _txId) {
        if (_txId >= transactions.length) {
            revert TxDoesNotExist();
        }
        _;
    }

    modifier notApproved(uint256 _txId) {
        if (approved[_txId][msg.sender]) {
            revert TxAlreadyApproved();
        }
        _;
    }

    modifier notExecuted(uint256 _txId) {
        if (transactions[_txId].executed) {
            revert TxAlreadyExecuted();
        }
        _;
    }

    constructor(address[] memory _owners, uint256 _required) {
        if (_owners.length <= 0) {
            revert OwnerIsRequired();
        }
        if (_required <= 0 || _required > _owners.length) {
            revert InvalidReqiredNumberOfOwners();
        }

        for (uint256 i; i < _owners.length; i++) {
            address owner = _owners[i];

            if (owner == address(0)) {
                revert InvalidOwner();
            }
            if (isOwner[owner]) {
                revert OwnerMustBeUnique();
            }

            isOwner[owner] = true;
            owners.push(owner);
        }
        required = _required;
    }

    receive() external payable {
        emit Deposit(msg.sender, msg.value);
    }

    function submit(address _to, uint256 _value, bytes calldata _data) external override onlyOwner {
        transactions.push(DataTypes.Transaction({to: _to, value: _value, data: _data, executed: false}));

        emit Submit(transactions.length - 1);
    }

    function approve(uint256 _txId) external override onlyOwner txExists(_txId) notApproved(_txId) notExecuted(_txId) {
        approved[_txId][msg.sender] = true;
        emit Approve(msg.sender, _txId);
    }

    function _getApprovalCount(uint256 _txId) private view returns (uint256 count) {
        for (uint256 i; i < owners.length; i++) {
            if (approved[_txId][owners[i]]) {
                count += 1;
            }
        }
    }

    function execute(uint256 _txId) external override txExists(_txId) notExecuted(_txId) {
        if (_getApprovalCount(_txId) < required) {
            revert NotEnoughApprovals();
        }

        DataTypes.Transaction storage transaction = transactions[_txId];
        transaction.executed = true;

        (bool success,) = transaction.to.call{value: transaction.value}(transaction.data);

        if (!success) {
            revert ExecutionFailed();
        }
        emit Execute(_txId);
    }

    function revoke(uint256 _txId) external override onlyOwner txExists(_txId) notExecuted(_txId) {
        if (!approved[_txId][msg.sender]) {
            revert TxNotApproved();
        }

        approved[_txId][msg.sender] = false;
        emit Revoke(msg.sender, _txId);
    }
}
