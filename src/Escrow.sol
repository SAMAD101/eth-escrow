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
        BaseContract.initialize();
        __Pausable_init();
        __Ownable_init(initialOwner);
        __ReentrancyGuard_init();
    }

    function createEscrow(
        address payable _receiver
    ) external payable nonReentrant whenNotPaused returns (bytes32) {
        require(_receiver != address(0), "Invalid receiver address");
        require(msg.value > 0, "Amount must be greater than 0");

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

    function claimEscrow(bytes32 _escrowId) external nonReentrant {
        Escrow storage escrow = escrows[_escrowId];
        require(msg.sender == escrow.receiver, "Only receiver can claim funds");
        require(!escrow.isClaimed && !escrow.isRefunded, "Escrow already settled");
        require(escrow.amount > 0, "Invalid escrow");

        escrow.isClaimed = true;
        emit EscrowClaimed(_escrowId);

        (bool success, ) = escrow.receiver.call{value: escrow.amount}("");
        require(success, "Transfer to receiver failed");
    }

    function refundEscrow(bytes32 _escrowId) external nonReentrant {
        Escrow storage escrow = escrows[_escrowId];
        require(msg.sender == escrow.sender, "Only sender can get the refund");
        require(!escrow.isClaimed && !escrow.isRefunded, "Escrow already settled");
        require(escrow.amount > 0, "Invalid escrow");

        escrow.isRefunded = true;
        emit EscrowRefunded(_escrowId);

        (bool success, ) = escrow.sender.call{value: escrow.amount}("");
        require(success, "Transfer to sender failed");
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

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }
}