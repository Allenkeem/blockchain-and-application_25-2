// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.5.0 < 0.8.0;


contract Ex6_16 {

event Obtain(address from, uint amount);

receive() external payable {
    emit Obtain(msg.sender, msg.value);
    }

function getBalance() public view returns(uint) {
    return address(this).balance;
    }

function sendEther() public payable {
    payable(address(this)).transfer(msg.value);
    }
}

