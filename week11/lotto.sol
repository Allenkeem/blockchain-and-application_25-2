// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

contract Lottery {
    address public manager; // 관리자(배포자)
    address[] public players; // 게임 참여자

    // 단계(enum) 정의: 2단계로 구분
    enum Stage { Betting, Closed }
    Stage public stage;

    // 이벤트 정의
    event PlayerEntered(address indexed player, uint amount); // 참가자 정보: 베팅 참여 시

    event WinnerSelected(address indexed winner, uint prize); // 우승자 정보와 금액: pickWinner 함수 호출 시

    modifier restricted() {
        require(manager == msg.sender, "Only the manager can call this function");
        _;
    }

    // 베팅이 가능한 단계와 베팅이 불가능한 단계로 구분
    modifier inStage(Stage _stage) {
        require(stage == _stage, "Function cannot be called in this stage");
        _;
    }

    constructor() {
        manager = msg.sender;
        stage = Stage.Betting;       // 처음에는 베팅 가능 단계
    }

    function getPlayers() public view returns (address[] memory) {
        return players; // 참여자 목록을 반환
    }

    // 단계 변경 함수 (배포자만 변경 가능)
    function openBetting() public restricted inStage(Stage.Closed){
    stage = Stage.Betting; // 함수 본문에서 stage 변경
    }

    function closeBetting() public restricted inStage(Stage.Betting){
    stage = Stage.Closed;
    }


    // 베팅 참가 함수
    function enter() public payable inStage(Stage.Betting) {
        // 배포자(소유자)는 참여 불가
        require(msg.sender != manager, "Manager cannot participate in the lottery");

        // 베팅 금액 확인 (1 ETH 고정)
        require(msg.value == 1 ether, "Only 1 Ether is allowed");

        // 이미 참여했는지 확인 (중복 참여 방지)
        for (uint i = 0; i < players.length; i++) {
            require(msg.sender != players[i], "You can participate only once.");
        }

        players.push(msg.sender);

        // 이벤트 발생: 참가자 정보와 금액 기록
        emit PlayerEntered(msg.sender, msg.value);
    }

    // 난수 생성(데모용)
    function random() private view returns (uint) {
        return uint(keccak256(abi.encodePacked(block.number, block.timestamp, players.length)));
    }

    // 추첨 함수
    function pickWinner() public restricted inStage(Stage.Betting) {
        require(players.length > 0, "No players in the lottery");

        uint index = random() % players.length;
        address payable winner = payable(players[index]);

        uint prize = address(this).balance;

        // 컨트랙트의 모든 잔액을 우승자에게 송금
        winner.transfer(prize);

        // 이벤트 발생: 우승자 정보와 상금 기록
        emit WinnerSelected(winner, prize);

        // players 배열 초기화 (기존 라운드 종료)
        delete players;

        // 추첨이 끝났으므로 단계 종료 상태로 변경
        stage = Stage.Closed;
    }
    /*
    베팅 단계 처리 방식:
    - enum Stage { Betting, Closed }를 사용해
    "베팅 가능(Betting)" / "베팅 불가(Closed)" 단계를 구분했다.

    - stage 상태변수와 inStage(Stage _stage) modifier를 통해
    특정 단계에서만 함수가 실행되도록 제한했다.
    (enter, pickWinner는 Betting 단계에서만 호출 가능)

    - 추첨 후 stage를 Closed로 변경해 추가 베팅을 막고,
    manager만 openBetting / closeBetting으로 단계를 전환할 수 있게 했다.

    - 고민인 점은 매니저가 closeBetting()을 통해 Closed 상태로 바꿀 수 있는데,
    이러면 pickWinner()를 호출할 수 없다...이에 closeBetting()은 우선 추첨없이 로또를 닫는 건으로 생각하였다.
    */
}
