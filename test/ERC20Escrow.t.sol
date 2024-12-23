// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {Test, console} from "lib/forge-std/src/Test.sol";

import {ERC20MockUpgradeable} from "lib/openzeppelin-contracts-upgradeable/contracts/mocks/token/ERC20MockUpgradeable.sol";
import {Upgrades} from "lib/openzeppelin-foundry-upgrades/src/Upgrades.sol";

import {ERC20EscrowContract} from "src/ERC20Escrow.sol";

contract ERC20EscrowTest is Test {
    ERC20EscrowContract public escrow;
    ERC20MockUpgradeable public token;
    address payable public owner;
    address payable public sender;
    address payable public receiver;
    uint256 public constant ESCROW_AMOUNT = 100 * 10**18;

    event TokenEscrowCreated(
        bytes32 indexed escrowId,
        address sender,
        address receiver,
        address tokenAddress,
        uint256 amount
    );

    function setUp() public {
        // Setup accounts
        owner = payable(address(this));
        sender = payable(address(0x1));
        receiver = payable(address(0x2));
        
        // Deploy token
        token = new ERC20MockUpgradeable();
        token.mint(address(this), ESCROW_AMOUNT * 2);

        // Deploy escrow contract
        escrow = ERC20EscrowContract(Upgrades.deployUUPSProxy(
            "ERC20Escrow.sol:ERC20EscrowContract",
            abi.encodeCall(ERC20EscrowContract.initialize, (owner))
        ));
        
        // Fund sender with tokens
        token.transfer(sender, ESCROW_AMOUNT * 2);
    }

    function test_CreateTokenEscrow() public {
        // Switch to sender context
        vm.startPrank(sender);
        
        // Approve tokens
        token.approve(address(escrow), ESCROW_AMOUNT);
        
        // Create escrow and expect event
        vm.expectEmit(true, true, true, true);
        bytes32 expectedId = keccak256(
            abi.encodePacked(
                sender,
                receiver,
                address(token),
                uint256(ESCROW_AMOUNT),
                block.timestamp
            )
        );
        emit TokenEscrowCreated(expectedId, sender, receiver, address(token), ESCROW_AMOUNT);
        
        bytes32 escrowId = escrow.createTokenEscrow(receiver, address(token), ESCROW_AMOUNT);
        
        // Verify escrow details
        (
            address _sender,
            address _receiver,
            address _tokenAddress,
            uint256 _amount,
            bool _isClaimed,
            bool _isRefunded,
            uint256 _createdAt
        ) = escrow.getTokenEscrow(escrowId);

        assertEq(_sender, sender);
        assertEq(_receiver, receiver);
        assertEq(_tokenAddress, address(token));
        assertEq(_amount, ESCROW_AMOUNT);
        assertFalse(_isClaimed);
        assertFalse(_isRefunded);
        assertEq(_createdAt, block.timestamp);
        
        // Verify token transfer
        assertEq(token.balanceOf(address(escrow)), ESCROW_AMOUNT);
        
        vm.stopPrank();
    }

    function test_ClaimTokenEscrow() public {
        // Create escrow first
        vm.startPrank(sender);
        token.approve(address(escrow), ESCROW_AMOUNT);
        bytes32 escrowId = escrow.createTokenEscrow(receiver, address(token), ESCROW_AMOUNT);
        vm.stopPrank();

        // Switch to receiver context and claim
        vm.startPrank(receiver);
        uint256 balanceBefore = token.balanceOf(receiver);
        
        escrow.claimTokenEscrow(escrowId);
        
        assertEq(token.balanceOf(receiver), balanceBefore + ESCROW_AMOUNT);
        
        // Verify escrow is claimed
        (,,,,bool isClaimed,,) = escrow.getTokenEscrow(escrowId);
        assertTrue(isClaimed);
        
        vm.stopPrank();
    }

    function test_RefundExpiredTokenEscrow() public {
        // Create escrow
        vm.startPrank(sender);
        token.approve(address(escrow), ESCROW_AMOUNT);
        bytes32 escrowId = escrow.createTokenEscrow(receiver, address(token), ESCROW_AMOUNT);
        vm.stopPrank();

        uint256 senderBalanceBefore = token.balanceOf(sender);

        // Warp time past timeout
        vm.warp(block.timestamp + 31 days);

        // Verify upkeep is needed
        (bool upkeepNeeded, bytes memory performData) = escrow.checkUpkeep("");
        assertTrue(upkeepNeeded);
        
        // Perform upkeep (simulate Chainlink keeper)
        vm.prank(address(0x123));
        escrow.performUpkeep(performData);

        // Verify escrow is refunded
        (,,,,bool isClaimed, bool isRefunded,) = escrow.getTokenEscrow(escrowId);
        assertFalse(isClaimed);
        assertTrue(isRefunded);
        
        // Verify tokens returned to sender
        assertEq(token.balanceOf(sender), senderBalanceBefore + ESCROW_AMOUNT);
    }

    function test_ClaimExpiredTokenEscrow() public {
        // Create escrow
        vm.startPrank(sender);
        token.approve(address(escrow), ESCROW_AMOUNT);
        bytes32 escrowId = escrow.createTokenEscrow(receiver, address(token), ESCROW_AMOUNT);
        vm.stopPrank();

        // Warp time past timeout
        vm.warp(block.timestamp + 31 days);

        // Try to claim (should fail)
        vm.prank(receiver);
        vm.expectRevert();
        escrow.claimTokenEscrow(escrowId);
    }

    function test_ReclaimTokenEscrow() public {
        // Create and claim escrow
        vm.startPrank(sender);
        token.approve(address(escrow), ESCROW_AMOUNT);
        bytes32 escrowId = escrow.createTokenEscrow(receiver, address(token), ESCROW_AMOUNT);
        vm.stopPrank();
        
        vm.prank(receiver);
        escrow.claimTokenEscrow(escrowId);
        
        // Try to claim again (should fail)
        vm.prank(receiver);
        vm.expectRevert();
        escrow.claimTokenEscrow(escrowId);
    }
}