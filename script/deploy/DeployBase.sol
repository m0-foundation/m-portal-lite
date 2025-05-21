// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.26;

import { ERC1967Proxy } from "../../lib/openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

import { HyperlaneBridge } from "../../src/bridges/hyperlane/HyperlaneBridge.sol";

import { HyperlaneConfig } from "../config/HyperlaneConfig.sol";
import { ScriptBase } from "../ScriptBase.sol";
import { ICreateXLike } from "./interfaces/ICreateXLike.sol";

contract DeployBase is ScriptBase {
    /// @dev Contract names used for deterministic deployment
    string internal constant _PORTAL_CONTRACT_NAME = "Portal Lite";
    string internal constant _HYPERLANE_BRIDGE_CONTRACT_NAME = "Hyperlane Bridge";

    // Same address across all supported mainnet and testnets networks.
    address internal constant _CREATE_X_FACTORY = 0xba5Ed099633D3B313e4D5F7bdc1305d3c28ba5Ed;

    function _computeSalt(address deployer_, string memory contractName_) internal pure returns (bytes32) {
        return bytes32(
            abi.encodePacked(
                bytes20(deployer_), // used to implement permissioned deploy protection
                bytes1(0), // disable cross-chain redeploy protection
                bytes11(keccak256(bytes(contractName_)))
            )
        );
    }

    function _computeGuardedSalt(address deployer_, bytes32 salt_) internal pure returns (bytes32) {
        return _efficientHash({ a: bytes32(uint256(uint160(deployer_))), b: salt_ });
    }

    /**
     * @dev Returns the `keccak256` hash of `a` and `b` after concatenation.
     * @param a The first 32-byte value to be concatenated and hashed.
     * @param b The second 32-byte value to be concatenated and hashed.
     * @return hash The 32-byte `keccak256` hash of `a` and `b`.
     */
    function _efficientHash(bytes32 a, bytes32 b) internal pure returns (bytes32 hash) {
        assembly ("memory-safe") {
            mstore(0x00, a)
            mstore(0x20, b)
            hash := keccak256(0x00, 0x40)
        }
    }

    function _deployCreate3Proxy(address implementation_, bytes32 salt_, bytes memory data_) internal returns (address) {
        return ICreateXLike(_CREATE_X_FACTORY).deployCreate3(
            salt_, abi.encodePacked(type(ERC1967Proxy).creationCode, abi.encode(address(implementation_), data_))
        );
    }

    function _deployCreate3(bytes memory initCode_, bytes32 salt_) internal returns (address) {
        return ICreateXLike(_CREATE_X_FACTORY).deployCreate3(salt_, initCode_);
    }

    function _getCreate3Address(address deployer_, bytes32 salt_) internal view virtual returns (address) {
        return ICreateXLike(_CREATE_X_FACTORY).computeCreate3Address(_computeGuardedSalt(deployer_, salt_));
    }

    function _computeHyperlaneBridgeAddress(address deployer_) internal view returns (address hyperlaneBridge_) {
        return _getCreate3Address(deployer_, _computeSalt(deployer_, _HYPERLANE_BRIDGE_CONTRACT_NAME));
    }

    function _deployHyperlaneBridge(uint256 chainId_, address deployer_) internal returns (address hyperlaneBridge_) {
        address portal_ = _computePortalAddress(deployer_);
        address mailbox_ = HyperlaneConfig.getMailbox(chainId_);
        bytes memory bridgeInitCode_ =
            abi.encodePacked(type(HyperlaneBridge).creationCode, abi.encode(mailbox_, portal_, deployer_));
        bytes32 bridgeSalt_ = _computeSalt(deployer_, _HYPERLANE_BRIDGE_CONTRACT_NAME);
        return _deployCreate3(bridgeInitCode_, bridgeSalt_);
    }

    function _computePortalAddress(address deployer_) internal view returns (address portal_) {
        return _getCreate3Address(deployer_, _computeSalt(deployer_, _PORTAL_CONTRACT_NAME));
    }
}
