// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.26;

/// @notice EVM chain Ids
library Chains {
    error UnsupportedChain(uint256 chainId);

    // Mainnet
    uint256 internal constant ETHEREUM = 1;
    uint256 internal constant HYPER_EVM = 999;
    uint256 internal constant PLUME = 98866;

    // Testnet
    uint256 internal constant ETHEREUM_SEPOLIA = 11155111;
    uint256 internal constant HYPER_EVM_TESTNET = 998;
    uint256 internal constant PLUME_TESTNET = 98867;

    function getHubChainId(uint256 spokeChainId_) internal returns (uint256 hubChainId_) {
        // Mainnet
        if (spokeChainId_ == HYPER_EVM) return ETHEREUM;
        if (spokeChainId_ == PLUME) return ETHEREUM;

        // Testnet
        if (spokeChainId_ == HYPER_EVM_TESTNET) return ETHEREUM_SEPOLIA;
        if (spokeChainId_ == PLUME_TESTNET) return ETHEREUM_SEPOLIA;
    }

    function isHub(uint256 chainId_) internal pure returns (bool) {
        return chainId_ == ETHEREUM || chainId_ == ETHEREUM_SEPOLIA;
    }
}
