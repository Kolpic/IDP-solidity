// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

interface IAuth {
    // Events
    event GrandAuthorization(address indexed usr);
    event DenyAuthorization(address indexed usr);

    // Errors
    error NotAuthorized();

    // Functions
    function grant_auth(address usr) external;
    function deny_auth(address usr) external;
}