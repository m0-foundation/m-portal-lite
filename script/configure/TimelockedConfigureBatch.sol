// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.26;

import { Chains } from "../config/Chains.sol";
import { TimelockConfigureBase } from "./TimelockConfigureBase.sol";

import { IPortal } from "../../src/interfaces/IPortal.sol";
import { PayloadType } from "../../src/libs/PayloadEncoder.sol";

/// @title  TimelockedConfigureBatch
/// @notice Builds the timelocked configuration batch for a set of peer chains.
abstract contract TimelockedConfigureBatch is TimelockConfigureBase {
    using Chains for uint256;

    /// @notice Populates the timelock batch arrays and returns the salt.
    /// @param  peerChainIds_ Array of peer chain IDs to configure.
    /// @return salt_         The salt derived from the CHAIN_NAME env var.
    function _buildConfigureBatch(uint256[] memory peerChainIds_) internal returns (bytes32 salt_) {
        // CHAIN_NAME env var is used to generate a unique salt for the timelock operation
        string memory chainName_ = vm.envString("CHAIN_NAME");
        (, address mToken_, address portal_,,, address wrappedM_) = _readDeployment(block.chainid);

        uint256 peersCount_ = peerChainIds_.length;

        for (uint256 i; i < peersCount_; i++) {
            uint256 peerChainId = peerChainIds_[i];
            (, address peerMToken_,,,, address peerWrappedM_) = _readDeployment(peerChainId);

            // Set address of $M token on the remote chain
            _addToTimelockBatch(portal_, abi.encodeCall(IPortal.setDestinationMToken, (peerChainId, peerMToken_)));

            // Set gas limit required to process transfer message
            _addToTimelockBatch(
                portal_, abi.encodeCall(IPortal.setPayloadGasLimit, (peerChainId, PayloadType.Token, _TOKEN_TRANSFER_GAS_LIMIT))
            );

            if (block.chainid.isHub()) {
                _addToTimelockBatch(
                    portal_, abi.encodeCall(IPortal.setPayloadGasLimit, (peerChainId, PayloadType.Index, _INDEX_UPDATE_GAS_LIMIT))
                );
                _addToTimelockBatch(
                    portal_, abi.encodeCall(IPortal.setPayloadGasLimit, (peerChainId, PayloadType.Key, _KEY_UPDATE_GAS_LIMIT))
                );
                _addToTimelockBatch(
                    portal_, abi.encodeCall(IPortal.setPayloadGasLimit, (peerChainId, PayloadType.List, _LIST_UPDATE_GAS_LIMIT))
                );
            }

            // Set supported bridging paths
            _addToTimelockBatch(portal_, abi.encodeCall(IPortal.setSupportedBridgingPath, (mToken_, peerChainId, peerMToken_, true)));
            _addToTimelockBatch(portal_, abi.encodeCall(IPortal.setSupportedBridgingPath, (mToken_, peerChainId, peerWrappedM_, true)));
            _addToTimelockBatch(portal_, abi.encodeCall(IPortal.setSupportedBridgingPath, (wrappedM_, peerChainId, peerMToken_, true)));
            _addToTimelockBatch(portal_, abi.encodeCall(IPortal.setSupportedBridgingPath, (wrappedM_, peerChainId, peerWrappedM_, true)));
        }

        salt_ = bytes32(bytes(string.concat("Configure ", chainName_)));
    }
}
