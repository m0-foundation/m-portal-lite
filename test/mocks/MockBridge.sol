// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.26;

import { IBridge } from "../../src/interfaces/IBridge.sol";

contract MockBridge is IBridge {
    bytes32 public messageId;

    function setMessageId(bytes32 messageId_) external {
        messageId = messageId_;
    }

    function sendMessage(
        uint256 destinationChainId,
        uint256 gasLimit,
        address refundAddress,
        bytes memory payload
    ) external payable returns (bytes32) {
        return messageId;
    }

    function portal() external view returns (address) { }
    function quote(uint256, uint256, bytes memory) external view returns (uint256) { }
}
