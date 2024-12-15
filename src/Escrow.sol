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

    bytes32[] public activeEscrows;
    mapping(bytes32 => Escrow) public escrows;
    mapping(bytes32 => uint256) public escrowIdToIndex;
    uint256 public escrowCount;

    event EscrowCreated(
        bytes32 indexed escrowId,
        address sender,
        address receiver,
        uint256 amount
    );
    event EscrowClaimed(bytes32 indexed escrowId);
    event EscrowRefunded(bytes32 indexed escrowId);

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(address initialOwner) public initializer {
        __UUPSUpgradeable_init();
        __Ownable_init(initialOwner);
        __Pausable_init();
        __ReentrancyGuard_init();
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
                block.timestamp
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
        escrowIdToIndex[escrowId] = activeEscrows.length;
        activeEscrows.push(escrowId);
        escrowCount++;

        emit EscrowCreated(escrowId, msg.sender, _receiver, msg.value);
        return escrowId;
    }

    function checkUpkeep(bytes calldata) 
        external 
        view 
        override 
        returns (bool upkeepNeeded, bytes memory performData) {
        for (uint i = 0; i < activeEscrows.length; i++) {
            bytes32 escrowId = activeEscrows[i];
            Escrow storage escrow = escrows[escrowId];
            if (!escrow.isClaimed && !escrow.isRefunded && 
                block.timestamp > escrow.createdAt + CLAIM_TIMEOUT) {
                return (true, abi.encode(escrowId));
            }
        }
        return (false, "");
    }

    function performUpkeep(bytes calldata performData) external override {
        bytes32 escrowId = abi.decode(performData, (bytes32));
        Escrow storage escrow = escrows[escrowId];

        if (msg.sender != escrow.sender) revert OnlySender();
        if (escrow.isClaimed || escrow.isRefunded) revert AlreadySettled();
        if (escrow.amount == 0) revert InvalidEscrow();
        if (block.timestamp <= escrow.createdAt + CLAIM_TIMEOUT) revert TooEarly();

        (bool success, ) = escrow.sender.call{value: escrow.amount}("");
        if (!success) revert TransferFailed();
        
        // Remove from active escrows
        uint256 index = escrowIdToIndex[escrowId];
        uint256 lastIndex = activeEscrows.length - 1;
        if (index != lastIndex) {
            bytes32 lastEscrowId = activeEscrows[lastIndex];
            activeEscrows[index] = lastEscrowId;
            escrowIdToIndex[lastEscrowId] = index;
        }
        activeEscrows.pop();

        escrow.isRefunded = true;
        emit EscrowRefunded(escrowId);
    }

    function claimEscrow(bytes32 _escrowId) external nonReentrant whenNotPaused {
        Escrow storage escrow = escrows[_escrowId];
        if (msg.sender != escrow.receiver) revert OnlyReceiver();
        if (escrow.isClaimed || escrow.isRefunded) revert AlreadySettled();
        if (escrow.amount == 0) revert InvalidEscrow();

        (bool success, ) = escrow.receiver.call{value: escrow.amount}("");
        if (!success) revert TransferFailed();

        // remove escrow from activeEscrows
        uint256 index = escrowIdToIndex[_escrowId];
        uint256 lastIndex = activeEscrows.length - 1;
        if (index != lastIndex) {
            bytes32 lastEscrowId = activeEscrows[lastIndex];
            activeEscrows[index] = lastEscrowId;
            escrowIdToIndex[lastEscrowId] = index;
        }
        activeEscrows.pop();

        escrow.isClaimed = true;
        emit EscrowClaimed(_escrowId);
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