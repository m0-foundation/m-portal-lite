// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.26;

import { console } from "../../lib/forge-std/src/console.sol";
import { DeploySpokeBase } from "./DeploySpokeBase.sol";

contract DeploySpoke is DeploySpokeBase {
    function run() external {
        address deployer_ = vm.rememberKey(vm.envUint("PRIVATE_KEY"));

        vm.startBroadcast(deployer_);

        uint64 currentNonce_ = vm.getNonce(deployer_);
        address registrar_ = _deployRegistrar(deployer_, currentNonce_);
        currentNonce_ = vm.getNonce(deployer_);
        address mToken_ = _deployMToken(deployer_, currentNonce_, registrar_);
        address bridge_ = _deployHyperlaneBridge(block.chainid, deployer_);
        address portal_ = _deploySpokePortal(bridge_, deployer_);

        vm.stopBroadcast();

        console.log("Registrar:        ", registrar_);
        console.log("M Token:          ", mToken_);
        console.log("Hyperlane Bridge: ", bridge_);
        console.log("Spoke Portal:     ", portal_);
    }
}