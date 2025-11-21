// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

contract HotelRoom {
    enum Status {Vacant, Occupied}

    Status public currentStatus;
    address payable public owner;

    event Occupy(address _occupant, uint _value);

    constructor() {
        owner = payable(msg.sender);
        currentStatus = Status.Vacant;
    }
    modifier onlyWhileVacant() {
    require(currentStatus == Status.Vacant, "Currently occupied.");
    _;
    }

    modifier costs(uint _amount) {
    require(msg.value >= _amount, "Not enough ether provided.");
    _;
    }

    modifier onlyOwner() {
    require(msg.sender == owner, "Only the owner can do.");
    _;
    }

    function book() public payable onlyWhileVacant costs(10 ether) {
    currentStatus = Status.Occupied;   // 방 상태 변경
    owner.transfer(msg.value);         // 소유자에게 예약금 전송
    emit Occupy(msg.sender, msg.value);// 이벤트 발생
    }

    function reset() public onlyOwner {
    currentStatus = Status.Vacant;     // 다시 빈방으로 초기화
    }
    
}