// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.0 <0.9.0;

contract Ex5_10 {

    event MyFunction(uint result, string name);

    function add(uint _a, uint _b) public {
        uint total = _a + _b;
        emit MyFunction(total, "add");
    }
    function mul(uint _a, uint _b) public {
        uint total = _a * _b;
        emit MyFunction(total, "mul");
    }
}