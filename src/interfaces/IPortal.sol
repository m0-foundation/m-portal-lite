// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.26;

import { PayloadType } from "../libs/PayloadEncoder.sol";

/**
 * @title  IPortal interface
 * @author M^0 Labs
 * @notice Subset of functions inherited by both IHubPortal and ISpokePortal.
 */
interface IPortal {
    ///////////////////////////////////////////////////////////////////////////
    //                                 EVENTS                                //
    ///////////////////////////////////////////////////////////////////////////

    /**
     * @notice Emitted when M token is sent to a destination chain.
     * @param  sourceToken      The address of the token on the source chain.
     * @param  destinationToken The address of the token on the destination chain.
     * @param  sender           The address that bridged the M tokens via the Portal.
     * @param  recipient        The account receiving tokens on destination chain.
     * @param  amount           The amount of tokens.
     * @param  index            The M token index.
     * @param  messageId        The unique identifier for the sent message.
     */
    event MTokenSent(
        address indexed sourceToken,
        address destinationToken,
        address indexed sender,
        address indexed recipient,
        uint256 amount,
        uint128 index,
        bytes32 messageId
    );

    /**
     * @notice Emitted when M token is received from a source chain.
     * @param  destinationToken The address of the token on the destination chain.
     * @param  sender           The account sending tokens.
     * @param  recipient        The account receiving tokens.
     * @param  amount           The amount of tokens.
     * @param  index            The M token index
     */
    event MTokenReceived(
        address indexed destinationToken,
        address indexed sender,
        address indexed recipient,
        uint256 amount,
        uint128 index
    );

    /**
     * @notice Emitted when wrapping M token is failed on the destination.
     * @param  destinationWrappedToken The address of the Wrapped M Token on the destination chain.
     * @param  recipient               The account receiving tokens.
     * @param  amount                  The amount of tokens.
     */
    event WrapFailed(address indexed destinationWrappedToken, address indexed recipient, uint256 amount);

    event BridgeSet(address indexed previousBridge, address indexed newBridge);

    /**
     * @notice Emitted when a bridging path support status is updated.
     * @param  sourceToken       The address of the token on the current chain.
     * @param  destinationToken  The address of the token on the destination chain.
     * @param  supported         `True` if the token is supported, `false` otherwise.
     */
    event SupportedBridgingPathSet(address indexed sourceToken, address indexed destinationToken, bool supported);

    /**
     * @notice Emitted when the gas limit for a payload type is updated.
     * @param  payloadType The type of payload.
     * @param  gasLimit    The gas limit.
     */
    event PayloadGasLimitSet(PayloadType indexed payloadType, uint256 gasLimit);

    ///////////////////////////////////////////////////////////////////////////
    //                             CUSTOM ERRORS                             //
    ///////////////////////////////////////////////////////////////////////////

    /// @notice Thrown when the M token is 0x0.
    error ZeroMToken();

    /// @notice Thrown when the M token is 0x0.
    error ZeroRemoteMToken();

    /// @notice Thrown when the Registrar address is 0x0.
    error ZeroRegistrar();

    /// @notice Thrown when the Bridge address is 0x0.
    error ZeroBridge();

    /// @notice Thrown when the source token address is 0x0.
    error ZeroSourceToken();

    /// @notice Thrown when the destination token address is 0x0.
    error ZeroDestinationToken();

    /// @notice Thrown in `transferMLikeToken` function when bridging path is not supported
    error UnsupportedBridgingPath(address sourceToken, address destinationToken);

    /// @notice Thrown when the transfer amount is 0.
    error ZeroAmount();

    /// @notice Thrown when the refund address is 0x0.
    error ZeroRefundAddress();

    /// @notice Thrown when the recipient address is 0x0.
    error ZeroRecipient();

    /// @notice Thrown when `receiveMessage` function caller is not the bridge.
    error NotBridge();

    ///////////////////////////////////////////////////////////////////////////
    //                          VIEW/PURE FUNCTIONS                          //
    ///////////////////////////////////////////////////////////////////////////

    /// @notice The current index of the Portal's earning mechanism.
    function currentIndex() external view returns (uint128);

    /// @notice The address of the M token.
    function mToken() external view returns (address);

    /// @notice The address of the Registrar contract.
    function registrar() external view returns (address);

    /// @notice The address of the Bridge contract responsible for cross-chain communication.
    function bridge() external view returns (address);

    /// @notice The address of M token on the remote chain.
    function remoteMToken() external view returns (address mToken);

    /**
     * @notice Indicates whether the provided bridging path is supported.
     * @param  sourceToken      The address of the token on the current chain.
     * @param  destinationToken The address of the token on the destination chain.
     * @return supported        `True` if the token is supported, `false` otherwise.
     */
    function supportedBridgingPath(
        address sourceToken,
        address destinationToken
    ) external view returns (bool supported);

    /**
     * @notice Returns the gas limit required to process a message
     *         with the specified payload type on the destination chain.
     * @param  payloadType The type of payload.
     * @return gasLimit    The gas limit.
     */
    function payloadGasLimit(PayloadType payloadType) external view returns (uint256 gasLimit);

    ///////////////////////////////////////////////////////////////////////////
    //                         INTERACTIVE FUNCTIONS                         //
    ///////////////////////////////////////////////////////////////////////////

    /**
     * @notice Sets address of the Bridge contract responsible for cross-chain communication.
     * @param  bridge The address of the Bridge.
     */
    function setBridge(address bridge) external;

    /**
     * @notice Sets a bridging path support status.
     * @param  sourceToken      The address of the token on the current chain.
     * @param  destinationToken The address of the token on the destination chain.
     * @param  supported        `True` if the bridging path is supported, `false` otherwise.
     */
    function setSupportedBridgingPath(address sourceToken, address destinationToken, bool supported) external;

    /**
     * @notice Sets the gas limit required to process a message
     *         with the specified payload type on the destination chain.
     * @param  payloadType The payload type.
     * @param  gasLimit    The gas limit required to process the message.
     */
    function setPayloadGasLimit(PayloadType payloadType, uint256 gasLimit) external;

    /**
     * @notice Transfers M token to the destination chain.
     * @param  amount        The amount of tokens to transfer.
     * @param  recipient     The account to receive tokens.
     * @param  refundAddress The address to receive excess native gas on the source chain.
     * @return messageId     The unique identifier of the message sent.
     */
    function transfer(
        uint256 amount,
        address recipient,
        address refundAddress
    ) external payable returns (bytes32 messageId);

    /**
     * @notice Transfers M or Wrapped M Token to the destination chain.
     * @dev    If wrapping on the destination fails, the recipient will receive $M token.
     * @param  amount           The amount of tokens to transfer.
     * @param  sourceToken      The address of the token (M or Wrapped M) on the source chain.
     * @param  destinationToken The address of the token (M or Wrapped M) on the destination chain.
     * @param  recipient        The account to receive tokens.
     * @param  refundAddress    The address to receive excess native gas on the source chain.
     * @return messageId        The unique identifier of the message sent.
     */
    function transferMLikeToken(
        uint256 amount,
        address sourceToken,
        address destinationToken,
        address recipient,
        address refundAddress
    ) external payable returns (bytes32 messageId);

    /**
     * @notice Receives a message from the bridge.
     * @param  sender   The address of the message sender.
     * @param  payload  The message payload.
     */
    function receiveMessage(address sender, bytes calldata payload) external;
}
