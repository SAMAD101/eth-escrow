pragma solidity ^0.8.20;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";

import {Defender, ApprovalProcessResponse} from "openzeppelin-foundry-upgrades/Defender.sol";
import {Upgrades, Options} from "openzeppelin-foundry-upgrades/Upgrades.sol";

import {Escrow} from "../src/Escrow.sol";

contract DefenderScript is Script {
    function setUp() public {}

    function run() public {
        ApprovalProcessResponse memory upgradeApprovalProcess = Defender.getUpgradeApprovalProcess();

        if (upgradeApprovalProcess.via == address(0)) {
            revert(string.concat("Upgrade approval process with id ", upgradeApprovalProcess.approvalProcessId, " has no assigned address"));
        }

        Options memory opts;
        opts.defender.useDefenderDeploy = true;

        address proxy = Upgrades.deployUUPSProxy(
            "Escrow.sol",
            abi.encodeCall(MyContract.initialize, ("Hello World", upgradeApprovalProcess.via)),
            opts
        );

        console.log("Deployed proxy to address", proxy);
    }
}