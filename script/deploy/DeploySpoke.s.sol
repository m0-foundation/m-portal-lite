// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.26;

import { console } from "../../lib/forge-std/src/console.sol";
import { DeploySpokeBase } from "./DeploySpokeBase.sol";

contract DeploySpoke is DeploySpokeBase {
    function run() external {
        address deployer_ = vm.rememberKey(vm.envUint("PRIVATE_KEY"));

        vm.startBroadcast(deployer_);

        uint256 chainId_ = block.chainid;
        uint64 currentNonce_ = vm.getNonce(deployer_);
        address registrar_ = _deployRegistrar(deployer_, currentNonce_);
        currentNonce_ = vm.getNonce(deployer_);
        address mToken_ = _deployMToken(currentNonce_, registrar_);
        address bridge_ = _deployHyperlaneBridge(chainId_, deployer_);
        address portal_ = _deploySpokePortal(chainId_, mToken_, registrar_, bridge_, deployer_);

        vm.stopBroadcast();

        console.log("M Token:          ", mToken_);
        console.log("Registrar:        ", registrar_);
        console.log("Spoke Portal:     ", portal_);
        console.log("Hyperlane Bridge: ", bridge_);

        _writeDeployments(chainId_, bridge_, mToken_, portal_, registrar_);
    }
}