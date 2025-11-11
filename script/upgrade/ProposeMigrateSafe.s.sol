// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.26;

import { console } from "../../lib/forge-std/src/console.sol";
import { Safe, Enum } from "../../lib/safe-utils/src/Safe.sol";

import { Portal } from "../../src/Portal.sol";
import { HubPortal } from "../../src/HubPortal.sol";
import { Migrator } from "./Migrator.sol";
import { IHyperlaneBridge } from "../../src/bridges/hyperlane/interfaces/IHyperlaneBridge.sol";
import { IHubPortal } from "../../src/interfaces/IHubPortal.sol";
import { TypeConverter } from "../../src/libs/TypeConverter.sol";
import { PayloadType } from "../../src/libs/PayloadEncoder.sol";

import { Chains } from "../config/Chains.sol";
import { ScriptBase } from "../ScriptBase.sol";
import { DelegatePrank } from "../lib/DelegatePrank.sol";

contract ProposeMigrateSafe is ScriptBase, DelegatePrank {
    using TypeConverter for *;
    using Chains for uint256;
    using Safe for Safe.Client;

    address constant _SAFE_MULTISIG = 0xdcf79C332cB3Fe9d39A830a5f8de7cE6b1BD6fD1;
    Safe.Client internal _safeMultiSig;

    address constant _SAFE_MIGRATION_CONTRACT = 0x526643F69b81B008F46d95CD5ced5eC0edFFDaC6;

    function run() external {
        address sender_ = vm.rememberKey(vm.envUint("PRIVATE_KEY"));

        _safeMultiSig.initialize(_SAFE_MULTISIG);

        address currentSingleton = vm.load(_SAFE_MULTISIG, bytes32(uint256(0))).toAddress();
        console.log("Current Safe singleton:", currentSingleton);

        // Build and simulate the migration transaction
        address to = _SAFE_MIGRATION_CONTRACT;
        bytes memory data = abi.encodeWithSignature("migrateL2Singleton()");
        uint256 nonce = _safeMultiSig.getNonce();

        vm.allowCheatcodes(_SAFE_MULTISIG);
        (bool success, bytes memory result) = delegatePrank(
            _SAFE_MULTISIG,
            to,
            data
        );

        if (success) {
            console.log("Migration simulation success.");
            address newSingleton = vm.load(_SAFE_MULTISIG, bytes32(uint256(0))).toAddress();
            console.log("Safe singleton after migration:", newSingleton);
        } else {
            console.log("Migration simulation failed with error:", string(result));
            revert(result);
        }

        // Propose the transaction to the Safe Transaction Service
        Safe.ExecTransactionParams memory params = Safe.ExecTransactionParams({
            to: to,
            value: 0,
            data: data,
            operation: Enum.Operation.DelegateCall,
            sender: sender_,
            signature: _safeMultiSig.sign(
                to,
                data,
                Enum.Operation.DelegateCall,
                sender_,
                ""
            ),
            nonce: nonce
        });

        bytes32 safeTxHash = _safeMultiSig.getSafeTxHash(
            to,
            0,
            data,
            Enum.Operation.DelegateCall,
            nonce
        );

        // _safeMultiSig.deleteTransaction(safeTxHash, sender_);

        _safeMultiSig.proposeTransaction(params);
    }
}