// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

library StorageSlot {
    struct AddressSlot {
        address value;
    }

    function getAddressSlot(bytes32 slot) internal pure returns (AddressSlot storage r) {
        assembly {
            r.slot := slot
        }
    }
}

contract TreasuryV1 {
    uint256 public totalDeposits;
    mapping(address => uint256) public userBalances;
    bool public depositsEnabled;
    address public owner;

    function setOwner(address _owner) external {
        require(owner == address(0), "Already initialized");
        owner = _owner;
    }

    modifier onlyOwner() {
        require (msg.sender == owner, "Not a owner");
        _;
    }

    // --- User Functions ---

    function deposit(uint256 amount) external payable virtual {
        require(depositsEnabled, "Deposits are currently disabled");
        userBalances[msg.sender] += amount;
        totalDeposits += amount;
    }

    function withdraw(uint256 _amount) external virtual {
        require(userBalances[msg.sender] >= _amount, "Insufficient balance");
        userBalances[msg.sender] -= _amount;
        totalDeposits -= _amount;
        payable(msg.sender).transfer(_amount);
    }

    function getMyBalance() external view virtual returns (uint256) {
        return userBalances[msg.sender];
    }

    // --- Admin Functions ---

    function toggleDeposits() external virtual onlyOwner {
        depositsEnabled = !depositsEnabled;
    }
}

contract Proxy {
    bytes32 private constant IMPLEMENTATION_SLOT = bytes32(uint256(keccak256("eip1967.proxy.implementation")) - 1);
    bytes32 private constant ADMIN_SLOT = bytes32(uint256(keccak256("eip1967.proxy.admin")) - 1);

    constructor() {
        _setAdmin(msg.sender);
    }

    modifier ifAdmin() {
        if (msg.sender == _getAdmin()) {
            _;
        } else {
            _fallback();
        }
    }

    function _getAdmin() private view returns (address) {
        return StorageSlot.getAddressSlot(ADMIN_SLOT).value;
    }

    function _setAdmin(address _admin) private {
        require(_admin != address(0), "admin = zero address");
        StorageSlot.getAddressSlot(ADMIN_SLOT).value = _admin;
    }

    function _getImplementation() private view returns (address) {
        return StorageSlot.getAddressSlot(IMPLEMENTATION_SLOT).value;
    }

    function _setImplementation(address _implementation) private {
        require(_implementation.code.length > 0, "implementation is not a contract");
        StorageSlot.getAddressSlot(IMPLEMENTATION_SLOT).value = _implementation;
    }

    //Admin interface
    function changeAdmin(address _admin) external ifAdmin {
        _setAdmin(_admin);
    }

    function upgradeTo(address _implementation) external ifAdmin {
        _setImplementation(_implementation);
    }

    function admin() external ifAdmin returns (address) {
        return _getAdmin();
    }

    function implementation() external ifAdmin returns (address) {
        return _getImplementation();
    }

    // User interface
    function _delegate(address _implementation) internal virtual {
        assembly {
            calldatacopy(0, 0, calldatasize())
            let result := delegatecall(gas(), _implementation, 0, calldatasize(), 0, 0)
            returndatacopy(0, 0, returndatasize())
            switch result
            case 0 {
                revert(0, returndatasize())
            }
            default {
                return (0, returndatasize())
            }
        }
    }

    function _fallback() private {
        _delegate(_getImplementation());
    }

    fallback() external payable {
        _fallback();
    }

    receive() external payable {
        _fallback();
    }
}

contract ProxyAdmin {
    address public owner;

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "not owner");
        _;
    }

    function getProxyAdmin(address proxy) external view returns (address) {
        (bool ok, bytes memory res) = proxy.staticcall(abi.encodeCall(Proxy.admin, ()));
        require(ok, "call failed");
        return abi.decode(res, (address));
    }

    function getProxyImplementation(address proxy) external view returns (address) {
        (bool ok, bytes memory res) = proxy.staticcall(abi.encodeCall(Proxy.implementation, ()));
        require(ok, "call failed");
        return abi.decode(res, (address));
    }

    function changeProxyAdmin(address payable proxy, address admin) external onlyOwner {
        Proxy(proxy).changeAdmin(admin);
    }

    function upgrade(address payable proxy, address implementation) external onlyOwner {
        Proxy(proxy).upgradeTo(implementation);
    }

    function toggleTreasuryDeposits(address payable proxy) external onlyOwner {
        (bool ok, ) = proxy.call(abi.encodeWithSignature("toggleDeposits()"));
        require(ok, "Transaction to logic failed");
    }
}