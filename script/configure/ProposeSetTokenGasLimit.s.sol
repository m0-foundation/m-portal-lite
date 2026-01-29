// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.26;

import { ProposeConfigureBase } from "./ProposeConfigureBase.sol";

import { IPortal } from "../../src/interfaces/IPortal.sol";
import { PayloadType } from "../../src/libs/PayloadEncoder.sol";

/// @title  ProposeSetTokenGasLimit
/// @notice Proposes a timelocked transaction to set PayloadType.Token gas limit on portal contracts.
contract ProposeSetTokenGasLimit is ProposeConfigureBase {
    /// @notice Proposes setting Token gas limit for the given peer chains.
    /// @param  peerChainIds_ Array of peer chain IDs to configure.
    function run(uint256[] memory peerChainIds_) external {
        address sender_ = vm.rememberKey(vm.envUint("PRIVATE_KEY"));
        (,, address portal_,,,) = _readDeployment(block.chainid);

        for (uint256 i; i < peerChainIds_.length; i++) {
            _addToTimelockBatch(
                portal_,
                abi.encodeCall(IPortal.setPayloadGasLimit, (peerChainIds_[i], PayloadType.Token, _TOKEN_TRANSFER_GAS_LIMIT))
            );
        }

        bytes32 salt_ = bytes32(bytes(string.concat("SetTokenGasLimit ", vm.toString(block.timestamp))));
        _proposeTimelockBatch(sender_, salt_);
    }
}
