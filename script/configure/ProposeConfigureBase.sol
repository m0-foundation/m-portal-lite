// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.26;

import { Safe } from "../../lib/safe-utils/src/Safe.sol";
import { TimelockController } from "../../lib/openzeppelin/contracts/governance/TimelockController.sol";

import { ConfigureBase } from "./ConfigureBase.sol";
import { TimelockBatchBase } from "../TimelockBatchBase.sol";

/// @title  ProposeConfigureBase
/// @notice Base contract for proposing timelocked configuration changes via Safe multisig.
abstract contract ProposeConfigureBase is ConfigureBase, TimelockBatchBase {
    using Safe for *;

    address internal constant _PROPOSER_SAFE_MULTISIG = 0xb7A9B5f301eF3bAD36C2b4964E82931Dd7fb989C;
    address internal constant _TIMELOCK = 0x23CA665c8a73292Fc7AC2cC4493d2cE883BBA468;

    Safe.Client internal _safeMultiSig;

    /// @notice Simulates the batch and proposes it to the Safe multisig.
    /// @param  sender_ The address proposing the transaction.
    /// @param  salt_   A unique salt for the timelock operation.
    function _proposeTimelockBatch(address sender_, bytes32 salt_) internal {
        _simulateBatch(_TIMELOCK);

        _safeMultiSig.initialize(_PROPOSER_SAFE_MULTISIG);
        uint256 delay_ = TimelockController(payable(_TIMELOCK)).getMinDelay();
        _safeMultiSig.proposeTransaction(_TIMELOCK, _getScheduleBatchCallData(bytes32(0), salt_, delay_), sender_);
    }
}
