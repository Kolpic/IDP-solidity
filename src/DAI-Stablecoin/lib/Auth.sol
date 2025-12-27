// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import { IAuth } from "../interfaces/IAuth.sol";

// This is the contract that will be used to authorize the users to interact with the GemJoin contract
contract Auth is IAuth {
    mapping (address => bool) public authorized;

    modifier auth {
        if (!authorized[msg.sender]) {
            revert NotAuthorized();
        }
        _;
    }

    constructor () {
        authorized[msg.sender] = true;
        emit GrandAuthorization(msg.sender);
    }
    
    function grant_auth(address usr) external override auth {
        authorized[usr] = true;
        emit GrandAuthorization(usr);
    }
    function deny_auth(address usr) external override auth {
        authorized[usr] = false;
        emit DenyAuthorization(usr);
    }
}