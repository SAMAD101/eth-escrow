// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "lib/openzeppelin-contracts-upgradeable/contracts/proxy/utils/UUPSUpgradeable.sol";
import "lib/openzeppelin-contracts-upgradeable/contracts/access/OwnableUpgradeable.sol";
import "lib/openzeppelin-contracts-upgradeable/contracts/utils/PausableUpgradeable.sol";
import "lib/openzeppelin-contracts-upgradeable/contracts/utils/ReentrancyGuardUpgradeable.sol";
import "lib/chainlink/contracts/src/v0.8/automation/AutomationCompatible.sol";

contract BaseContract is 
    UUPSUpgradeable,
    OwnableUpgradeable,
    PausableUpgradeable,
    ReentrancyGuardUpgradeable,
    AutomationCompatibleUpgradeable
{
    error InvalidAddress();
    error ZeroAmount();
    error AlreadySettled();
    error InvalidEscrow();
    error OnlyReceiver();
    error OnlySender();
    error TransferFailed();

    uint256 constant public CLAIM_TIMEOUT = 30 days;

    function initialize(address initialOwner) public onlyInitializing {
        require(!initialized, "Contract instance has already been initialized");
        __UUPSUpgradeable_init();
        __Ownable_init(initialOwner);
        __Pausable_init();
        __ReentrancyGuard_init();
    }

    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }
}