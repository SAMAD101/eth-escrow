// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.13;

event Deposited(address indexed _from, uint _value);
event claimed(address indexed _to, uint _value);

contract Escrow {
    address payable public sender;
    address payable public recipient;

    struct Vault {
        uint amount;
        address sender;
        address recipient;
    }    

    function deposit(uint amount) public payable{
        

        emit Deposited(msg.sender, msg.value);
    }

    function withdraw() public payable {
        
        emit claimed(msg.sender, msg.value);
    }
}