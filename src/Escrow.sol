// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.20;

import "lib/openzeppelin-contracts-upgradeable/contracts/proxy/utils/Initializable.sol";
import "lib/openzeppelin-contracts-upgradeable/contracts/token/ERC20/ERC20Upgradeable.sol";


contract BaseContract is Initializable {
    bool private initialized;

    function initialize() public onlyInitializing {
        require(!initialized, "Contract instance has already been initialized");
        initialized = true;
    }
}

contract Escrow is BaseContract {
    uint256 public x;

    function initialize(uint256 _x) public initializer {
        BaseContract.initialize();
        x = _x;
    }
}