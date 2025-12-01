// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.26;

import { Safe } from "../../lib/safe-utils/src/Safe.sol";
import { TimelockController } from "../../lib/openzeppelin/contracts/governance/TimelockController.sol";

import { Chains } from "../config/Chains.sol";
import { PeerConfig, ConfigureBase } from "./ConfigureBase.sol";
import { TimelockBatchBase } from "../TimelockBatchBase.sol";

import { IHyperlaneBridge } from "../../src/bridges/hyperlane/interfaces/IHyperlaneBridge.sol";
import { IPortal } from "../../src/interfaces/IPortal.sol";
import { TypeConverter } from "../../src/libs/TypeConverter.sol";
import { PayloadType } from "../../src/libs/PayloadEncoder.sol";

contract ProposeTimelockedConfigure is ConfigureBase, TimelockBatchBase {
    using TypeConverter for address;
    using Chains for uint256;
    using Safe for *;

    Safe.Client internal _safeMultiSig;
    address constant _PROPOSER_SAFE_MULTISIG = 0xb7A9B5f301eF3bAD36C2b4964E82931Dd7fb989C;
    address constant _TIMELOCK = 0x23CA665c8a73292Fc7AC2cC4493d2cE883BBA468;

    function run(uint256[] memory peerChainIds_) external {
        address sender_ = vm.rememberKey(vm.envUint("PRIVATE_KEY"));
        (address bridge_, address mToken_, address portal_,,, address wrappedM_) = _readDeployment(block.chainid);

        uint256 peersCount_ = peerChainIds_.length;
        PeerConfig[] memory peers_ = new PeerConfig[](peersCount_);

        // Prepare Timelocked batch
        for (uint256 i; i < peersCount_; i++) {
            uint256 peerChainId = peerChainIds_[i];
            (address peerBridge_, address peerMToken_,,,, address peerWrappedM_) = _readDeployment(peerChainId);

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

        _simulateBatch(_TIMELOCK);
        
        // Propose Timelock.scheduleBatch transaction to multisig
        _safeMultiSig.initialize(_PROPOSER_SAFE_MULTISIG);
        uint256 delay = TimelockController(payable(_TIMELOCK)).getMinDelay();
        bytes32 salt = "Configure Plasma";
        _safeMultiSig.proposeTransaction(_TIMELOCK, _getScheduleBatchCallData(bytes32(0), salt, delay), sender_);
    }
}
