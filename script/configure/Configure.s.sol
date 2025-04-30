// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.26;

import { PeerConfig, ConfigureBase } from "./ConfigureBase.sol";

contract Configure is ConfigureBase {
    function run(uint256[] memory peerChainIds_) external {
        address deployer_ = vm.rememberKey(vm.envUint("PRIVATE_KEY"));
        (address bridge_, address mToken_, address portal_,) = _readDeployment(block.chainid);

        uint256 peersCount_ = peerChainIds_.length;
        PeerConfig[] memory peers_ = new PeerConfig[](peersCount_);

        for (uint256 i; i < peersCount_; i++) {
            uint256 peerChainId = peerChainIds_[i];
            (address peerBridge_, address peerMToken_,,) = _readDeployment(peerChainId);
            peers_[i] = PeerConfig({ chainId: peerChainId, bridge: peerBridge_, mToken: peerMToken_ });
        }

        vm.startBroadcast(deployer_);

        _configurePeers(portal_, mToken_, bridge_, peers_);

        vm.stopBroadcast();
    }
}
