// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {Script} from "lib/forge-std/src/Script.sol";
import {console} from "lib/forge-std/src/console.sol";

import {Upgrades, Options} from "lib/openzeppelin-foundry-upgrades/src/Upgrades.sol";

import {EscrowContract} from "src/Escrow.sol";
import {ERC20EscrowContract} from "src/ERC20Escrow.sol";

contract DefenderScript is Script {
    function setUp() public {}

    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        // Deploy ETH Escrow
        address ethEscrowProxy = Upgrades.deployUUPSProxy(
            "Escrow.sol:EscrowContract",
            abi.encodeCall(EscrowContract.initialize, (payable(msg.sender)))
        );

        console.log("Deployed ETH Escrow proxy to address", ethEscrowProxy);

        // Deploy ERC20 Escrow
        address erc20EscrowProxy = Upgrades.deployUUPSProxy(
            "ERC20Escrow.sol:ERC20EscrowContract",
            abi.encodeCall(ERC20EscrowContract.initialize, (payable(msg.sender)))
        );

        console.log("Deployed ERC20 Escrow proxy to address", erc20EscrowProxy);
    }
}