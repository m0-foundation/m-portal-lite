// SPDX-License-Identifier: MIT

pragma solidity 0.8.26;

import { TimelockConfigureBase } from "./TimelockConfigureBase.sol";

import { IPortal } from "../../src/interfaces/IPortal.sol";

contract ProposeRemoveBridgingPath is TimelockConfigureBase {
    function run(uint256[] memory peerChainIds_) external {
        address sender_ = vm.rememberKey(vm.envUint("PRIVATE_KEY"));
        bytes32 salt_ = _buildRemoveBridgingPathBatch(peerChainIds_);
        _proposeTimelockBatch(sender_, salt_);
    }

    function _buildRemoveBridgingPathBatch(uint256[] memory peerChainIds_) internal returns (bytes32 salt_) {
        (, address mToken_, address portal_,,, address wrappedM_) = _readDeployment(block.chainid);

        uint256 peersCount_ = peerChainIds_.length;

        for (uint256 i; i < peersCount_; i++) {
            uint256 peerChainId = peerChainIds_[i];
            (, address peerMToken_,,,, address peerWrappedM_) = _readDeployment(peerChainId);

            // Remove supported bridging paths
            _addToTimelockBatch(portal_, abi.encodeCall(IPortal.setSupportedBridgingPath, (mToken_, peerChainId, peerMToken_, false)));
            _addToTimelockBatch(portal_, abi.encodeCall(IPortal.setSupportedBridgingPath, (mToken_, peerChainId, peerWrappedM_, false)));
            _addToTimelockBatch(portal_, abi.encodeCall(IPortal.setSupportedBridgingPath, (wrappedM_, peerChainId, peerMToken_, false)));
            _addToTimelockBatch(portal_, abi.encodeCall(IPortal.setSupportedBridgingPath, (wrappedM_, peerChainId, peerWrappedM_, false)));
        }

        salt_ = bytes32(bytes("Remove Bridging Path"));
    }
}