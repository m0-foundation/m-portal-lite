# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

M Portal Lite is a cross-chain bridging system for the M0 Protocol's $M token, enabling multichain yield-earning capabilities. It uses a hub-and-spoke architecture where Ethereum serves as the hub chain, and other EVM chains are spokes. This is a simplified version of M Portal supporting only EVM chains in a one-to-many model (spokes can only communicate with the hub, not each other).

## Build and Test Commands

```bash
# Install dependencies
forge install

# Build contracts
forge build

# Run all tests
forge test

# Run tests matching a specific contract name
forge test --mc <TestContractName>

# Run a specific test function
forge test --mt <test_function_name>

# Format code
forge fmt
```

## Architecture

### Core Contracts

- **Portal.sol**: Abstract base contract inherited by both HubPortal and SpokePortal. Handles token transfers, message routing, and bridging path configuration.

- **HubPortal.sol**: Deployed on Ethereum mainnet. Uses lock-release mechanism for token transfers. Additionally responsible for:
  - Propagating M token earning index to spoke chains
  - Sending TTG Registrar keys and list status updates
  - Tracking bridged principal amounts per spoke chain
  - Managing earning state (enable/disable)

- **SpokePortal.sol**: Deployed on spoke chains. Uses mint-burn mechanism for token transfers. Receives and applies:
  - M token index updates
  - Registrar key updates
  - Registrar list updates (add/remove accounts)

- **HyperlaneBridge.sol**: Bridge implementation using Hyperlane protocol for cross-chain messaging. Owned contract that manages peer addresses for each destination chain.

- **SpokeVault.sol**: Vault on spoke chains for receiving and transferring excess wrapped $M back to the hub.

### Key Libraries

- **PayloadEncoder.sol**: Encodes/decodes cross-chain message payloads. Four payload types:
  - `Token`: Token transfer messages (amount, destination token, sender, recipient, index)
  - `Index`: M token index propagation
  - `Key`: Registrar key-value pairs
  - `List`: Registrar list updates (add/remove accounts)

### Token Flow

- **Hub → Spoke**: Tokens are locked in HubPortal, message sent via Hyperlane, tokens minted on SpokePortal
- **Spoke → Hub**: Tokens are burned on SpokePortal, message sent via Hyperlane, tokens released from HubPortal
- **Spoke ↔ Spoke**: Not supported in this lite version

### Access Control

- **PausableOwnableUpgradeable**: Custom pausable pattern with separate owner and pauser roles
- Portals are upgradeable (ERC1967 proxy pattern)
- Bridge is non-upgradeable but owner can set peer addresses

## Testing

- Unit tests in `test/unit/`
- Fork tests in `test/fork/`
- Mock contracts in `test/mocks/` for isolated testing
- Tests use Foundry's Test framework with vm cheatcodes

## Deployment

- Deployment scripts in `script/deploy/`
- Configuration scripts in `script/configure/`
- Upgrade scripts in `script/upgrade/`
- Uses CreateX for deterministic deployments
- Supports Safe multisig operations via `MultiSigBatchBase.sol` and `TimelockBatchBase.sol`

## Dependencies

Key external dependencies (in `lib/`):
- `common`: M0 shared libraries (IndexingMath, Migratable, IERC20)
- `protocol`: M0 protocol contracts
- `ttg`: Two Token Governance contracts
- `wrapped-m-token`: Wrapped M token implementation
- `openzeppelin` / `openzeppelin-contracts-upgradeable`: Access control, proxy patterns
- `forge-std`: Foundry testing utilities
