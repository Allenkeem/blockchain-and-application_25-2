// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.13 <0.9.0;

// ERC-165 인터페이스
interface ERC165 {
    function supportsInterface(bytes4 interfaceID)
        external
        view
        returns (bool);
}

// ERC-721 인터페이스
interface ERC721 is ERC165 {
    // 이벤트들
    // NFT가 이동될 때마다 발생
    event Transfer(address indexed _from, address indexed _to, uint256 indexed _tokenId);
    // 특정 토큰에 대한 단일 승인(approved)이 설정될 때 발생
    event Approval(address indexed _owner, address indexed _approved, uint256 indexed _tokenId);
    // 전체 권한(operator)을 설정할 때 발생
    event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);

    // 필수 함수들
    // _owner가 가진 NFT 개수
    function balanceOf(address _owner) external view returns (uint256 balance);

    // _tokenId의 소유자 주소
    function ownerOf(uint256 _tokenId) external view returns (address owner);

    // 안전 전송(safeTransfer)
    function safeTransferFrom(
        address _from,
        address _to,
        uint256 _tokenId,
        bytes calldata data
    ) external payable;

    // 안전 전송(safeTransfer) – data 없는 간단 버전
    function safeTransferFrom(
        address _from,
        address _to,
        uint256 _tokenId
    ) external payable;

    // 일반 전송
    function transferFrom(
        address _from,
        address _to,
        uint256 _tokenId
    ) external payable;

    // 특정 토큰에 대해 한 번에 한 주소만 승인
    function approve(address _approved, uint256 _tokenId) external payable;

    // owner의 모든 NFT에 대한 operator 권한 설정/해제
    function setApprovalForAll(address _operator, bool _approved) external;

    // 해당 토큰에 대해 승인된 주소
    function getApproved(uint256 _tokenId) external view returns (address);

    // owner가 operator에게 전체 권한을 부여했는지 여부
    function isApprovedForAll(address _owner, address _operator)
        external
        view
        returns (bool);
}

// ERC-721 수신자(Receiver) 인터페이스
interface ERC721TokenReceiver {
    function onERC721Received(
        address _operator, // 호출한 주체 (보통 msg.sender)
        address _from,     // 토큰을 보낸 원래 소유자
        uint256 _tokenId,  // 전송된 토큰 ID
        bytes calldata _data
    ) external returns (bytes4);
}

contract ERC721StdNFT is ERC721 {
    // 컨트랙트 배포자 (초기 민팅 권한 보유자)
    address public founder;

    // Mapping from token ID to owner address(각 NFT의 소유자)
    mapping(uint256 => address) internal _ownerOf;         // tokenId -> owner

    // Mapping owner address to token count(해당 주소가 가진 NFT 개수)
    mapping(address => uint256) internal _balanceOf;        // owner -> # of NFTs

    // Mapping from token ID to approved address(해당 NFT를 대신 전송할 수 있는 주소)
    mapping(uint256 => address) internal _approvals;        // tokenId -> approved

    // Mapping from owner to operator approvals(owner의 모든 NFT 전송 권한)
    mapping(address => mapping(address => bool)) internal _operatorApprovals;
                                                             // owner -> operator -> approved

    string public name;
    string public symbol;

    constructor(string memory _name, string memory _symbol) {
        founder = msg.sender; // 배포자를 founder로 기록
        name = _name;
        symbol = _symbol;

        // 1~5번 tokenID를 배포자에게 자동 발행
        for (uint256 tokenID = 1; tokenID <= 5; tokenID++) {
            _mint(msg.sender, tokenID);
        }
    }

    // 내부 mint 함수 (새로운 tokenId를 to 주소에게 발행)
    function _mint(address to, uint256 id) internal {
        require(to != address(0), "mint to zero address"); // 0x0 주소로 발행 금지
        require(_ownerOf[id] == address(0), "already minted"); // 이미 존재하는 토큰인지 검사

        _balanceOf[to] += 1; // to의 보유 개수 증가
        _ownerOf[id] = to;   // 소유자 정보 기록

        emit Transfer(address(0), to, id);
    }

    // founder만 새로운 NFT 발행 가능
    function mintNFT(address to, uint256 tokenID) public {
        require(msg.sender == founder, "not an authorized minter");
        _mint(to, tokenID);
    }

    // 상태 변수 조회 함수

    // ownerOf: 특정 tokenId의 소유자 주소 반환
    function ownerOf(uint256 _tokenId)
        external
        view
        override
        returns (address)
    {
        address owner = _ownerOf[_tokenId];
        require(owner != address(0), "token doesn't exist"); // 0 주소이면 존재하지 않는 토큰
        return owner;
    }

    // balanceOf: 해당 주소가 가진 NFT 개수 반환
    function balanceOf(address _owner)
        external
        view
        override
        returns (uint256)
    {
        require(_owner != address(0), "balance query for the zero address");
        return _balanceOf[_owner];
    }

    // getApproved: 해당 tokenId에 대해 승인된 주소 반환
    function getApproved(uint256 _tokenId)
        external
        view
        override
        returns (address)
    {
        require(_ownerOf[_tokenId] != address(0), "token doesn't exist");
        return _approvals[_tokenId];
    }

    // isApprovedForAll: owner가 operator에게 전체 NFT 전송 권한을 줬는지 여부
    function isApprovedForAll(address _owner, address _operator)
        external
        view
        override
        returns (bool)
    {
        return _operatorApprovals[_owner][_operator];
    }

    // approve / setApprovalForAll 함수

    // approve: 주어진 tokenId의 전송을 다른 주소에게 허가
    function approve(address _approved, uint256 _tokenId)
        external
        payable
        override
    {
        address owner = _ownerOf[_tokenId];
        require(owner != address(0), "token doesn't exist");

        // 토큰 소유자 or 소유자로부터 승인받은 operator만 호출 가능
        require(
            msg.sender == owner || _operatorApprovals[owner][msg.sender],
            "not authorized"
        );

        _approvals[_tokenId] = _approved;
        emit Approval(owner, _approved, _tokenId);
    }

    // setApprovalForAll: msg.sender가 특정 operator에게
    // 자신의 모든 NFT 전송 권한을 부여 또는 해제
    function setApprovalForAll(address _operator, bool _approved)
        external
        override
    {
        _operatorApprovals[msg.sender][_operator] = _approved;
        emit ApprovalForAll(msg.sender, _operator, _approved);
    }

    // transferFrom 함수

    // 외부에서 호출되는 transferFrom: 내부 _transferFrom으로 위임
    function transferFrom(
        address _from,
        address _to,
        uint256 _tokenId
    ) external payable override {
        _transferFrom(_from, _to, _tokenId);
    }

    // 실제 소유권 이동 로직
    function _transferFrom(
        address _from,
        address _to,
        uint256 _tokenId
    ) private {
        address owner = _ownerOf[_tokenId];
        require(_from == owner, "from != owner");
        require(_to != address(0), "transfer to zero address");

        // msg.sender는 소유자, 해당 토큰의 승인된 주소, 또는 operator 중 하나여야 함
        require(
            msg.sender == owner ||
                msg.sender == _approvals[_tokenId] ||
                _operatorApprovals[owner][msg.sender],
            "msg.sender not in {owner,operator,approved}"
        );

        _balanceOf[_from] -= 1;            // 보내는 사람 balance 감소
        _balanceOf[_to] += 1;              // 받는 사람 balance 증가
        _ownerOf[_tokenId] = _to;          // 토큰 소유자 변경
        _approvals[_tokenId] = address(0); // approval 초기화 (ERC721 규칙)

        emit Transfer(_from, _to, _tokenId);   // Transfer 이벤트 발생
    }

    // safeTransferFrom 함수

    // data 있는 버전 먼저 구현
    function safeTransferFrom(
        address _from,
        address _to,
        uint256 _tokenId,
        bytes calldata data
    ) external payable override {
        // 1) 기본 transfer 로직
        _transferFrom(_from, _to, _tokenId);

        // 2) 받는 쪽이 컨트랙트면 onERC721Received 구현 여부 확인
        require(
            _to.code.length == 0 ||   // 코드 없으면 EOA 지갑 -> OK
                ERC721TokenReceiver(_to).onERC721Received(
                    msg.sender,
                    _from,
                    _tokenId,
                    data
                ) ==
                ERC721TokenReceiver.onERC721Received.selector,
            "unsafe recipient"
        );
    }

    // data 없는 버전 (interface 때문에 꼭 필요)
    function safeTransferFrom(
        address _from,
        address _to,
        uint256 _tokenId
    ) external payable override {
        // 위 함수와 똑같이 동작하되 data 를 빈 바이트로
        _transferFrom(_from, _to, _tokenId);

        require(
            _to.code.length == 0 ||
                ERC721TokenReceiver(_to).onERC721Received(
                    msg.sender,
                    _from,
                    _tokenId,
                    ""
                ) ==
                ERC721TokenReceiver.onERC721Received.selector,
            "unsafe recipient"
        );
    }

    // ERC-165 구현

    function supportsInterface(bytes4 interfaceId)
        external
        pure
        override
        returns (bool)
    {
        return
            interfaceId == type(ERC721).interfaceId ||
            interfaceId == type(ERC165).interfaceId;
    }
}
