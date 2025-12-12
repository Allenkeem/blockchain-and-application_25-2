// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

contract BlindAuction {  
    struct Bid {
        bytes32 blindedBid; // - blindedBid : keccak256(abi.encodePacked(value, secret))
        uint    deposit;    // - deposit    : 입찰 시 예치한 이더(wei 단위)
    }

    // Init - 0; Bidding - 1; Reveal - 2; Done - 3
    enum Phase { Init, Bidding, Reveal, Done }

    // 경매 수혜자(경매 종료 시 낙찰금을 가져갈 주소)
    address payable public beneficiary;

    // 현재까지의 최고 입찰자 / 최고 입찰액(wei)
    address public highestBidder;
    uint    public highestBid = 0;

    // 주소당 1개 Bid만 허용
    mapping(address => Bid) public bids;    
    mapping(address => uint) public pendingReturns; // 나중에 돌려줄 금액(최고입찰자였다가 밀려난 사람 등)

    // 현재 경매 단계
    Phase public currentPhase = Phase.Init;
    bool public ended; // auctionEnd가 한 번만 실행되도록 막기 위한 플래그

    // 시간 관련 변수 (block.timestamp 기준)
    uint public biddingEndTime; // 입찰 마감 시각
    uint public revealEndTime;  // 공개 마감 시각
    bool public timesSet;       // setAuctionTimes가 한 번이라도 호출되었는지

    // Events
    event AuctionEnded(address winner, uint highestBid);
    event BiddingStarted();
    event RevealStarted();
    event AuctionInit();

    // Modifiers
    // 오직 수혜자(beneficiary)만 호출 가능
    modifier onlyBeneficiary() {
        require(msg.sender == beneficiary, "Only beneficiary");
        _;
    }

    // 특정 Phase에서만 실행 가능
    // 호출 시점에 block.timestamp를 반영하여 currentPhase를 최신화한 뒤 체크
    modifier inPhase(Phase P) {
        _updatePhaseByTime();
        require(currentPhase == P, "Wrong phase");
        _;
    }
    
    // 생성자
    constructor() {
        beneficiary = payable(msg.sender);
        emit AuctionInit();
    }

    // 시간 설정 / Phase 자동 전환
    
    // 수혜자만 경매 시간을 설정 (한 번만 가능)
    // biddingDuration: 입찰 단계 지속 시간(초 단위)
    // revealDuration: 공개 단계 지속 시간(초 단위)
    // 호출 시점부터 곧장 Bidding 단계로 진입
    function setAuctionTimes(uint biddingDuration, uint revealDuration)
        external
        onlyBeneficiary
    {
        require(!timesSet, "Times already set");
        require(currentPhase == Phase.Init, "Already started");
        require(biddingDuration > 0, "biddingDuration must be > 0");
        require(revealDuration > 0,  "revealDuration must be > 0");

        biddingEndTime = block.timestamp + biddingDuration;
        revealEndTime  = biddingEndTime + revealDuration;
        timesSet = true;

        currentPhase = Phase.Bidding;
        emit BiddingStarted();
    }

    /// @dev block.timestamp와 설정된 마감 시각을 비교해 currentPhase를 자동 갱신
    function _updatePhaseByTime() internal {
        if (!timesSet) {
            // 아직 시간이 설정되지 않았으면 항상 Init
            currentPhase = Phase.Init;
            return;
        }

        // Done 이후에는 더 이상 단계가 변하지 않도록 고정
        if (currentPhase == Phase.Done) {
            return;
        }

        uint nowTime = block.timestamp;

        if (nowTime < biddingEndTime) {
            // 입찰 시간
            currentPhase = Phase.Bidding;
        } else if (nowTime < revealEndTime) {
            // 입찰 시간은 끝났고, 공개 시간은 남아 있는 경우
            if (currentPhase != Phase.Reveal) {
                currentPhase = Phase.Reveal;
                emit RevealStarted();
            }
        } else {
            // 공개 시간까지 모두 끝난 경우
            currentPhase = Phase.Done;
            // 실제 이더 전송/종료 이벤트는 auctionEnd()에서 처리
        }
    }

    // 수동으로 시간 기반 Phase 재계산 (디버깅/보조용)
    // function advancePhase() public onlyBeneficiary {
    //    _updatePhaseByTime();
    // }

    /* Init -> Bidding -> Reveal -> Done 으로 한 단계씩 이동하는 기존의 함수
    function advancePhase() public onlyBeneficiary{
        require(currentPhase != Phase.Done, "Already last phase");

        if (currentPhase == Phase.Init){
            currentPhase = Phase.Bidding;
            emit BiddingStarted();
        } else if (currentPhase == Phase.Bidding){
            currentPhase = Phase.Reveal;
            emit RevealStarted();
        } else if (currentPhase == Phase.Reveal){
            currentPhase = Phase.Done;
            // Done 단계 진입 자체에 대한 이벤트는 따로 두지 않고,
            // 실제 종료는 auctionEnd()에서 AuctionEnded 이벤트로 알림
        }
    } */

    // Bidding 단계에서 블라인드 입찰
    // blindBid = keccak256(abi.encodePacked(value, secret));
    function bid(bytes32 blindBid) public payable inPhase(Phase.Bidding) {
        require(blindBid != bytes32(0), "Invalid blinded bid");
        require(bids[msg.sender].blindedBid == bytes32(0), "Bid already submitted");
        require(msg.value > 0, "Deposit must be > 0");

        bids[msg.sender] = Bid({
            blindedBid: blindBid,
            deposit: msg.value
        });
        // 이 시점에 예치금이 컨트랙트에 잠시 보관됨
    }

    // Reveal 단계에서 실제 입찰가와 secret 공개
    function reveal(uint value, bytes32 secret) public inPhase(Phase.Reveal) {
        Bid storage b = bids[msg.sender];
        require(b.deposit > 0, "No bid found");

        // commit 당시 해시와 비교하여 유효성 검증
        bytes32 calc = keccak256(abi.encodePacked(value, secret));
        require(calc == b.blindedBid, "Hash mismatch");

        // ETH 단위를 wei로 변환
        uint bidWei = value * 1 ether;

        // 같은 커밋을 다시 쓰지 못하도록 초기화
        bids[msg.sender].blindedBid = bytes32(0);

        uint refund = b.deposit; // 환불 예정 금액(처음 예치금 50 ETH 에서 시작)

        // 예치금이 입찰가 이상이면 유효한 입찰로 처리
        // (deposit < bidWei 이면 유효하지 않은 입찰 → 전액 환불)
        if (b.deposit >= bidWei && value > 0) {
            // 현재 최고 입찰가보다 크면 최고 입찰자로 갱신
            if (_placeBid(msg.sender, bidWei)) {
                // 최고 입찰자가 된 경우: 예치금에서 실제 입찰가만 남기고 나머지 환불
                refund -= bidWei;
            }
        }

        // deposit < bidWei 이거나 최고 입찰가가 아닌 경우: 예치금 전체/일부 환불
        b.deposit = 0;

        if (refund > 0) {
            payable(msg.sender).transfer(refund);
        }
    }

    // 기간 내에 공개하지 못한 사용자를 위한 지각 환불. 입찰은 포기하고, 예치금을 전액 돌려받는다.
    function lateRefund() public {
        require(timesSet, "Auction not started yet");
        require(block.timestamp >= revealEndTime, "Reveal period not yet ended");

        Bid storage b = bids[msg.sender];
        uint amount = b.deposit;
        require(amount > 0, "Nothing to refund");

        // 이 사용자의 미공개 입찰을 완전히 폐기
        b.deposit = 0;
        b.blindedBid = bytes32(0);

        payable(msg.sender).transfer(amount);
    }

    // 최고 입찰 갱신 내부 함수
    function _placeBid(address bidder, uint valueWei) internal returns (bool) {
        if (valueWei <= highestBid) {
            return false;
        }

        // 기존 최고 입찰자는 나중에 돌려주기 위해 pendingReturns에 누적
        if (highestBidder != address(0)) {
            pendingReturns[highestBidder] += highestBid;
        }

        highestBid = valueWei;
        highestBidder = bidder;
        return true;
    }

    // 경매에서 지고 pendingReturns에 쌓인 금액(자기 입찰가)을 찾아감
    // 슬라이드에서 마지막 Withdraw 후 loser(20 ETH 입찰자)가 20을 돌려받는 부분
    function withdraw() public {
        uint amount = pendingReturns[msg.sender];
        require(amount > 0, "Nothing to withdraw");

        // 재진입 방지를 위해 먼저 0으로 만들고 이더 전송
        pendingReturns[msg.sender] = 0;
        payable(msg.sender).transfer(amount);
    }

    // Done 단계에서 수혜자(beneficiary)가 실제로 최고 입찰가를 가져감
    function auctionEnd() public onlyBeneficiary inPhase(Phase.Done) {
        require(!ended, "auctionEnd already called");
        ended = true;

        emit AuctionEnded(highestBidder, highestBid);

        // 컨트랙트에 남은 금액 중 최고 입찰액만 수혜자에게 전송
        // (패자들의 입찰액은 pendingReturns에 남아 있다가 withdraw로 반환)
        if (highestBid > 0) {
            beneficiary.transfer(highestBid);
        }
    }
}