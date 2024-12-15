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

    mapping(bytes32 => TokenEscrow) public escrows;
    uint256 public escrowCount;

    event TokenEscrowCreated(
        bytes32 indexed escrowId,
        address indexed sender,
        address indexed receiver,
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
        require(_receiver != address(0), "Invalid receiver address");
        require(_tokenAddress != address(0), "Invalid token address");
        require(_amount > 0, "Amount must be greater than 0");

        bytes32 escrowId = keccak256(
            abi.encodePacked(
                msg.sender,
                _receiver,
                _tokenAddress,
                _amount,
                block.timestamp,
                escrowCount++
            )
        );

        // transferFrom tokens from sender to this contract
        ERC20Upgradeable token = ERC20Upgradeable(_tokenAddress);
        token.transferFrom(msg.sender, address(this), _amount);

        escrows[escrowId] = TokenEscrow({
            sender: payable(msg.sender),
            receiver: _receiver,
            tokenAddress: _tokenAddress,
            amount: _amount,
            isClaimed: false,
            isRefunded: false,
            createdAt: block.timestamp
        });

        emit TokenEscrowCreated(escrowId, msg.sender, _receiver, _tokenAddress, _amount);
        return escrowId;
    }

    function claimTokenEscrow(bytes32 _escrowId) external nonReentrant whenNotPaused {
        TokenEscrow storage escrow = escrows[_escrowId];
        require(msg.sender == escrow.receiver, "Only receiver can claim tokens");
        require(!escrow.isClaimed && !escrow.isRefunded, "Escrow already settled");
        require(escrow.amount > 0, "Invalid escrow");

        escrow.isClaimed = true;
        
        ERC20Upgradeable token = ERC20Upgradeable(escrow.tokenAddress);
        token.transfer(escrow.receiver, escrow.amount);
        
        emit TokenEscrowClaimed(_escrowId);
    }

    function refundTokenEscrow(bytes32 _escrowId) external nonReentrant whenNotPaused {
        TokenEscrow storage escrow = escrows[_escrowId];
        require(msg.sender == escrow.sender, "Only sender can get the refund");
        require(!escrow.isClaimed && !escrow.isRefunded, "Escrow already settled");
        require(escrow.amount > 0, "Invalid escrow");

        escrow.isRefunded = true;
        
        ERC20Upgradeable token = ERC20Upgradeable(escrow.tokenAddress);
        token.transfer(escrow.sender, escrow.amount);
        
        emit TokenEscrowRefunded(_escrowId);
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