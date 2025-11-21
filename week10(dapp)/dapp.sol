// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

contract Ballot {

    struct Voter {                    // 투표자 상세 정보  
        uint weight;
        bool voted;
        uint vote;
    }
    struct Proposal {                  
        uint voteCount;
    }

    address public chairperson;
    mapping(address => Voter) public voters;  
    Proposal[] public proposals;

    enum Phase {Init, Regs, Vote, Done}
    Phase public currentPhase = Phase.Init;

    modifier onlyChair() {
        require(msg.sender == chairperson, "ONLY CHAIR CAN CALL THIS FUNCTION");
        _;
    }

    /*
    modifier validVoter() {
        require(Voter.weight == 1, "ONLY valid Voter CAN CALL THIS FUNCTION");
        _;
    }
    */ 추후 수정 예정

    modifier validPhase(Phase reqPhase){
        require(currentPhase == reqPhase, "Not a valid Phase");
        _;
    }

    constructor(uint _numProposals){

    }

    function register(address voter)

    function vote(uint toProposal) public vallidPhase(_reqPhase){
        require(currentPhase == ~~~)
    }????
    

    function reqWinner



    
}