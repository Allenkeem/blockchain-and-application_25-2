// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

contract ERC20StdToken {
    
    mapping (address => uint256) balances; // 각 주소의 토큰 보유량을 저장하는 매핑
    mapping (address => mapping(address => uint256)) allowed; // (owner → (spender → 허용량)) 구조의 매핑
    uint256 private total; // 총 발행량 저장 변수 (totalSupply)
    string public name; // 토큰 이름
    string public symbol; // 토큰 심볼
    uint public decimals; // 소수 자리 수

    // 토큰이 전송될 때마다 발생하는 이벤트
    event Transfer(address indexed from, address indexed to, uint256 value);
    // approve가 호출될 때마다 발생하는 이벤트
    event Approval(address indexed owner, address indexed spender, uint256 value);

    constructor(string memory _name, string memory _symbol, uint _totalSupply){
        total = _totalSupply; // 총 발행량 설정
        // 토큰 메타데이터 설정
        name = _name;
        symbol = _symbol;
        decimals = 0;
        balances[msg.sender] = _totalSupply; // 배포자에게 전체 물량 부여
        emit Transfer(address(0x0), msg.sender, _totalSupply); // 민트(생성)를 의미하는 Transfer 이벤트 (from = 0x0)
    }

    function totalSupply() public view returns (uint256){ // 전체 발행량 조회 함수
        return total;
    }
    function balanceOf(address _owner) public view returns(uint256 balance){ // 특정 주소의 잔액 조회 함수
        return balances[_owner];
    }
    function allowance(address _owner, address _spender) public view returns (uint256 remaining){ // owner가 spender에게 허용한 남은 토큰 양을 조회
        return allowed[_owner][_spender];
    }

    function transfer(address _to, uint256 _value) public returns (bool success){ // 내 지갑에서 _to 주소로 _value 만큼 전송
        require(balances[msg.sender] >= _value, "Value should be under balance"); // 1) 내 잔액이 충분한지 확인
        // 2) 오버플로우가 발생하지 않는지 확인
        if((balances[_to]+_value)>=balances[_to]){
            balances[msg.sender] -= _value; // 보내는 사람 잔액 감소
            balances[_to] += _value; // 받는 사람 잔액 증가
            emit Transfer(msg.sender, _to, _value); // Transfer 이벤트 발생
            return true;
        }
        else {
            return false;
        }        
    }

    // 제3자가(from의 허용을 받은 msg.sender)가 _from → _to 로 _value만큼 전송
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success){
        // 1) _from 주소의 잔액이 충분한지 확인
        require(balances[_from] >= _value, "Value should be under balance");
        // 2) _from이 msg.sender에게 허용한 allowance가 충분한지 확인
        require(allowed[_from][msg.sender] >= _value, "Value should be under allowance");

        // 3) 오버플로우 방지 조건
        if((balances[_to] + _value) >= balances[_to]){
            // _from 잔액 감소
            balances[_from] -= _value;
            // _to 잔액 증가
            balances[_to] += _value;
            // 사용한 만큼 allowance 감소
            allowed[_from][msg.sender] -= _value;

            // Transfer 이벤트 발생
            emit Transfer(_from, _to, _value);
            return true;
        }
        else{
            return false;
        }
    }

    // msg.sender(토큰 소유자)가 _spender에게 _value만큼 사용 권한을 부여하는 함수
    function approve(address _spender, uint256 _value) public returns (bool success){
        // _spender가 사용할 수 있는 한도 설정(덮어쓰기)
        allowed[msg.sender][_spender] = _value;
        // Approval 이벤트 발생
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

}