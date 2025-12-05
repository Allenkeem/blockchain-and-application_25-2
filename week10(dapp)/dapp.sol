// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

contract Ballot {

    struct Voter {
        uint weight;   // 가중치: 1 이상이면 등록된 유권자
        bool voted;    // 이미 투표했는지 여부
        uint vote;     // 선택한 후보 인덱스
    }

    struct Proposal {
        uint voteCount;   // 제안이 받은 총 득표수
    }

    address public chairperson;

    mapping(address => Voter) public voters;    // 투표자 주소를 투표자 상세 정보로 매핑

    Proposal[] public proposals;                // 제안들을 담는 배열

    // onlyChair: 의장만 호출하도록 제한
    modifier onlyChair() {
        require(msg.sender == chairperson, "Only chairperson");
        _;
    }

    // validVoter: 등록된 투표자만 호출하도록 제한 (voters 매핑의 weight 정보로 확인)
    modifier validVoter() {
        require(voters[msg.sender].weight > 0, "Not registered voter");
        _;
    }

    // numProposals: 제안(후보자)의 개수
    constructor(uint numProposals) {
        chairperson = msg.sender;  // 의장 주소만 저장

        for (uint i = 0; i < numProposals; i++) {
            proposals.push(Proposal({voteCount: 0}));
        }
    }

    // register(등록할 투표자 주소)
    function register(address voterAddr) public onlyChair {
    // 이미 등록된 사람(가중치 > 0) 또는 이미 투표한 사람은 막기
        require(voters[voterAddr].weight == 0, "Already registered");
        require(!voters[voterAddr].voted, "Already voted");

        if (voterAddr == chairperson) {
            voters[voterAddr].weight = 2;  // 의장은 가중치 2
        } else {
            voters[voterAddr].weight = 1;  // 일반 유권자는 가중치 1
        }
    }


    // vote(투표할 proposal 의 인덱스)
    function vote(uint proposal) public validVoter {
        require(!voters[msg.sender].voted, "Already voted");
        require(proposal < proposals.length, "Invalid proposal");

        voters[msg.sender].voted = true;
        voters[msg.sender].vote  = proposal;
        proposals[proposal].voteCount += voters[msg.sender].weight;
    }


    // reqWinner: 가장 많은 표를 얻은 proposal 의 인덱스 반환
    function reqWinner() public view returns (uint winningProposal) {
        uint winningVoteCount = 0;

        for (uint i = 0; i < proposals.length; i++) {
            if (proposals[i].voteCount > winningVoteCount) {
                winningVoteCount = proposals[i].voteCount;
                winningProposal  = i;
            }
        }
    }
}