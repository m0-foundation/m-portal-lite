// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.26;

import { console } from "../../lib/forge-std/src/console.sol";
import { IPausableOwnable } from "../../src/interfaces/IPausableOwnable.sol";
import { ExecuteBase } from "./ExecuteBase.sol";
import { MultiSigBatchBase } from "../MultiSigBatchBase.sol";

contract ProposeTransferPauserRole is ExecuteBase, MultiSigBatchBase {
    address constant _SAFE_MULTISIG = 0xdcf79C332cB3Fe9d39A830a5f8de7cE6b1BD6fD1;

    function run(address newPauser_) external {
        address proposer_ = vm.rememberKey(vm.envUint("PRIVATE_KEY"));
        (, , address portal_, , , ) = _readDeployment(block.chainid);

        console.log("Current chain ID:", block.chainid);
        console.log("Portal address:", portal_);
        console.log("Current pauser:", IPausableOwnable(portal_).pauser());
        console.log("New pauser:", newPauser_);
        console.log("Multisig (owner):", _SAFE_MULTISIG);

        // Add transferPauserRole to batch
        _addToBatch(portal_, abi.encodeCall(IPausableOwnable.transferPauserRole, (newPauser_)));

        // Simulate and propose the batch
        _simulateBatch(_SAFE_MULTISIG);
        _proposeBatch(_SAFE_MULTISIG, proposer_);

        console.log("Multisig proposal created to transfer pauser role!");
    }
}