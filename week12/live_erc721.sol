// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

interface ERC165 {
    function supportsInterface(bytes4 interfaceID) external view returns (bool);
}
interface ERC721TokenReceiver {
    function onERC721Received(address _operator, address _from, uint256 _tokenId, bytes memory _data)
external returns(bytes4);
}

contract ERC721StdNFT is ERC721 {
    address public founder;
    // Mapping from token ID to owner address(각 NFT의 소유자 주소)
    mapping(uint => address) internal _ownerOf; // tokenId → owner
    // Mapping owner address to token count(특정 주소가 보유한 NFT의 개수)
    mapping(address => uint) internal _balanceOf; // owner → number of NFTs
    // Mapping from token ID to approved address(특정 NFT를 대신 전송할 권리를 부여받은 주소를 저장)
    mapping(uint => address) internal _approvals; // tokenId → approved
    // Mapping from owner to operator approvals(특정 주소가 소유자의 모든 NFT를 관리할 권한이 있는지)
    mapping(address => mapping(address => bool)) internal _operatorApprovals;
    
    string public name;
    string public symbol;
    
    constructor (string memory _name, string memory _symbol) {
        founder = msg.sender;
        name = _name;
        symbol = _symbol;

        for (uint tokenID=1; tokenID<=5; tokenID++) { // 1~5번 tokenID를 배포자에게 자동 발행
        _mint(msg.sender, tokenID);
    }

    function _mint(address to, uint id) internal {
        require(to != address(0), "mint to zero address");
        require(_ownerOf[id] == address(0), "already minted");
        
        _balanceOf[to]++;
        _ownerOf[id] = to;
        
        emit Transfer(address(0), to, id);
    }
    
    function mintNFT(address to, uint256 tokenID) public {
        require(msg.sender == founder, "not an authorized minter");
        _mint(to, tokenID);
    }

    function ownerOf(uint256 _tokenId) external view returns (address) {
        address owner = ________________________
        require(owner != address(0), "token doesn't exist");
        return owner;
    }

    function balanceOf(address _owner) external view returns (uint256) {
        require(_owner != address(0), "balance query for the zero address");
        return ________________________
    }

    function getApproved(uint256 _tokenId) external view returns (address) {
        require(_ownerOf[_tokenId] != address(0), "token doesn't exist");
        return ________________________
    }

    function isApprovedForAll(address _owner, address _operator) external view returns (bool) {
        return ________________________
    }

    function approve(address _approved, uint256 _tokenId) external payable {
        address owner = _ownerOf[_tokenId];
        require(
        msg.sender == owner || _operatorApprovals[owner][msg.sender],
        "not authorized"
        );

        _approvals[_tokenId] = _approved;
        emit Approval(owner, _approved, _tokenId);
    }

    function setApprovalForAll(address _operator, bool _approved) external {

        _operatorApprovals[msg.sender][_operator] = _approved;
        emit ApprovalForAll(msg.sender, _operator, _approved);
    }

    function transferFrom(address _from, address _to, uint256 _tokenId) external payable {
        _transferFrom( _from, _to, _tokenId);
    }

    function _transferFrom(address _from, address _to, uint256 _tokenId) private {
        address owner = _ownerOf[_tokenId];
        require(_from == owner, "from != owner");
        require(_to != address(0), "transfer to zero address");

        require(msg.sender == owner
            || msg.sender == _approvals[_tokenId]
            || _operatorApprovals[owner][msg.sender]); //"msg.sender not in {owner,operator,approved}");
        ________________________ // 보내는 사람 balance 감소
        ________________________ // 받는 사람 balance 증가
        ________________________ // 토큰 소유자 변경
        ________________________ // approval 초기화 (ERC721 규칙)
        emit Transfer(_from, _to, _tokenId); // Transfer 이벤트 발생
    }



}