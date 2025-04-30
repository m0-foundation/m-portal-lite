// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.26;

import { ScriptBase } from "../ScriptBase.sol";

import { IHyperlaneBridge } from "../../src/bridges/hyperlane/interfaces/IHyperlaneBridge.sol";
import { IPortal } from "../../src/interfaces/IPortal.sol";
import { TypeConverter } from "../../src/libs/TypeConverter.sol";

struct PeerConfig {
    uint256 chainId;
    address mToken;
    address bridge;
}

contract ConfigureBase is ScriptBase {
    using TypeConverter for address;

    function _configurePeers(address portal_, address mToken_, address bridge_, PeerConfig[] memory peers_) internal {
        uint256 peersCount_ = peers_.length;

        for (uint256 i; i < peersCount_; i++) {
            PeerConfig memory peer_ = peers_[i];
            uint256 destinationChainId_ = peer_.chainId;

            IHyperlaneBridge(bridge_).setPeer(destinationChainId_, peer_.bridge.toBytes32());
            IPortal(portal_).setDestinationMToken(destinationChainId_, peer_.mToken);

            // Supported Bridging Paths
            // M => M
            IPortal(portal_).setSupportedBridgingPath(mToken_, destinationChainId_, peer_.mToken, true);
        }
    }
}
