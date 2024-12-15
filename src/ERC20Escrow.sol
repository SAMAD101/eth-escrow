// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "lib/openzeppelin-contracts-upgradeable/contracts/token/ERC20/ERC20Upgradeable.sol";

import {BaseContract} from "./BaseContract.sol";

contract ERC20EscrowContract is BaseContract, ERC20Upgradeable {
    struct TokenEscrow {
        address payable sender;
        address payable receiver;
        address tokenAddress;
        uint256 amount;
        bool isClaimed;
        bool isRefunded;
        uint256 createdAt;
    }

    bytes32[] public activeEscrows;
    mapping(bytes32 => TokenEscrow) public escrows;
    uint256 public escrowCount;

    event TokenEscrowCreated(
        bytes32 indexed escrowId,
        address sender,
        address receiver,
        address tokenAddress,
        uint256 amount
    );
    event TokenEscrowClaimed(bytes32 indexed escrowId);
    event TokenEscrowRefunded(bytes32 indexed escrowId);

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(address initialOwner) public initializer {
        BaseContract.initialize(initialOwner);
    }

    function createTokenEscrow(
        address payable _receiver,
        address _tokenAddress,
        uint256 _amount
    ) external nonReentrant whenNotPaused returns (bytes32) {
        if (_receiver == address(0)) revert InvalidAddress();
        if (_tokenAddress == address(0)) revert InvalidAddress();
        if (_amount == 0) revert ZeroAmount();

        bytes32 escrowId = keccak256(
            abi.encodePacked(
                msg.sender,
                _receiver,
                _tokenAddress,
                _amount,
                block.timestamp,
                escrowCount
            )
        );

        unchecked {escrowCount++;}

        // transferFrom tokens from sender to this contract
        ERC20Upgradeable token = ERC20Upgradeable(_tokenAddress);
        bool success = token.transferFrom(msg.sender, address(this), _amount);
        if (!success) revert TransferFailed();

        escrows[escrowId] = TokenEscrow({
            sender: payable(msg.sender),
            receiver: _receiver,
            tokenAddress: _tokenAddress,
            amount: _amount,
            isClaimed: false,
            isRefunded: false,
            createdAt: block.timestamp
        });
        activeEscrows.push(escrowId);

        emit TokenEscrowCreated(escrowId, msg.sender, _receiver, _tokenAddress, _amount);
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

        ERC20Upgradeable token = ERC20Upgradeable(escrow.tokenAddress);
        bool success = token.transfer(escrow.sender, escrow.amount);
        if (!success) revert TransferFailed();
        
        // Remove from active escrows
        uint256 index = escrowIndex[escrowId];
        bytes32 lastEscrowId = activeEscrows[activeEscrows.length - 1];
        activeEscrows[index] = lastEscrowId;
        escrowIndex[lastEscrowId] = index;
        activeEscrows.pop();

        escrow.isRefunded = true;
        emit EscrowRefunded(escrowId);
    }

    function claimTokenEscrow(bytes32 _escrowId) external nonReentrant whenNotPaused {
        TokenEscrow storage escrow = escrows[_escrowId];
        if (msg.sender != escrow.receiver) revert OnlyReceiver();
        if (escrow.isClaimed || escrow.isRefunded) revert AlreadySettled();
        if (escrow.amount == 0) revert InvalidEscrow();
        
        ERC20Upgradeable token = ERC20Upgradeable(escrow.tokenAddress);
        bool success = token.transfer(escrow.receiver, escrow.amount);
        if (!success) revert TransferFailed();

        escrow.isClaimed = true;
        emit TokenEscrowClaimed(_escrowId);
    }

    function getTokenEscrow(bytes32 _escrowId) 
        external 
        view 
        returns (
            address sender,
            address receiver,
            address tokenAddress,
            uint256 amount,
            bool isClaimed,
            bool isRefunded,
            uint256 createdAt
        ) 
    {
        TokenEscrow storage escrow = escrows[_escrowId];
        return (
            escrow.sender,
            escrow.receiver,
            escrow.tokenAddress,
            escrow.amount,
            escrow.isClaimed,
            escrow.isRefunded,
            escrow.createdAt
        );
    }
}