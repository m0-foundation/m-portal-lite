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
     * @param  sourceToken        The address of the token on the source chain.
     * @param  destinationChainId The EVM chain Id of the destination chain.
     * @param  destinationToken   The address of the token on the destination chain.
     * @param  sender             The address that bridged the M tokens via the Portal.
     * @param  recipient          The account receiving tokens on destination chain.
     * @param  amount             The amount of tokens.
     * @param  index              The M token index.
     * @param  messageId          The unique identifier for the sent message.
     */
    event MTokenSent(
        address indexed sourceToken,
        uint256 destinationChainId,
        address destinationToken,
        address indexed sender,
        address indexed recipient,
        uint256 amount,
        uint128 index,
        bytes32 messageId
    );

    /**
     * @notice Emitted when M token is received from a source chain.
     * @param  sourceChainId    The EVM chain Id of the source chain.
     * @param  destinationToken The address of the token on the destination chain.
     * @param  sender           The account sending tokens.
     * @param  recipient        The account receiving tokens.
     * @param  amount           The amount of tokens.
     * @param  index            The M token index
     */
    event MTokenReceived(
        uint256 sourceChainId,
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

    /**
     * @notice Emitted when the Bridge contract responsible for cross-chain communication is set
     * @param  previousBridge The address of the previous Bridge.
     * @param  newBridge      The address of the new Bridge.
     */
    event BridgeSet(address indexed previousBridge, address indexed newBridge);

    /**
     * @notice Emitted when M token is set for the remote chain.
     * @param  destinationChainId The EVM chain Id of the destination chain.
     * @param  mToken             The address of M token on the destination chain.
     */
    event DestinationMTokenSet(uint256 indexed destinationChainId, address mToken);

    /**
     * @notice Emitted when a bridging path support status is updated.
     * @param  sourceToken        The address of the token on the current chain.
     * @param  destinationChainId The EVM chain Id of the destination chain.
     * @param  destinationToken   The address of the token on the destination chain.
     * @param  supported          `True` if the token is supported, `false` otherwise.
     */
    event SupportedBridgingPathSet(
        address indexed sourceToken, uint256 indexed destinationChainId, address indexed destinationToken, bool supported
    );

    /**
     * @notice Emitted when the gas limit for a payload type is updated.
     * @param  destinationChainId The EVM chain Id of the destination chain.
     * @param  payloadType        The type of payload.
     * @param  gasLimit           The gas limit.
     */
    event PayloadGasLimitSet(uint256 indexed destinationChainId, PayloadType indexed payloadType, uint256 gasLimit);

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

    /// @notice Thrown when the transfer amount is 0.
    error ZeroAmount();

    /// @notice Thrown when the refund address is 0x0.
    error ZeroRefundAddress();

    /// @notice Thrown when the recipient address is 0x0.
    error ZeroRecipient();

    /// @notice Thrown when `receiveMessage` function caller is not the bridge.
    error NotBridge();

    /// @notice Thrown in `transferMLikeToken` function when bridging path is not supported
    error UnsupportedBridgingPath(address sourceToken, uint256 destinationChainId, address destinationToken);

    /// @notice Thrown when the destination chain id is equal to the source one.
    error InvalidDestinationChain(uint256 destinationChainId);

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

    /**
     * @notice Returns the address of M token on the destination chain.
     * @param  destinationChainId The EVM chain Id of the destination chain.
     * @return mToken             The address of M token on the destination chain.
     */
    function destinationMToken(uint256 destinationChainId) external view returns (address mToken);

    /**
     * @notice Indicates whether the provided bridging path is supported.
     * @param  sourceToken        The address of the token on the current chain.
     * @param  destinationChainId The EVM chain Id of the destination chain.
     * @param  destinationToken   The address of the token on the destination chain.
     * @return supported          `True` if the token is supported, `false` otherwise.
     */
    function supportedBridgingPath(
        address sourceToken,
        uint256 destinationChainId,
        address destinationToken
    ) external view returns (bool supported);

    /**
     * @notice Returns the gas limit required to process a message
     *         with the specified payload type on the destination chain.
     * @param  destinationChainId The EVM chain Id of the destination chain.
     * @param  payloadType        The type of payload.
     * @return gasLimit           The gas limit.
     */
    function payloadGasLimit(uint256 destinationChainId, PayloadType payloadType) external view returns (uint256 gasLimit);

    /**
     * @notice Returns the delivery fee for token transfer.
     * @dev    The fee must be passed as mgs.value when calling `transfer` or `transferMLikeToken`.
     * @param  amount             The amount of tokens to transfer.
     * @param  destinationChainId The EVM chain Id of the destination chain.
     * @param  recipient          The account to receive tokens.
     * @param  fee                The delivery fee.
     */
    function quoteTransfer(uint256 amount, uint256 destinationChainId, address recipient) external view returns (uint256 fee);

    ///////////////////////////////////////////////////////////////////////////
    //                         INTERACTIVE FUNCTIONS                         //
    ///////////////////////////////////////////////////////////////////////////

    /**
     * @notice Initializes the Proxy's storage
     * @param  bridge_        The address of the Bridge contract.
     * @param  initialOwner_  The address of the owner.
     * @param  initialPauser_ The address of the pauser.
     */
    function initialize(address bridge_, address initialOwner_, address initialPauser_) external;

    /**
     * @notice Sets address of the Bridge contract responsible for cross-chain communication.
     * @param  bridge The address of the Bridge.
     */
    function setBridge(address bridge) external;

    /**
     * @notice Sets M token address on the remote chain.
     * @param  destinationChainId The EVM chain Id of the destination chain.
     * @param  mToken             The address of M token on the destination chain.
     */
    function setDestinationMToken(uint256 destinationChainId, address mToken) external;

    /**
     * @notice Sets a bridging path support status.
     * @param  sourceToken        The address of the token on the current chain.
     * @param  destinationChainId The EVM chain Id of the destination chain.
     * @param  destinationToken   The address of the token on the destination chain.
     * @param  supported          `True` if the token is supported, `false` otherwise.
     */
    function setSupportedBridgingPath(
        address sourceToken,
        uint256 destinationChainId,
        address destinationToken,
        bool supported
    ) external;

    /**
     * @notice Sets the gas limit required to process a message
     *         with the specified payload type on the destination chain.
     * @param  destinationChainId The EVM chain Id of the destination chain.
     * @param  payloadType        The payload type.
     * @param  gasLimit           The gas limit required to process the message.
     */
    function setPayloadGasLimit(uint256 destinationChainId, PayloadType payloadType, uint256 gasLimit) external;

    /**
     * @notice Transfers M token to the destination chain.
     * @param  amount             The amount of tokens to transfer.
     * @param  destinationChainId The EVM chain Id of the destination chain.
     * @param  recipient          The account to receive tokens.
     * @param  refundAddress      The address to receive excess native gas on the source chain.
     * @return messageId          The unique identifier of the message sent.
     */
    function transfer(
        uint256 amount,
        uint256 destinationChainId,
        address recipient,
        address refundAddress
    ) external payable returns (bytes32 messageId);

    /**
     * @notice Transfers M or Wrapped M Token to the destination chain.
     * @dev    If wrapping on the destination fails, the recipient will receive $M token.
     * @param  amount             The amount of tokens to transfer.
     * @param  sourceToken        The address of the token (M or Wrapped M) on the source chain.
     * @param  destinationChainId The EVM chain Id of the destination chain.
     * @param  destinationToken   The address of the token (M or Wrapped M) on the destination chain.
     * @param  recipient          The account to receive tokens.
     * @param  refundAddress      The address to receive excess native gas on the source chain.
     * @return messageId          The unique identifier of the message sent.
     */
    function transferMLikeToken(
        uint256 amount,
        address sourceToken,
        uint256 destinationChainId,
        address destinationToken,
        address recipient,
        address refundAddress
    ) external payable returns (bytes32 messageId);

    /**
     * @notice Receives a message from the bridge.
     * @param  sourceChainId The EVM chain Id of the source chain.
     * @param  sender        The address of the message sender.
     * @param  payload       The message payload.
     */
    function receiveMessage(uint256 sourceChainId, address sender, bytes calldata payload) external;
}
