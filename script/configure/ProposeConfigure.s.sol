// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.26;

import { Chains } from "../config/Chains.sol";
import { PeerConfig, ConfigureBase } from "./ConfigureBase.sol";
import { MultiSigBatchBase } from "../MultiSigBatchBase.sol";

import { IHyperlaneBridge } from "../../src/bridges/hyperlane/interfaces/IHyperlaneBridge.sol";
import { IPortal } from "../../src/interfaces/IPortal.sol";
import { TypeConverter } from "../../src/libs/TypeConverter.sol";
import { PayloadType } from "../../src/libs/PayloadEncoder.sol";

contract ProposeConfigure is ConfigureBase, MultiSigBatchBase {
    using TypeConverter for address;
    using Chains for uint256;

    address constant _SAFE_MULTISIG = 0xdcf79C332cB3Fe9d39A830a5f8de7cE6b1BD6fD1;

    function run(uint256[] memory peerChainIds_) external {
        address deployer_ = vm.rememberKey(vm.envUint("PRIVATE_KEY"));
        (address bridge_, address mToken_, address portal_,,, address wrappedM_) = _readDeployment(block.chainid);

        uint256 peersCount_ = peerChainIds_.length;
        PeerConfig[] memory peers_ = new PeerConfig[](peersCount_);

        for (uint256 i; i < peersCount_; i++) {
            uint256 peerChainId = peerChainIds_[i];
            (address peerBridge_, address peerMToken_,,,, address peerWrappedM_) = _readDeployment(peerChainId);
            
            // Configure Peer
            _addToBatch(bridge_, abi.encodeCall(IHyperlaneBridge.setPeer, (peerChainId, peerBridge_.toBytes32())));
            
            // Set address of $M token on the remote chain
            _addToBatch(portal_, abi.encodeCall(IPortal.setDestinationMToken, (peerChainId, peerMToken_)));

            // Set gas limit required to process transfer message
            _addToBatch(portal_, abi.encodeCall(IPortal.setPayloadGasLimit, (peerChainId, PayloadType.Token, _TOKEN_TRANSFER_GAS_LIMIT)));

            if (block.chainid.isHub()) {
                _addToBatch(portal_, abi.encodeCall(IPortal.setPayloadGasLimit, (peerChainId, PayloadType.Index, _INDEX_UPDATE_GAS_LIMIT)));
                _addToBatch(portal_, abi.encodeCall(IPortal.setPayloadGasLimit, (peerChainId, PayloadType.Key, _KEY_UPDATE_GAS_LIMIT)));
                _addToBatch(portal_, abi.encodeCall(IPortal.setPayloadGasLimit, (peerChainId, PayloadType.List, _LIST_UPDATE_GAS_LIMIT)));
            }

            // Set supported bridging paths
            _addToBatch(portal_, abi.encodeCall(IPortal.setSupportedBridgingPath, (mToken_, peerChainId, peerMToken_, true)));
            _addToBatch(portal_, abi.encodeCall(IPortal.setSupportedBridgingPath, (mToken_, peerChainId, peerWrappedM_, true)));
            _addToBatch(portal_, abi.encodeCall(IPortal.setSupportedBridgingPath, (wrappedM_, peerChainId, peerMToken_, true)));
            _addToBatch(portal_, abi.encodeCall(IPortal.setSupportedBridgingPath, (wrappedM_, peerChainId, peerWrappedM_, true)));
        }

        _simulateBatch(_SAFE_MULTISIG);
        _proposeBatch(_SAFE_MULTISIG, deployer_);
    }
}
