// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {Test, console} from "lib/forge-std/src/Test.sol";
import {Upgrades} from "lib/openzeppelin-foundry-upgrades/src/Upgrades.sol";

import {EscrowContract} from "src/Escrow.sol";

contract EscrowTest is Test {
    EscrowContract public escrow;
    address payable public owner;
    address payable public sender;
    address payable public receiver;
    uint256 public constant ESCROW_AMOUNT = 1 ether;

    event EscrowCreated(
        bytes32 indexed escrowId,
        address sender,
        address receiver,
        uint256 amount
    );

    function setUp() public {
        // Setup accounts
        owner = payable(address(this));
        sender = payable(address(0x1));
        receiver = payable(address(0x2));
        
        // Deploy contract
        escrow = EscrowContract(Upgrades.deployUUPSProxy(
            "Escrow.sol:EscrowContract",
            abi.encodeCall(EscrowContract.initialize, (owner))
        ));
        
        // Fund accounts
        vm.deal(sender, 100 ether);
    }

    function test_CreateEscrow() public {
        // Switch to sender context
        vm.startPrank(sender);
        
        // Create escrow and expect event
        vm.expectEmit(true, true, true, true);
        bytes32 expectedId = keccak256(
            abi.encodePacked(
                sender,
                receiver,
                uint256(ESCROW_AMOUNT),
                block.timestamp
            )
        );
        emit EscrowCreated(expectedId, sender, receiver, ESCROW_AMOUNT);
        
        bytes32 escrowId = escrow.createEscrow{value: ESCROW_AMOUNT}(receiver);
        
        // Verify escrow details
        (
            address _sender,
            address _receiver,
            uint256 _amount,
            bool _isClaimed,
            bool _isRefunded,
            uint256 _createdAt
        ) = escrow.getEscrow(escrowId);

        assertEq(_sender, sender);
        assertEq(_receiver, receiver);
        assertEq(_amount, ESCROW_AMOUNT);
        assertFalse(_isClaimed);
        assertFalse(_isRefunded);
        assertEq(_createdAt, block.timestamp);
        
        vm.stopPrank();
    }

    function test_ClaimEscrow() public {
        // Create escrow first
        vm.startPrank(sender);
        bytes32 escrowId = escrow.createEscrow{value: ESCROW_AMOUNT}(receiver);
        vm.stopPrank();

        // Switch to receiver context and claim
        vm.startPrank(receiver);
        uint256 balanceBefore = receiver.balance;
        
        escrow.claimEscrow(escrowId);
        
        assertEq(receiver.balance, balanceBefore + ESCROW_AMOUNT);
        
        // Verify escrow is claimed
        (,,, bool isClaimed,,) = escrow.getEscrow(escrowId);
        assertTrue(isClaimed);
        
        vm.stopPrank();
    }

    function test_RefundExpiredEscrow() public {
        // Create escrow
        vm.startPrank(sender);
        bytes32 escrowId = escrow.createEscrow{value: ESCROW_AMOUNT}(receiver);
        vm.stopPrank();

        // Warp time past timeout
        vm.warp(block.timestamp + 31 days);

        // Verify upkeep is needed
        (bool upkeepNeeded, bytes memory performData) = escrow.checkUpkeep("");
        assertTrue(upkeepNeeded);
        
        // Perform upkeep (simulate Chianlink keeper)
        vm.prank(address(0x123));
        escrow.performUpkeep(performData);

        // Verify escrow is refunded
        (,,, bool isClaimed, bool isRefunded,) = escrow.getEscrow(escrowId);
        assertFalse(isClaimed);
        assertTrue(isRefunded);
    }

    function testFail_ClaimExpiredEscrow() public {
        // Create escrow
        vm.startPrank(sender);
        bytes32 escrowId = escrow.createEscrow{value: ESCROW_AMOUNT}(receiver);
        vm.stopPrank();

        // Warp time past timeout
        vm.warp(block.timestamp + 31 days);

        // Try to claim (should fail)
        vm.prank(receiver);
        escrow.claimEscrow(escrowId);
    }

    function testFail_ReclaimEscrow() public {
        // Create and claim escrow
        vm.prank(sender);
        bytes32 escrowId = escrow.createEscrow{value: ESCROW_AMOUNT}(receiver);
        
        vm.prank(receiver);
        escrow.claimEscrow(escrowId);
        
        // Try to claim again (should fail)
        vm.prank(receiver);
        escrow.claimEscrow(escrowId);
    }
}