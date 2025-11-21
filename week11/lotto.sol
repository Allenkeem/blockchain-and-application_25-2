// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

contract Lottery{
    address public manager;
    address[] public players;

    modifier restricted(){
        require(manager == msg.sender, "Only the manager can call this function");
        _;
    }

    constructor(){
        manager = msg.sender;
    }

    function getPlayers() public view returns(address[] memory){
        // 참여자 목록을 반환하는 함수
        return players;
        // 여기 뭔가 더 고민해봐야할듯????
    }
    function enter() public payable{
        //사용자가 로또에 참여하는 함수
        // 베팅 금액을 확인
        require(msg.value == 1 ether, "Only 1 Ether is Allowed");
        // 이미 참여하였는지 확인한 후 아니면 players 배열에 참여자 주소를 추가
        for (uint i=0;i<players.length;i++){
            if(msg.sender == players[i]){
                revert("You can participate only once.");
            }
        }
        players.push(msg.sender);

    }
    function random() private view returns (uint){
        return uint(keccak256(abi.encodePacked(block.number, block.timestamp, players.length)));
    }
    function pickWinner() public restricted{
        // 당첨자를 무작위로 선택하고, 당첨자에게 컨트랙트 잔액을 송금
        uint index = random() % players.length;
         // 당첨자 주소
        address payable winner = payable(players[index]);

        // 컨트랙트에 쌓여 있는 모든 잔액을 당첨자에게 송금
        winner.transfer(address(this).balance);
        
        // players 배열 초기화
        delete players;
    }


}