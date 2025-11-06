// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.5.0 < 0.8.0;

contract Bank{

    mapping(address => uint256) private balances; // mapping으로 주소값과 uint값 연결 == balances
    address payable public owner;

    event Deposit(address indexed account, uint256 amount); // 입금 진행 시 이벤트 정의
    event Withdrawal(address indexed account, uint256 amount); // 출금 진행 시 이벤트 정의

    constructor() {
        owner = payable(msg.sender); // deploy되면 owner가 정의됩니다
    }

    modifier onlyOwner() { // modifier를 활용하여 owner만이 특정 function을 사용 가능하게 됩니다.
        require(msg.sender == owner, "ONLY OWNER");
        _;
    }

    function deposit() public payable { // 입금
        require(msg.value > 0, "INPUT SHOULD BE MORE THAN ZERO"); // 입금은 0 초과의 값이 요구됩니다.
        balances[msg.sender] += msg.value; // balance mapping에 value 더해짐
        emit Deposit(msg.sender, msg.value); // event Deposit 호출
    }
    function withdraw(uint256 amount) public { // 출금
        require(amount > 0, "amount = 0"); // 0 초과의 값이 요구됩니다.
        uint256 bal = balances[msg.sender]; // bal 변수에 요청을 보낸 주소의 잔고 정의
        require(bal >= amount, "INSUFFICIENT BALANCE");
        // 사용자의 요청과 잔고를 서로 비교, 잔고는 요청값 이상이어야 합니다.

        balances[msg.sender] = bal - amount; // 사용자의 잔고에서 요청값 만큼을 줄입니다.

        (bool ok, ) = payable(msg.sender).call{value: amount}(""); // msg.sender에게 이더를 보냅니다. 성공여부를 튜플 형태로 보냅니다.
        require(ok, "ETH TRANSFER FAIL"); // 성공여부를 확인합니다. 실패하면 트랜젝션을 되돌립니다. 

        emit Withdrawal(msg.sender, amount); // event Withdrawal 호출
    }

    function getBalance() public view returns (uint256) { // 사용자의 잔고를 돌려줍니다.
        return balances[msg.sender];
    }
    function getContractBalance() public view onlyOwner returns (uint256) { // Owner만 사용가능한 함수
        return address(this).balance; // bank의 잔고를 확인 및 돌려줍니다.
    }
}