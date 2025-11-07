// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.7.0 <0.9.0;

contract NameRegistry{

    struct ContractInfo{
        address contractOwner;
        address contractAddress;
        string description;
    }

    uint public numContracts;
    mapping (string => ContractInfo) public registeredContracts;

    modifier onlyOwner(string memory _name){
        require(msg.sender == registeredContracts[_name].contractOwner, "You are not owner");
        _;
    }

    constructor(){
        numContracts = 0;
    }

    function registerContract(string memory _name,
                            address _contractAddress,
                            string memory _description) public {
        if(_contractAddress != address(0)){
            registeredContracts[_name] = ContractInfo(msg.sender, _contractAddress, _description);
        }
        numContracts += 1;
    }
    function unregisterContract(string memory _name) onlyOwner(_name) public {
        delete(registeredContracts[_name]);
        numContracts -= 1;
    }

    function changeOwner(string memory _name, address _newOwner) onlyOwner(_name) public {
        registeredContracts[_name].contractOwner = _newOwner;
    }
    
    function getOwner(string memory _name) public view returns(address){
        return registeredContracts[_name].contractOwner;
    }

    function setAddr(string memory _name, address _addr) onlyOwner(_name) public {
        registeredContracts[_name].contractAddress = _addr;
    }

    function getAddr(string memory _name) public view returns(address){
        return registeredContracts[_name].contractAddress;
    }

    function setDescription(string memory _name, string memory _description) onlyOwner(_name) public {
        registeredContracts[_name].description = _description;
    }

    function getDescription(string memory _name) public view returns(string memory){
        return registeredContracts[_name].description;
    }

}