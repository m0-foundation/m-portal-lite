// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.26;

import { Chains } from "./Chains.sol";

library MetalayerConfig {
    address internal constant _MAINNET_ROUTER = 0x09cE71C24EE2098e351C0cF2dC6431B414d247f3;
    address internal constant _TESTNET_ROUTER = 0x6F23B0211056035A22430a10fD27DED8547dc377;

    /**
     * @notice Returns Metalayer Router address for the given chain ID
     * @dev    https://docs.caldera.xyz/metalayer/developers/cross-chain-dapps/addresses
     * @param  chainId_ EVM chain id.
     * @return router_  The address of Metalayer Router contract.
     */
    function getRouter(uint256 chainId_) internal pure returns (address router_) {
        // Mainnet
        if (chainId_ == Chains.ETHEREUM) return _MAINNET_ROUTER;
        if (chainId_ == Chains.APECHAIN) return _MAINNET_ROUTER;

        // Testnet
        if (chainId_ == Chains.ETHEREUM_SEPOLIA) return _TESTNET_ROUTER;
        if (chainId_ == Chains.APECHAIN_TESTNET) return _TESTNET_ROUTER;
    }
}