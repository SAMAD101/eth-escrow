// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "lib/openzeppelin-contracts-upgradeable/contracts/proxy/utils/UUPSUpgradeable.sol";
import "lib/openzeppelin-contracts-upgradeable/contracts/access/OwnableUpgradeable.sol";
import "lib/openzeppelin-contracts-upgradeable/contracts/utils/PausableUpgradeable.sol";
import "lib/openzeppelin-contracts-upgradeable/contracts/utils/ReentrancyGuardUpgradeable.sol";
import "lib/chainlink/contracts/src/v0.8/automation/interfaces/AutomationCompatibleInterface.sol";

contract BaseContract is 
    UUPSUpgradeable,
    OwnableUpgradeable,
    PausableUpgradeable,
    ReentrancyGuardUpgradeable,
    AutomationCompatibleInterface
{
    error InvalidAddress();
    error ZeroAmount();
    error AlreadySettled();
    error InvalidEscrow();
    error OnlyReceiver();
    error OnlySender();
    error TransferFailed();
    error TooEarly();
    error TooLate();

    uint256 constant public CLAIM_TIMEOUT = 30 days;
    
    bool public initialized;
    
    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}

    function checkUpkeep(bytes calldata) 
        external 
        view 
        virtual 
        override 
        returns (bool upkeepNeeded, bytes memory performData) {
        return (false, "");
    }

    function performUpkeep(bytes calldata) external virtual override {}

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }
}