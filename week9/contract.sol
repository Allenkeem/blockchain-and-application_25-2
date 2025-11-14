// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

contract NameRegistry {

    // 컨트랙트 정보를 나타낼 구조체
    struct ContractInfo {
        address contractOwner;      // 컨트랙트를 등록한 사람 (소유자)
        address contractAddress;    // 실제 배포된 컨트랙트 주소
        string description;         // 컨트랙트에 대한 설명
    }

    // 등록된 컨트랙트 수
    uint public numContracts;

    // 등록한 컨트랙트들을 저장할 매핑(이름->컨트랙트 정보 구조체)
    mapping (string => ContractInfo) public registeredContracts;

    // 새 컨트랙트가 등록될 때 발생
    event ContractRegistered(
        string indexed name,           // 등록한 이름
        address indexed owner,         // 컨트랙트 Owner 주소
        address contractAddress,       // 컨트랙트 주소
        string description             // 설명
    );

    // 컨트랙트가 삭제(unregister)될 때 발생
    event ContractDeleted(
        string indexed name,           // 삭제된 이름
        address indexed owner,         // 삭제 당시 Owner
        address contractAddress        // 삭제된 컨트랙트 주소
    );

    // 컨트랙트 정보가 변경될 때 발생
    // 어떤 부분이 바뀌었는지(field)를 문자열로 남김
    // 예: "OwnerChanged", "AddressChanged", "DescriptionChanged"
    event ContractUpdated(
        string indexed name,           // 변경된 이름
        string field,                  // 어떤 변경인지 (Owner / Address / Description 등)
        address indexed owner,         // 변경 후 기준 Owner
        address contractAddress,       // 현재 컨트랙트 주소
        string description             // 현재 설명
    );

    // 특정 이름에 대한 Owner만 함수 호출을 허용하는 제어자
    modifier onlyOwner(string memory _name) {
        require(msg.sender == registeredContracts[_name].contractOwner, "YOU ARE NOT OWNER");
        _;
    }

    // 생성자: 처음 배포 시 컨트랙트 개수를 0으로 초기화
    constructor() {
        numContracts = 0;
    }

    // 컨트랙트 등록 함수
    function registerContract(
        string memory _name,        // 이름(키)
        address _contractAddress,   // 실제 컨트랙트 주소
        string memory _description  // 설명
    )
        public
    {
        if (_contractAddress != address(0)) {       // 주소가 0이 아닌 경우에만 유효한 등록으로 처리
            // msg.sender를 Owner로 하여 정보 저장
            registeredContracts[_name] = ContractInfo(msg.sender, _contractAddress, _description);

            // 전체 등록 개수 1 증가
            numContracts += 1;

            // 이벤트 발생: ContractRegistered
            emit ContractRegistered(_name, msg.sender, _contractAddress, _description);
        }
    }

    // 컨트랙트 등록 해제 함수
    function unregisterContract(string memory _name)
        public
        onlyOwner(_name)    // onlyOwner 제어자로 인해 해당 Owner만 삭제 가능
    {
        // 이벤트에 사용하기 위해 삭제 전 값들을 임시로 저장
        address oldOwner = registeredContracts[_name].contractOwner;
        address oldAddr = registeredContracts[_name].contractAddress;

        // 매핑에서 해당 이름 정보 삭제
        delete registeredContracts[_name];

        // 전체 등록 개수 1 감소
        numContracts -= 1;

        // 이벤트 발생: ContractDeleted
        emit ContractDeleted(_name, oldOwner, oldAddr);
    }

    // 컨트랙트 소유자 변경 (소유자만 가능)
    function changeOwner(string memory _name, address _newOwner)
        public
        onlyOwner(_name)
    {
        registeredContracts[_name].contractOwner = _newOwner;

        // 이벤트 발생: ContractUpdated (Owner 변경)
        emit ContractUpdated(
            _name,
            "OwnerChanged",
            registeredContracts[_name].contractOwner,
            registeredContracts[_name].contractAddress,
            registeredContracts[_name].description
        );
    }

    // 컨트랙트 소유자 정보 확인
    function getOwner(string memory _name) public view returns (address) {
        return registeredContracts[_name].contractOwner;
    }

    // 컨트랙트 어드레스 변경 (소유자만 가능)
    function setAddr(string memory _name, address _addr)
        public
        onlyOwner(_name)
    {
        registeredContracts[_name].contractAddress = _addr;

        // 이벤트 발생: ContractUpdated (Address 변경)
        emit ContractUpdated(
            _name,
            "AddressChanged",
            registeredContracts[_name].contractOwner,
            registeredContracts[_name].contractAddress,
            registeredContracts[_name].description
        );
    }

    // 컨트랙트 어드레스 확인
    function getAddr(string memory _name) public view returns (address) {
        return registeredContracts[_name].contractAddress;
    }

    // 컨트랙트 설명 변경 (소유자만 가능)
    function setDescription(string memory _name, string memory _description)
        public
        onlyOwner(_name)
    {
        registeredContracts[_name].description = _description;

        // 이벤트 발생: ContractUpdated (Description 변경)
        emit ContractUpdated(
            _name,
            "DescriptionChanged",
            registeredContracts[_name].contractOwner,
            registeredContracts[_name].contractAddress,
            registeredContracts[_name].description
        );
    }

    // 컨트랙트 설명 확인
    function getDescription(string memory _name) public view returns (string memory) {
        return registeredContracts[_name].description;
    }
}
