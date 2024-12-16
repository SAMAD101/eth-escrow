# eth-escrow

A gas efficient solidity smart contract for an escrow on ethereum. Supports ERC20 tokens.

## Features:
- Allows the sender to designate a set amount of ETH (or an ERC20 token).
- The recipient user can claim or refund back to the sender the designated amount of ETH (or an ERC20 token). Automated refunds using Chainlink.
- Unclaimed funds automatically gets refunded back to the sender.
- Upgradable contract, uses UUPS.
- Reentrancy protection.

## Implementation:
- Uses [Foundary framework](https://book.getfoundry.sh/) for development and testing
- Uses [OpenZeppelin](https://www.openzeppelin.com/) for safe and secure smart contracts and upgradability
- Comprehensive test suite
- Secure, maintainable, and modular Solidity code, with great organization
- Follows best practices and style guide for Solidity

## Setup

1. Clone the repository

```bash
git clone https://github.com/SAMAD101/eth-escrow.git
```

2. Environment variables

- SEPOLIA_RPC_URL
- PRIVATE_KEY

3. Build and deploy

```bash
forge script script/DefenderScript.s.sol --force --rpc-url $SEPOLIA_RPC_URL
```

## Tests

to be added...