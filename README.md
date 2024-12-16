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
- ETHERSCAN_API_KEY

3. Build and deploy

```bash
forge script script/DefenderScript.s.sol --force --rpc-url $SEPOLIA_RPC_URL --broadcast
```

4. Verify contract

```bash
forge verify-contract 0x35e72418cD57d1dF7129291EE4E23Dc6e1aB6d6D src/Escrow.sol:EscrowContract \                                                          [19:03:35]
--watch \
--chain-id 11155111 \
--etherscan-api-key $ETHERSCAN_API_KEY
```

5. Make upkeep on Chainlink for the `Escrow` and `ERC20Escrow` contracts for the automated refunds.

Go to https://automation.chain.link/ and register a new Upkeep (Time-based) for both of the contracts.

## Tests

1. Build

```bash
forge build
```

2. Run tests

```bash
forge test
```
