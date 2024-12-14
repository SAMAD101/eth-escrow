// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {Script} from "lib/forge-std/src/Script.sol";
import {console} from "lib/forge-std/src/console.sol";

import {Defender, ApprovalProcessResponse} from "lib/openzeppelin-foundry-upgrades/src/Defender.sol";
import {Upgrades, Options} from "lib/openzeppelin-foundry-upgrades/src/Upgrades.sol";

import {EscrowContract} from "src/Escrow.sol";

contract DefenderScript is Script {
    function setUp() public {}

    function run() public {
        ApprovalProcessResponse memory upgradeApprovalProcess = Defender.getUpgradeApprovalProcess();

        if (upgradeApprovalProcess.via == address(0)) {
            revert(string.concat("Upgrade approval process with id ", upgradeApprovalProcess.approvalProcessId, " has no assigned address"));
        }

        Options memory opts;
        opts.defender.useDefenderDeploy = false;

        address proxy = Upgrades.deployUUPSProxy(
            "Escrow.sol:EscrowContract",
            abi.encodeCall(EscrowContract.initialize, (payable(msg.sender))),
            opts
        );

        console.log("Deployed proxy to address", proxy);
    }
}