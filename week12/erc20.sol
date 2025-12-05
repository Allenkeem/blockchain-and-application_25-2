// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

contract ERC20StdToken {
    // 각 계정의 토큰 잔액
    mapping (address => uint256) balances;

    // allowed[owner][spender] : owner가 spender에게 위임한 토큰 수
    mapping (address => mapping (address => uint256)) allowed;

    uint256 private total;   // 총 발행 토큰 수

    string public name;      // 토큰 이름
    string public symbol;    // 토큰 심볼
    uint8 public decimals;   // 소수점 자리수

    // 이벤트 (슬라이드 그대로)
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    // ----------------- constructor -----------------
    constructor (string memory _name,
                 string memory _symbol,
                 uint _totalSupply) {
        total = _totalSupply;
        name = _name;
        symbol = _symbol;
        decimals = 0;

        // 전체 발행량을 배포자에게 지급
        balances[msg.sender] = _totalSupply;

        // 발행을 Transfer 이벤트로 기록 (from = 0x0)
        emit Transfer(address(0x0), msg.sender, _totalSupply);
    }

    // ----------------- view 함수 3개 -----------------

    // totalSupply()
    function totalSupply() public view returns (uint256) {
        return total;
    }

    // balanceOf(address _owner)
    function balanceOf(address _owner) public view returns (uint256 balance) {
        return balances[_owner];
    }

    // allowance(address _owner, address _spender)
    function allowance(address _owner, address _spender)
        public
        view
        returns (uint256 remaining)
    {
        return allowed[_owner][_spender];
    }

    // ----------------- transfer -----------------
    // 직접 전송
    function transfer(address _to, uint256 _value)
        public
        returns (bool success)
    {
        // 잔액 검증
        require(balances[msg.sender] >= _value, "insufficient balance");

        // overflow 검사 (솔리디티 0.8 이상에서는 자동이지만, 슬라이드 스타일대로)
        require(balances[_to] + _value >= balances[_to], "overflow");

        // 토큰 이전 (from 잔액 조정)
        balances[msg.sender] -= _value;

        // 토큰 이전 (to 잔액 조정)
        balances[_to] += _value;

        // 이벤트 발생
        emit Transfer(msg.sender, _to, _value);

        return true;
    }

    // ----------------- transferFrom -----------------
    // 위임 전송
    function transferFrom(address _from, address _to, uint256 _value)
        public
        returns (bool success)
    {
        // _from에게 토큰이 충분해야 함
        require(balances[_from] >= _value, "insufficient balance");

        // _from이 msg.sender에게 허용한 allowance가 충분해야 함
        require(allowed[_from][msg.sender] >= _value, "allowance exceeded");

        // overflow 검사
        require(balances[_to] + _value >= balances[_to], "overflow");

        // 토큰 이전 (from 잔액 조정)
        balances[_from] -= _value;

        // 토큰 이전 (to 잔액 조정)
        balances[_to] += _value;

        // 토큰 이전 (allowance 잔액 조정)
        allowed[_from][msg.sender] -= _value;

        // 이벤트 발생
        emit Transfer(_from, _to, _value);

        return true;
    }

    // ----------------- approve -----------------
    // 특정 주소에게 토큰 사용 권한 부여
    function approve(address _spender, uint256 _value)
        public
        returns (bool success)
    {
        // allowance 지정
        allowed[msg.sender][_spender] = _value;

        // 이벤트 발생
        emit Approval(msg.sender, _spender, _value);

        return true;
    }
}
