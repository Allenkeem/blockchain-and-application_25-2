// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.5.0 < 0.8.0;

contract Counter {
    uint private count;
    
    function get() public view returns(uint){
        return count;
    }

    function inc() public returns(uint){
        count += 1;
        return count;
    }

    function dec() public returns(uint){
        count -= 1;
        return count;
    }
}