// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.26;

import { console } from "../../lib/forge-std/src/console.sol";

import { UpgradeSpokeMTokenBase } from "./UpgradeSpokeMTokenBase.sol";

contract UpgradeSpokeMToken is UpgradeSpokeMTokenBase {
    function run() external {
        address deployer_ = vm.rememberKey(vm.envUint("PRIVATE_KEY"));
        address migrationAdmin_ = vm.envAddress("MIGRATION_ADMIN");

        (, address mToken_, address portal_, address registrar_,,) = _readDeployment(block.chainid);

        console.log("Deployer:", deployer_);
        vm.startBroadcast(deployer_);

        _upgradeSpokeMToken(mToken_,  portal_, registrar_, migrationAdmin_);

        vm.stopBroadcast();
    }
}
