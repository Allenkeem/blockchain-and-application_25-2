// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

contract CrowdFunding {
    struct Investor {
        address addr;   // 투자자 주소
        uint amount;    // 투자금 (wei 단위)
    }

    mapping(uint => Investor) public investors;   // 투자자 추가할 때 key 증가

    address public owner;        // 컨트랙트 소유자
    uint public numInvestors;    // 투자자 수
    uint public deadline;        // 마감일
    string public status;        // 모금활동 상태(Funding, Campaign Succeeded, Campaign Failed)
    bool public ended;           // 모금 종료여부
    uint public goalAmount;      // 목표액 (ETH 단위)
    uint public totalAmount;     // 총 투자액

    // 펀딩 발생 시 알리기 위한 이벤트
    event Funded(address indexed investor, uint amount);

    // 소유자만 실행하게 하는 modifier
    modifier onlyOwner() {
        require(msg.sender == owner, "ONLY OWNER CAN CALL THIS FUNCTION");
        _;
    }

    // _duration: 모금기간(초 단위)
    // _goalAmount: 목표 금액(ETH 단위)을 내부에서는 wei로 변환해서 사용
    constructor(uint _duration, uint _goalAmount) {
        owner = msg.sender;

        deadline = block.timestamp + _duration; // 현재시간 + 모금기간
        goalAmount = _goalAmount * 1 ether;     // ETH 단위를 wei로 변환
        status = "Funding";
        ended = false;

        numInvestors = 0;
        totalAmount = 0;
    }

    // fund() 함수: 컨트랙트로 ETH를 전송하면서 호출 
    function fund() public payable {
        require(!ended, "FUNDING ALREADY ENDED");      // ended == false인 경우에만 진행됨.
        require(block.timestamp < deadline, "DEADLINE PASSED"); // 마감시간 설정
        require(msg.value > 0, "NEED TO SEND ETH");   // 음수 방지

        // 새로운 투자자 정보 저장
        investors[numInvestors] = Investor(msg.sender, msg.value);
        numInvestors++;
        totalAmount += msg.value;

        // 투자 발생 이벤트 발생
        emit Funded(msg.sender, msg.value);
    }

    // 목표 금액 달성 여부 체크 및 정산 함수
    function checkGoalReached() public onlyOwner {
        require(!ended, "Already ended");                    // ended가 false일때만 한번에 한해 실행 가능
        require(block.timestamp >= deadline, "Deadline not reached yet"); // 시간 마감 확ㅇ니 

        // 1) 목표 금액 이상 모인 경우: 소유자에게 전액 송금
        if (totalAmount >= goalAmount) {
            status = "Campaign Succeeded";
            (bool ok, ) = payable(owner).call{value: totalAmount}("");
            require(ok, "Transfer to owner failed");
        } 
        // 2) 목표 금액 미달: 투자자들에게 환불
        else {
            status = "Campaign Failed";
            for (uint i = 0; i < numInvestors; i++) {
                (bool ok, ) = payable(investors[i].addr).call{value: investors[i].amount}("");
                require(ok, "Refund failed");
            }
        }

        ended = true;
    }

    // 투자자 주소 목록 조회 함수
    // 모든 투자자의 주소를 배열 형태로 반환
    function getInvestors() public view returns (address[] memory) {
        // 투자자 수만큼 길이를 가지는 메모리 배열 생성
        address[] memory addrs = new address[](numInvestors);

        // mapping에 저장된 투자자 주소를 메모리 배열에 복사
        for (uint i = 0; i < numInvestors; i++) {
            addrs[i] = investors[i].addr;
        }

        // 완성된 주소 배열 반환
        return addrs;
    }
}