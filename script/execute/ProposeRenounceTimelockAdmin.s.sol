// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.26;

import { console } from "../../lib/forge-std/src/console.sol";
import { TimelockController } from "../../lib/openzeppelin/contracts/governance/TimelockController.sol";
import { ExecuteBase } from "./ExecuteBase.sol";
import { MultiSigBatchBase } from "../MultiSigBatchBase.sol";

contract ProposeRenounceTimelockAdmin is ExecuteBase, MultiSigBatchBase {
    address constant _SAFE_MULTISIG = 0xdcf79C332cB3Fe9d39A830a5f8de7cE6b1BD6fD1;
    address constant _MAINNET_TIMELOCK = 0x23CA665c8a73292Fc7AC2cC4493d2cE883BBA468;

    function run() external {
        address proposer_ = vm.rememberKey(vm.envUint("PRIVATE_KEY"));
        TimelockController timelock = TimelockController(payable(_MAINNET_TIMELOCK));
        bytes32 ADMIN_ROLE = timelock.DEFAULT_ADMIN_ROLE();

        console.log("Current chain ID:", block.chainid);
        console.log("Timelock address:", _MAINNET_TIMELOCK);
        console.log("Multisig (current admin):", _SAFE_MULTISIG);
        console.log("Admin role:");
        console.logBytes32(ADMIN_ROLE);
        console.log("Multisig has admin role:", timelock.hasRole(ADMIN_ROLE, _SAFE_MULTISIG));
        console.log("Timelock has admin role:", timelock.hasRole(ADMIN_ROLE, _MAINNET_TIMELOCK));

        // Add renounceRole to batch - multisig renounces its admin role
        // callerConfirmation must match msg.sender (the multisig) to prevent accidental renunciation
        _addToBatch(_MAINNET_TIMELOCK, abi.encodeCall(timelock.renounceRole, (ADMIN_ROLE, _SAFE_MULTISIG)));

        // Simulate and propose the batch
        _simulateBatch(_SAFE_MULTISIG);
        _proposeBatch(_SAFE_MULTISIG, proposer_);

        console.log("Multisig proposal created to renounce timelock admin role!");
        console.log("After execution, timelock will be fully self-administered.");
    }
}