// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.26;

import { console } from "../../lib/forge-std/src/console.sol";

import { Portal } from "../../src/Portal.sol";
import { SpokePortal } from "../../src/SpokePortal.sol";
import { Migrator } from "./Migrator.sol";
import { IHyperlaneBridge } from "../../src/bridges/hyperlane/interfaces/IHyperlaneBridge.sol";
import { IPortal } from "../../src/interfaces/IPortal.sol";
import { TypeConverter } from "../../src/libs/TypeConverter.sol";
import { PayloadType } from "../../src/libs/PayloadEncoder.sol";

import { Chains } from "../config/Chains.sol";
import { ConfigureBase } from "../configure/ConfigureBase.sol";
import { MultiSigBatchBase } from "../MultiSigBatchBase.sol";

contract ProposeUpgradeSpokePortal is ConfigureBase, MultiSigBatchBase {
    using TypeConverter for address;
    using Chains for uint256;

    address constant _SAFE_MULTISIG = 0xdcf79C332cB3Fe9d39A830a5f8de7cE6b1BD6fD1;
    address constant _MUSD = 0xacA92E438df0B2401fF60dA7E4337B687a2435DA;

    function run(uint256 peerChainId) external {
        address deployer_ = vm.rememberKey(vm.envUint("PRIVATE_KEY"));
        (address bridge_, address mToken_, address portal_, address registrar_,, address wrappedM_) = _readDeployment(block.chainid);
        (address peerBridge_, address peerMToken_,,,, address peerWrappedM_) = _readDeployment(peerChainId);

        console.log("Deployer:", deployer_);
        vm.startBroadcast(deployer_);
        IHyperlaneBridge(bridge_).setPeer(peerChainId, peerBridge_.toBytes32());
        SpokePortal implementation_ = new SpokePortal(mToken_, registrar_, _SWAP_FACILITY);
        Migrator migrator_ = new Migrator(address(implementation_));

        vm.stopBroadcast();

        console.log("Implementation:", address(implementation_));

        // Upgrade Spoke Portal
        _addToBatch(portal_, abi.encodeCall(Portal.migrate, (address(migrator_))));

        // Set address of $M token on the remote chain
        _addToBatch(portal_, abi.encodeCall(IPortal.setDestinationMToken, (peerChainId, peerMToken_)));

        // Set gas limit required to process transfer message
        _addToBatch(
            portal_, abi.encodeCall(IPortal.setPayloadGasLimit, (peerChainId, PayloadType.Token, _TOKEN_TRANSFER_GAS_LIMIT))
        );

         // Set supported bridging paths
        _addToBatch(portal_, abi.encodeCall(IPortal.setSupportedBridgingPath, (mToken_, peerChainId, peerMToken_, true)));
        _addToBatch(portal_, abi.encodeCall(IPortal.setSupportedBridgingPath, (mToken_, peerChainId, peerWrappedM_, true)));
        _addToBatch(portal_, abi.encodeCall(IPortal.setSupportedBridgingPath, (wrappedM_, peerChainId, peerMToken_, true)));
        _addToBatch(portal_, abi.encodeCall(IPortal.setSupportedBridgingPath, (wrappedM_, peerChainId, peerWrappedM_, true)));
        _addToBatch(portal_, abi.encodeCall(IPortal.setSupportedBridgingPath, (_MUSD, peerChainId, _MUSD, true)));

        _simulateBatch(_SAFE_MULTISIG);
        _proposeBatch(_SAFE_MULTISIG, deployer_);
    }
}
