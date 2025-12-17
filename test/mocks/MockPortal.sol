// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.26;

contract MockPortal {
    function receiveMessage(uint256, bytes calldata) external { }

    function transferMLikeToken(
        uint256 amount_,
        address sourceToken_,
        uint256 destinationChainId_,
        address destinationToken_,
        address recipient_,
        address refundAddress_
    ) external payable returns (bytes32 messageId_) {
        return bytes32(0);
    }
}
