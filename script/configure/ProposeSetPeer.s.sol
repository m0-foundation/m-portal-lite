// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.26;

import { Chains } from "../config/Chains.sol";
import { PeerConfig, ConfigureBase } from "./ConfigureBase.sol";
import { MultiSigBatchBase } from "../MultiSigBatchBase.sol";

import { IHyperlaneBridge } from "../../src/bridges/hyperlane/interfaces/IHyperlaneBridge.sol";
import { IPortal } from "../../src/interfaces/IPortal.sol";
import { TypeConverter } from "../../src/libs/TypeConverter.sol";
import { PayloadType } from "../../src/libs/PayloadEncoder.sol";

contract ProposeSetPeer is ConfigureBase, MultiSigBatchBase {
    using TypeConverter for address;
    using Chains for uint256;

    address constant _SAFE_MULTISIG = 0xdcf79C332cB3Fe9d39A830a5f8de7cE6b1BD6fD1;

    function run(uint256[] memory peerChainIds_) external {
        address deployer_ = vm.rememberKey(vm.envUint("PRIVATE_KEY"));
        (address bridge_,,,,,) = _readDeployment(block.chainid);

        uint256 peersCount_ = peerChainIds_.length;
        PeerConfig[] memory peers_ = new PeerConfig[](peersCount_);

        for (uint256 i; i < peersCount_; i++) {
            uint256 peerChainId = peerChainIds_[i];
            (address peerBridge_,,,,,) = _readDeployment(peerChainId);
            
            // Configure Peer
            _addToBatch(bridge_, abi.encodeCall(IHyperlaneBridge.setPeer, (peerChainId, peerBridge_.toBytes32())));
        }

        _simulateBatch(_SAFE_MULTISIG);
        _proposeBatch(_SAFE_MULTISIG, deployer_);
    }
}
