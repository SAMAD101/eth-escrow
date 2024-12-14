// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";

import {EscrowContract} from "src/Escrow.sol";
import {ERC20EscrowContract} from "src/ERC20Escrow.sol";

contract DeployScript is Script {
    function run() external returns (address) {
        vm.startBroadcast();
        
        EscrowContract escrow = new EscrowContract();
        escrow.initialize(msg.sender);
        
        ERC20EscrowContract tokenEscrow = new ERC20EscrowContract();
        tokenEscrow.initialize(msg.sender);
        
        vm.stopBroadcast();
        
        return address(escrow);
    }
}
