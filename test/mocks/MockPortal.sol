// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.26;

contract MockPortal {
    address public immutable mToken;

    function receiveMessage(uint256, bytes calldata) external { }

    function transfer(
        uint256 amount_,
        uint256 destinationChainId_,
        address recipient_,
        address refundAddress_
    ) external payable returns (bytes32 messageId_) {
        return bytes32(0);
    }
}
