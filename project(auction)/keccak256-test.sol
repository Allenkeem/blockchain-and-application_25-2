// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.0;

contract HashCheck {
    function makeHash(uint value, bytes32 secret) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(value, secret));
    }
}