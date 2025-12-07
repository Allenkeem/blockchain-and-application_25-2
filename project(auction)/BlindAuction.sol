// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

contract BlindAuction {
    struct Bid {
        bytes32 blindedBid; // keccak256(abi.encodePacked(value, secret))
        uint deposit;       // 입찰 시 예치한 ETH 양
    }

    // Init - 0; Bidding - 1; Reveal - 2; Done - 3
    enum Phase {Init, Bidding, Reveal, Done}

    // Owner (수혜자)
    address payable public beneficiary;

    // Keep track of the highest bid,bidder (최고 입찰자 / 최고 입찰가)
    address public highestBidder;
    uint public highestBid = 0;

    // Only one bid allowed per address (주소당 한 번만 입찰)
    mapping(address => Bid) public bids;
    mapping(address => uint) pendingReturns; /// 나중에 돌려줄 금액(최고입찰자였다가 밀려난 사람 등)

    Phase public currentPhase = Phase.Init;
    bool public ended; // auctionEnd가 한 번만 실행되도록

    // Events
    event AuctionEnded(address winner, uint highestBid);
    event BiddingStarted();
    event RevealStarted();
    event AuctionInit();

    // Modifiers
    modifier onlyBeneficiary(){
        require(msg.sender == beneficiary, "Only beneficiary");
        _;
    }

    modifier inPhase(Phase P){
        require(currentPhase == P, "Wrong phase");
        _;
    }

    constructor() {
        beneficiary = payable(msg.sender);
        emit AuctionInit();
    }

    // Init -> Bidding -> Reveal -> Done 으로 한 단계씩 이동
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
    }


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
        // 이 시점에 예치금이 컨트랙트로 들어와서
        // 슬라이드의 "Bid 후 컨트랙트: 100 ETH" 상태가 됨
    }

    // Reveal 단계에서 실제 입찰가와 secret 공개
    function reveal(uint value, bytes32 secret) public inPhase(Phase.Reveal) {
        Bid storage b = bids[msg.sender];
        require(b.deposit > 0, "No bid found");

        // 해시 검증
        bytes32 calc = keccak256(abi.encodePacked(value, secret));
        require(calc == b.blindedBid, "Hash mismatch");

        // 여기서부터는 실제 돈 단위: ETH -> wei로 변환
        uint bidWei = value * 1 ether;

        // 앞으로 다시 쓰지 않도록 제거
        bids[msg.sender].blindedBid = bytes32(0);

        uint refund = b.deposit; // 처음 예치한 50 ETH

        // 예치금이 입찰가 이상이면 유효한 입찰로 처리
        if (b.deposit >= value && value > 0) {
            if (_placeBid(msg.sender, bidWei)) {
                // 현재 최고가가 되었다면 deposit 중 value 만큼만 남기고 돌려줌
                // (슬라이드에서 Reveal 후
                // Account3:80, Account4:70, Contract:50 이 되는 구조)
                // deposit(50 ETH) - bid(20/30 ETH)
                refund -= bidWei;
            }
        }

        // deposit < value 이거나 최고가가 아니면 전액/일부 환불
        b.deposit = 0;

        if (refund > 0){
            payable(msg.sender).transfer(refund);
        }
    }

    // 최고 입찰 갱신 내부 함수
    function _placeBid(address bidder, uint valueWei) internal returns (bool) {
        if (valueWei <= highestBid){
            return false;
        }

        // 기존 최고 입찰자는 pendingReturns에 최고 입찰가를 쌓아둔다.
        if (highestBidder != address(0)){
            pendingReturns[highestBidder] += highestBid; // `+=` -> `=`이어도 무방하다
        }

        highestBid = valueWei;
        highestBidder = bidder;
        return true;
    }

    // 경매에서 지고 pendingReturns에 쌓인 금액(자기 입찰가)을 찾아감
    // 슬라이드에서 마지막 Withdraw 후 loser(20 ETH 입찰자)가 20을 돌려받는 부분
    // Withdraw a non-winning bid
    function withdraw() public {
        uint amount = pendingReturns[msg.sender];
        require(amount > 0, "Nothing to withdraw");

        // 재진입 방지
        pendingReturns[msg.sender] = 0;
        payable (msg.sender).transfer(amount);

    }

    // Done 단계에서 수혜자(beneficiary)가 실제로 최고 입찰가를 가져감
    // (슬라이드의 "Show winning bid"에 해당)
    // Send the highest bid to the beneficiary and end the auction
    function auctionEnd() public onlyBeneficiary inPhase(Phase.Done) {
        require(!ended, "auctionEnd already called");
        ended = true;

        emit AuctionEnded(highestBidder, highestBid);

        // 컨트랙트에 남은 금액 중 최고 입찰가만 beneficiary에게 전송
        // (나머지 패자들의 입찰가는 pendingReturns로 남아 있다가 withdraw로 반환)
        if (highestBid > 0){
            beneficiary.transfer(highestBid);
        }
    }
}
