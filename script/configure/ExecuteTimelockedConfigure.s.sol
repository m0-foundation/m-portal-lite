// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.26;

import { TimelockedConfigureBatch } from "./TimelockedConfigureBatch.sol";

/// @title  ExecuteTimelockedConfigure
/// @notice Executes a previously scheduled timelocked configuration batch after the delay has elapsed.
contract ExecuteTimelockedConfigure is TimelockedConfigureBatch {
    function run(uint256[] memory peerChainIds_) external {
        address sender_ = vm.rememberKey(vm.envUint("PRIVATE_KEY"));
        bytes32 salt_ = _buildConfigureBatch(peerChainIds_);

        vm.startBroadcast(sender_);
        _executeTimelockBatch(salt_);
        vm.stopBroadcast();
    }
}
