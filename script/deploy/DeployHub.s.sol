// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.26;

import { console } from "../../lib/forge-std/src/console.sol";
import { DeployHubBase } from "./DeployHubBase.sol";

contract DeployHub is DeployHubBase {
    function run() external {
        address deployer_ = vm.rememberKey(vm.envUint("PRIVATE_KEY"));

        vm.startBroadcast(deployer_);

        address bridge_ = _deployHyperlaneBridge(block.chainid, deployer_);
        address portal_ = _deployHubPortal(bridge_, deployer_);

        vm.stopBroadcast();

        console.log("Hyperlane Bridge: ", bridge_);
        console.log("Hub Portal:       ", portal_);
    }
}
