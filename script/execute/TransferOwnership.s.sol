// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.26;

import { console } from "../../lib/forge-std/src/console.sol";
import { Ownable } from "../../lib/openzeppelin/contracts/access/Ownable.sol";
import { ScriptBase } from "../ScriptBase.sol";
import { MultiSigBatchBase } from "../MultiSigBatchBase.sol";

contract ProposeTransferOwnership is ScriptBase, MultiSigBatchBase {
    address constant _SAFE_MULTISIG = 0xdcf79C332cB3Fe9d39A830a5f8de7cE6b1BD6fD1;

    function run(address newOwner_) external {
        address proposer_ = vm.rememberKey(vm.envUint("PRIVATE_KEY"));
        (, , address portal_, , , ) = _readDeployment(block.chainid);

        console.log("Current chain ID:", block.chainid);
        console.log("Portal address:", portal_);
        console.log("Current owner:", Ownable(portal_).owner());
        console.log("New owner:", newOwner_);
        console.log("Multisig (current owner):", _SAFE_MULTISIG);

        // Add transferOwnership to batch
        _addToBatch(portal_, abi.encodeCall(Ownable.transferOwnership, (newOwner_)));

        // Simulate and propose the batch
        _simulateBatch(_SAFE_MULTISIG);
        _proposeBatch(_SAFE_MULTISIG, proposer_);

        console.log("Multisig proposal created to transfer ownership!");
    }
}