// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

contract HotelRoom{
    address public owner;
    enum Status{Vacant, Occupied}
    

    modifier onlyWhileVacant(){
        //방 비어있는지 확인 여부.
    }
    modifier costs(uint _amount){
        //일정금액 이상인지 확인, 기본값은 10 ETH
    }
    modifier onlyOwner(){
        //msg.sender == Owner로 갈거고
    }
    
    event Occupy(address customer, uint amount);

    constructor(){
        owner = msg.sender;
        Status public currentStatus = Status.Vacant;
    }

    function book() public onlyWhileVacant costs{
        currentStatus = Status.onlyWhileVacant;
        emit Occupy (msg.sender, msg.value);
    }

    function reset() //여기는 주인만 실행 가능해야할거고{
        //여기 Status vacant로 다시 세팅해야되고.
    }
}