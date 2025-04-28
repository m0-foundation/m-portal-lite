// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.26;

import { IPortal } from "./IPortal.sol";

/**
 * @title  HubPortal interface.
 * @author M^0 Labs
 */
interface IHubPortal is IPortal {
    ///////////////////////////////////////////////////////////////////////////
    //                                 EVENTS                                //
    ///////////////////////////////////////////////////////////////////////////

    /**
     * @notice Emitted when earning is enabled for the Hub Portal.
     * @param  index The index at which earning was enabled.
     */
    event EarningEnabled(uint128 index);

    /**
     * @notice Emitted when earning is disabled for the Hub Portal.
     * @param  index The index at which earning was disabled.
     */
    event EarningDisabled(uint128 index);

    /**
     * @notice Emitted when the M token index is sent to a destination chain.
     * @param  destinationChainId The EVM chain Id of the destination chain.
     * @param  messageId          The unique identifier for the sent message.
     * @param  index              The the M token index.
     */
    event MTokenIndexSent(uint256 destinationChainId, bytes32 messageId, uint128 index);

    /**
     * @notice Emitted when the Registrar key is sent to a destination chain.
     * @param  destinationChainId The EVM chain Id of the destination chain.
     * @param  messageId          The unique identifier for the sent message.
     * @param  key                The key that was sent.
     * @param  value              The value that was sent.
     */
    event RegistrarKeySent(uint256 destinationChainId, bytes32 messageId, bytes32 indexed key, bytes32 value);

    /**
     * @notice Emitted when the Registrar list status for an account is sent to a destination chain.
     * @param  destinationChainId The EVM chain Id of the destination chain.
     * @param  messageId          The unique identifier for the sent message.
     * @param  listName           The name of the list.
     * @param  account            The account.
     * @param  status             The status of the account in the list.
     */
    event RegistrarListStatusSent(
        uint256 destinationChainId, bytes32 messageId, bytes32 indexed listName, address indexed account, bool status
    );

    ///////////////////////////////////////////////////////////////////////////
    //                             CUSTOM ERRORS                             //
    ///////////////////////////////////////////////////////////////////////////

    /// @notice Thrown when trying to enable earning after it has been explicitly disabled.
    error EarningCannotBeReenabled();

    /// @notice Thrown when performing an operation that is not allowed when earning is disabled.
    error EarningIsDisabled();

    /// @notice Thrown when performing an operation that is not allowed when earning is enabled.
    error EarningIsEnabled();

    /// @notice Thrown when trying to unlock more tokens than was locked.
    error InsufficientBridgedBalance();

    ///////////////////////////////////////////////////////////////////////////
    //                          VIEW/PURE FUNCTIONS                          //
    ///////////////////////////////////////////////////////////////////////////

    /// @notice Indicates whether earning for HubPortal was ever enabled.
    function wasEarningEnabled() external view returns (bool);

    /// @notice Returns the value of M token index when earning for HubPortal was disabled.
    function disableEarningIndex() external view returns (uint128);

    /// @notice Returns the principal amount of M tokens bridged to the destination chain.
    function bridgedPrincipal(uint256 destinationChainId) external view returns (uint256 principal);

    /**
     * @notice Returns the delivery fee for sending $M token index.
     * @dev    The fee must be passed as mgs.value when calling `sendMTokenIndex`.
     * @param  destinationChainId The EVM chain Id of the destination chain.
     * @param  fee                The delivery fee.
     */
    function quoteSendIndex(uint256 destinationChainId) external view returns (uint256 fee);

    /**
     * @notice Returns the delivery fee for sending Registrar key and value.
     * @dev    The fee must be passed as mgs.value when calling `sendRegistrarKey`.
     * @param  destinationChainId The EVM chain Id of the destination chain.
     * @param  key                The Registrar key to send.
     * @param  fee                The delivery fee.
     */
    function quoteSendRegistrarKey(uint256 destinationChainId, bytes32 key) external view returns (uint256 fee);

    /**
     * @notice Returns the delivery fee for sending Registrar list status.
     * @dev    The fee must be passed as mgs.value when calling `sendRegistrarListStatus`.
     * @param  destinationChainId The EVM chain Id of the destination chain.
     * @param  listName           The name of the list.
     * @param  account            The account.
     * @param  fee                The delivery fee.
     */
    function quoteSendRegistrarListStatus(
        uint256 destinationChainId,
        bytes32 listName,
        address account
    ) external view returns (uint256 fee);

    ///////////////////////////////////////////////////////////////////////////
    //                         INTERACTIVE FUNCTIONS                         //
    ///////////////////////////////////////////////////////////////////////////

    /**
     * @notice Sends the $M token index to the destination chain.
     * @param  destinationChainId The EVM chain Id of the destination chain.
     * @param  refundAddress      The refund address to receive excess native gas.
     * @return messageId          The ID uniquely identifying the message.
     */
    function sendMTokenIndex(uint256 destinationChainId, address refundAddress) external payable returns (bytes32 messageId);

    /**
     * @notice Sends the Registrar key to the destination chain.
     * @param  destinationChainId The EVM chain Id of the destination chain.
     * @param  key                The key to send.
     * @param  refundAddress      The refund address to receive excess native gas.
     * @return messageId          The ID uniquely identifying the message
     */
    function sendRegistrarKey(
        uint256 destinationChainId,
        bytes32 key,
        address refundAddress
    ) external payable returns (bytes32 messageId);

    /**
     * @notice Sends the Registrar list status for an account to the destination chain.
     * @param  destinationChainId The EVM chain Id of the destination chain.
     * @param  listName           The name of the list.
     * @param  account            The account.
     * @param  refundAddress      The refund address to receive excess native gas.
     * @return messageId          The ID uniquely identifying the message.
     */
    function sendRegistrarListStatus(
        uint256 destinationChainId,
        bytes32 listName,
        address account,
        address refundAddress
    ) external payable returns (bytes32 messageId);

    /// @notice Enables earning for the Hub Portal if allowed by TTG.
    function enableEarning() external;

    /// @notice Disables earning for the Hub Portal if disallowed by TTG.
    function disableEarning() external;
}
