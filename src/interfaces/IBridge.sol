// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.26;

interface IBridge {
    ///////////////////////////////////////////////////////////////////////////
    //                             CUSTOM ERRORS                             //
    ///////////////////////////////////////////////////////////////////////////

    /// @notice Thrown when `sendMessage` function caller is not the portal.
    error NotPortal();

    /// @notice Thrown when the portal address is 0x0.
    error ZeroPortal();

    ///////////////////////////////////////////////////////////////////////////
    //                          VIEW/PURE FUNCTIONS                          //
    ///////////////////////////////////////////////////////////////////////////

    /// @notice Returns the address of the portal.
    function portal() external view returns (address);

    /**
     * @notice Returns the fee for sending a message to the remote chain
     * @param  destinationChainId The EVM chain Id of the destination chain.
     * @param  gasLimit           The gas limit to execute the message on the destination chain.
     * @param  payload            The message payload to send.
     * @return fee                The fee for sending a message.
     */
    function quote(uint256 destinationChainId, uint256 gasLimit, bytes memory payload) external view returns (uint256 fee);

    ///////////////////////////////////////////////////////////////////////////
    //                         INTERACTIVE FUNCTIONS                         //
    ///////////////////////////////////////////////////////////////////////////

    /**
     * @notice Sends a message to the remote chain.
     * @dev    Only EVM chains are supported.
     * @param  destinationChainId The EVM chain Id of the destination chain.
     * @param  gasLimit           The gas limit to execute the message on the destination chain.
     * @param  refundAddress      The address to refund the fee to.
     * @param  payload            The message payload to send.
     * @return messageId          The unique identifier of the message sent.
     */
    function sendMessage(
        uint256 destinationChainId,
        uint256 gasLimit,
        address refundAddress,
        bytes memory payload
    ) external payable returns (bytes32 messageId);
}
