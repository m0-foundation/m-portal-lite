// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.26;

library MetalayerConfig {
    /// @dev Returns Metalayer Router address for the given chain ID
    function getRouter(uint256 chainId_) internal pure returns (address router_) {
        return 0x09ce71c24ee2098e351c0cf2dc6431b414d247f3;
    }
} 