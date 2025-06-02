// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.26;

import { console } from "../../lib/forge-std/src/console.sol";
import { DeploySpokeBase } from "./DeploySpokeBase.sol";

contract DeploySpokeWrappedM is DeploySpokeBase {
    function run() external {
        address deployer_ = vm.rememberKey(vm.envUint("PRIVATE_KEY"));
        address migrationAdmin_ = vm.envAddress("MIGRATION_ADMIN");
        address hubVault_ = vm.envAddress("HUB_VAULT");
        uint256 hubChainId_ = vm.envUint("HUB_CHAIN_ID");

        (address bridge_, address mToken_, address portal_, address registrar_,,) = _readDeployment(block.chainid);

        console.log("Deployer:          ", deployer_);
        console.log("Migration admin:   ", migrationAdmin_);

        vm.startBroadcast(deployer_);

        uint256 chainId_ = block.chainid;

        (, address vault_ )= _deployVault(deployer_, portal_, hubVault_, hubChainId_, migrationAdmin_);
        (, address wrappedMToken_) = _deployWrappedMToken(deployer_, mToken_, registrar_, vault_, migrationAdmin_);

        vm.stopBroadcast();

        console.log("Vault:             ", vault_);
        console.log("Wrapped M Token:   ", wrappedMToken_);

        _writeDeployments(chainId_, bridge_, mToken_, portal_, registrar_, vault_, wrappedMToken_);
    }
}
