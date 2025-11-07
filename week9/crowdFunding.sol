// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

contract CrowdFunding {
    struct Investor {
        address addr;   // 투자자 주소
        uint amount;    // 투자금 (wei 단위)
    }

    mapping(uint => Investor) public investors; // 투자자 목록
    address public owner;        // 컨트랙트 소유자
    uint public numInvestors;    // 투자자 수
    uint public deadline;        // 마감일 (timestamp)
    string public status;        // Funding / Campaign Succeeded / Campaign Failed
    bool public ended;           // 종료 여부
    uint public goalAmount;      // 목표 금액 (ETH 단위)
    uint public totalAmount;     // 현재까지 모인 금액

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }

    constructor(uint _duration, uint _goalAmount) {
        owner = msg.sender;
        deadline = block.timestamp + _duration; // 현재시간 + 모금기간
        goalAmount = _goalAmount * 1 ether;     // ETH 단위를 wei로 변환
        status = "Funding";
        ended = false;
        numInvestors = 0;
        totalAmount = 0;
    }

    function fund() public payable {
        require(!ended, "Funding already ended");
        require(block.timestamp < deadline, "Deadline passed");
        require(msg.value > 0, "Need to send ETH");

        investors[numInvestors] = Investor(msg.sender, msg.value);
        numInvestors++;
        totalAmount += msg.value;
    }

    function checkGoalReached() public onlyOwner {
        require(!ended, "Already ended");
        require(block.timestamp >= deadline, "Deadline not reached yet");

        if (totalAmount >= goalAmount) {
            status = "Campaign Succeeded";
            (bool ok, ) = payable(owner).call{value: totalAmount}("");
            require(ok, "Transfer to owner failed");
        } else {
            status = "Campaign Failed";
            for (uint i = 0; i < numInvestors; i++) {
                (bool ok, ) = payable(investors[i].addr).call{value: investors[i].amount}("");
                require(ok, "Refund failed");
            }
        }

        ended = true;
    }
}
