// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.26;

library MetalayerConfig {
    /// @dev Returns Metalayer Router address for the given chain ID
    function getRouter(uint256 chainId_) internal pure returns (address router_) {
        return 0x09cE71C24EE2098e351C0cF2dC6431B414d247f3;
    }
}