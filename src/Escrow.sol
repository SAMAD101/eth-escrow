// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {BaseContract} from "./BaseContract.sol";

contract EscrowContract is BaseContract {
    struct Escrow {
        address payable sender;
        address payable receiver;
        uint256 amount;
        bool isClaimed;
        bool isRefunded;
        uint256 createdAt;
    }

    mapping(bytes32 => Escrow) public escrows;
    uint256 public escrowCount;

    event EscrowCreated(
        bytes32 indexed escrowId,
        address indexed sender,
        address indexed receiver,
        uint256 amount
    );
    event EscrowClaimed(bytes32 indexed escrowId);
    event EscrowRefunded(bytes32 indexed escrowId);

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(address initialOwner) public initializer {
        BaseContract.initialize(initialOwner);
    }

    function createEscrow(
        address payable _receiver
    ) external payable nonReentrant whenNotPaused returns (bytes32) {
        if (_receiver == address(0)) revert InvalidAddress();
        if (msg.value == 0) revert ZeroAmount();

        bytes32 escrowId = keccak256(
            abi.encodePacked(
                msg.sender,
                _receiver,
                msg.value,
                block.timestamp,
                escrowCount++
            )
        );

        escrows[escrowId] = Escrow({
            sender: payable(msg.sender),
            receiver: _receiver,
            amount: msg.value,
            isClaimed: false,
            isRefunded: false,
            createdAt: block.timestamp
        });

        emit EscrowCreated(escrowId, msg.sender, _receiver, msg.value);
        return escrowId;
    }

    function claimEscrow(bytes32 _escrowId) external nonReentrant whenNotPaused {
        Escrow storage escrow = escrows[_escrowId];
        if (msg.sender != escrow.receiver) revert OnlyReceiver();
        if (escrow.isClaimed || escrow.isRefunded) revert AlreadySettled();
        if (escrow.amount == 0) revert InvalidEscrow();

        (bool success, ) = escrow.receiver.call{value: escrow.amount}("");
        if (!success) revert TransferFailed();

        escrow.isClaimed = true;
        emit EscrowClaimed(_escrowId);
    }

    function refundEscrow(bytes32 _escrowId) external nonReentrant whenNotPaused {
        Escrow storage escrow = escrows[_escrowId];
        if (msg.sender != escrow.sender) revert OnlySender();
        if (escrow.isClaimed || escrow.isRefunded) revert AlreadySettled();
        if (escrow.amount == 0) revert InvalidEscrow();

        (bool success, ) = escrow.sender.call{value: escrow.amount}("");
        if (!success) revert TransferFailed();
        
        escrow.isRefunded = true;
        emit EscrowRefunded(_escrowId);
    }

    function getEscrow(bytes32 _escrowId) 
        external 
        view 
        returns (
            address sender,
            address receiver,
            uint256 amount,
            bool isClaimed,
            bool isRefunded,
            uint256 createdAt
        ) 
    {
        Escrow storage escrow = escrows[_escrowId];
        return (
            escrow.sender,
            escrow.receiver,
            escrow.amount,
            escrow.isClaimed,
            escrow.isRefunded,
            escrow.createdAt
        );
    }
}