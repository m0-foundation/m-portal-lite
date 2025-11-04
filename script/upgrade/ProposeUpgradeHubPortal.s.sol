// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.26;

import { console } from "../../lib/forge-std/src/console.sol";

import { Portal } from "../../src/Portal.sol";
import { HubPortal } from "../../src/HubPortal.sol";
import { Migrator } from "./Migrator.sol";
import { IHyperlaneBridge } from "../../src/bridges/hyperlane/interfaces/IHyperlaneBridge.sol";
import { IHubPortal } from "../../src/interfaces/IHubPortal.sol";
import { TypeConverter } from "../../src/libs/TypeConverter.sol";
import { PayloadType } from "../../src/libs/PayloadEncoder.sol";

import { Chains } from "../config/Chains.sol";
import { ScriptBase } from "../ScriptBase.sol";
import { MultiSigBatchBase } from "../MultiSigBatchBase.sol";

contract ProposeUpgradeHubPortal is ScriptBase, MultiSigBatchBase {
    using TypeConverter for address;
    using Chains for uint256;

    address constant _SAFE_MULTISIG = 0xdcf79C332cB3Fe9d39A830a5f8de7cE6b1BD6fD1;
    uint256 constant _LINEA_CHAIN_ID = 59144;
    uint256 constant _BNB_CHAIN_ID = 56;

    function run() external {
        address deployer_ = vm.rememberKey(vm.envUint("PRIVATE_KEY"));
        (, address mToken_, address portal_, address registrar_,, address wrappedM_) = _readDeployment(block.chainid);

        console.log("Deployer:", deployer_);
        
        vm.startBroadcast(deployer_);
        
        HubPortal implementation_ = new HubPortal(mToken_, registrar_, _SWAP_FACILITY);
        Migrator migrator_ = new Migrator(address(implementation_));

        vm.stopBroadcast();

        console.log("Implementation:", address(implementation_));

        // Upgrade Spoke Portal
        _addToBatch(portal_, abi.encodeCall(Portal.migrate, (address(migrator_))));

        // enableCrossSpokeConnection
        _addToBatch(portal_, abi.encodeCall(IHubPortal.enableCrossSpokeConnection, (_LINEA_CHAIN_ID)));
        _addToBatch(portal_, abi.encodeCall(IHubPortal.enableCrossSpokeConnection, (_BNB_CHAIN_ID)));

        _simulateBatch(_SAFE_MULTISIG);
        _proposeBatch(_SAFE_MULTISIG, deployer_);
    }
}