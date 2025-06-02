// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.26;

import { Chains } from "../config/Chains.sol";
import { ScriptBase } from "../ScriptBase.sol";

import { IHyperlaneBridge } from "../../src/bridges/hyperlane/interfaces/IHyperlaneBridge.sol";
import { IPortal } from "../../src/interfaces/IPortal.sol";
import { TypeConverter } from "../../src/libs/TypeConverter.sol";
import { PayloadType } from "../../src/libs/PayloadEncoder.sol";

struct PeerConfig {
    uint256 chainId;
    address mToken;
    address wrappedM;
    address bridge;
}

contract ConfigureBase is ScriptBase {
    using TypeConverter for address;
    using Chains for uint256;

    uint256 internal constant _INDEX_UPDATE_GAS_LIMIT = 50_000;
    uint256 internal constant _KEY_UPDATE_GAS_LIMIT = 50_000;
    uint256 internal constant _LIST_UPDATE_GAS_LIMIT = 50_000;
    uint256 internal constant _TOKEN_TRANSFER_GAS_LIMIT = 100_000;

    function _configurePeers(
        address portal_,
        address mToken_,
        address wrappedMToken_,
        address bridge_,
        PeerConfig[] memory peers_
    ) internal {
        uint256 peersCount_ = peers_.length;

        for (uint256 i; i < peersCount_; i++) {
            PeerConfig memory peer_ = peers_[i];
            uint256 destinationChainId_ = peer_.chainId;

            IHyperlaneBridge(bridge_).setPeer(destinationChainId_, peer_.bridge.toBytes32());
            IPortal(portal_).setDestinationMToken(destinationChainId_, peer_.mToken);

            // Set Payload Gas limit
            IPortal(portal_).setPayloadGasLimit(destinationChainId_, PayloadType.Token, _TOKEN_TRANSFER_GAS_LIMIT);

            if (block.chainid.isHub()) {
                IPortal(portal_).setPayloadGasLimit(destinationChainId_, PayloadType.Index, _INDEX_UPDATE_GAS_LIMIT);
                IPortal(portal_).setPayloadGasLimit(destinationChainId_, PayloadType.Key, _KEY_UPDATE_GAS_LIMIT);
                IPortal(portal_).setPayloadGasLimit(destinationChainId_, PayloadType.List, _LIST_UPDATE_GAS_LIMIT);
            }

            // Supported Bridging Paths
            // M => M
            IPortal(portal_).setSupportedBridgingPath(mToken_, destinationChainId_, peer_.mToken, true);

            // M => WrappedM
            IPortal(portal_).setSupportedBridgingPath(mToken_, destinationChainId_, peer_.wrappedM, true);

            // WrappedM => M
            IPortal(portal_).setSupportedBridgingPath(wrappedMToken_, destinationChainId_, peer_.mToken, true);

            // WrappedM => WrappedM
            IPortal(portal_).setSupportedBridgingPath(wrappedMToken_, destinationChainId_, peer_.wrappedM, true);
        }
    }
}
