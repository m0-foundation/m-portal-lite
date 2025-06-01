// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.26;

import { console } from "../../lib/forge-std/src/console.sol";

import { IHubPortal } from "../../src/interfaces/IHubPortal.sol";

import { DeployHubBase } from "./DeployHubBase.sol";

contract DeployHub is DeployHubBase {
    function run() external {
        address deployer_ = vm.rememberKey(vm.envUint("PRIVATE_KEY"));

        console.log("Deployer:         ", deployer_);

        vm.startBroadcast(deployer_);

        uint256 chainId_ = block.chainid;
        address bridge_ = _deployHyperlaneBridge(chainId_, deployer_);
        address portal_ = _deployHubPortal(bridge_, deployer_);

        // HubPortal is already an approve earner
        IHubPortal(portal_).enableEarning();

        vm.stopBroadcast();

        console.log("Hyperlane Bridge: ", bridge_);
        console.log("Hub Portal:       ", portal_);

        _writeDeployments(chainId_, bridge_, _M_TOKEN, portal_, _REGISTRAR, _VAULT, _WRAPPED_M_TOKEN);
    }
}
