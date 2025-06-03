// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.26;

import { console } from "../../lib/forge-std/src/console.sol";

import { UpgradeSpokePortalBase } from "./UpgradeSpokePortalBase.sol";

contract UpgradeSpokePortal is UpgradeSpokePortalBase {
    function run() external {
        address deployer_ = vm.rememberKey(vm.envUint("PRIVATE_KEY"));
        (address bridge_, address mToken_, address portal_, address registrar_,,) = _readDeployment(block.chainid);

        console.log("Deployer:", deployer_);
        vm.startBroadcast(deployer_);

        _upgradeSpokePortal(block.chainid, portal_, mToken_, registrar_, bridge_, deployer_);

        vm.stopBroadcast();
    }
}
