// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.5.0 < 0.8.0;

contract Bank{

    mapping(address => uint256) private balances;
    address payable public owner;

    event Deposit(address indexed account, uint256 amount);
    event Withdrawal(address indexed account, uint256 amount);

    constructor() {
        owner = payable(msg.sender);
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "only owner");
        _;
    }

    function deposit() public payable {
        require(msg.value > 0, "no ether sent");
        balances[msg.sender] += msg.value;
        emit Deposit(msg.sender, msg.value);
    }
    function withdraw(uint256 amount) public {
        require(amount > 0, "amount = 0");
        uint256 bal = balances[msg.sender];
        require(bal >= amount, "insufficient balance");

        balances[msg.sender] = bal - amount;

        (bool ok, ) = payable(msg.sender).call{value: amount}("");
        require(ok, "ETH transfer failed");

        emit Withdrawal(msg.sender, amount);
    }

    function getBalance() public view returns (uint256) {
        return balances[msg.sender];
    }
    function getContractBalance() public view onlyOwner returns (uint256) {
        return address(this).balance;
    }
}