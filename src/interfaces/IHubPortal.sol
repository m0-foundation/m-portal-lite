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
     * @param  messageId The unique identifier for the sent message.
     * @param  index     The the M token index.
     */
    event MTokenIndexSent(bytes32 messageId, uint128 index);

    /**
     * @notice Emitted when the Registrar key is sent to a destination chain.
     * @param  messageId The unique identifier for the sent message.
     * @param  key       The key that was sent.
     * @param  value     The value that was sent.
     */
    event RegistrarKeySent(bytes32 messageId, bytes32 indexed key, bytes32 value);

    /**
     * @notice Emitted when the Registrar list status for an account is sent to a destination chain.
     * @param  messageId The unique identifier for the sent message.
     * @param  listName  The name of the list.
     * @param  account   The account.
     * @param  status    The status of the account in the list.
     */
    event RegistrarListStatusSent(bytes32 messageId, bytes32 indexed listName, address indexed account, bool status);

    ///////////////////////////////////////////////////////////////////////////
    //                             CUSTOM ERRORS                             //
    ///////////////////////////////////////////////////////////////////////////

    /// @notice Thrown when trying to enable earning after it has been explicitly disabled.
    error EarningCannotBeReenabled();

    /// @notice Thrown when performing an operation that is not allowed when earning is disabled.
    error EarningIsDisabled();

    /// @notice Thrown when performing an operation that is not allowed when earning is enabled.
    error EarningIsEnabled();

    ///////////////////////////////////////////////////////////////////////////
    //                          VIEW/PURE FUNCTIONS                          //
    ///////////////////////////////////////////////////////////////////////////

    /// @notice Indicates whether earning for HubPortal was ever enabled.
    function wasEarningEnabled() external returns (bool);

    /// @notice Returns the value of M Token index when earning for HubPortal was disabled.
    function disableEarningIndex() external returns (uint128);

    ///////////////////////////////////////////////////////////////////////////
    //                         INTERACTIVE FUNCTIONS                         //
    ///////////////////////////////////////////////////////////////////////////

    /**
     * @notice Sends the M token index to the destination chain.
     * @param  destinationChainId The EVM chain Id of the destination chain.
     * @param  refundAddress      The refund address to receive excess native gas.
     * @return messageId          The ID uniquely identifying the message.
     */
    function sendMTokenIndex(uint256 destinationChainId, address refundAddress) external payable returns (bytes32 messageId);

    /**
     * @notice Sends the Registrar key to the destination chain.
     * @param  destinationChainId The EVM chain Id of the destination chain.
     * @param  key                The key to dispatch.
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
