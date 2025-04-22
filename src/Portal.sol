// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.26;

import { IERC20 } from "../lib/common/src/interfaces/IERC20.sol";
import { Migratable } from "../lib/common/src/Migratable.sol";
import { IndexingMath } from "../lib/common/src/libs/IndexingMath.sol";

import { IPortal } from "./interfaces/IPortal.sol";
import { IBridge } from "./interfaces/IBridge.sol";
import { PausableOwnable } from "./access/PausableOwnable.sol";
import { IWrappedMTokenLike } from "./interfaces/IWrappedMTokenLike.sol";
import { TypeConverter } from "./libs/TypeConverter.sol";
import { SafeCall } from "./libs/SafeCall.sol";
import { PayloadType, PayloadEncoder } from "./libs/PayloadEncoder.sol";

/**
 * @title  Base Portal contract inherited by HubPortal and SpokePortal.
 * @author M^0 Labs
 */
abstract contract Portal is IPortal, PausableOwnable, Migratable {
    using TypeConverter for *;
    using PayloadEncoder for bytes;
    using SafeCall for address;

    /// @inheritdoc IPortal
    address public immutable mToken;

    /// @inheritdoc IPortal
    address public immutable registrar;

    /// @inheritdoc IPortal
    address public bridge;

    /// @inheritdoc IPortal
    mapping(address sourceToken => mapping(uint256 destinationChainId => mapping(address destinationToken => bool supported)))
        public supportedBridgingPath;

    /// @inheritdoc IPortal
    mapping(uint256 destinationChainId => address mToken) public destinationMToken;

    /// @inheritdoc IPortal
    mapping(uint256 destinationChainId => mapping(PayloadType payloadType => uint256 gasLimit)) public payloadGasLimit;

    constructor(
        address mToken_,
        address registrar_,
        address bridge_,
        address initialOwner_,
        address initialPauser_
    ) PausableOwnable(initialOwner_, initialPauser_) {
        if ((mToken = mToken_) == address(0)) revert ZeroMToken();
        if ((registrar = registrar_) == address(0)) revert ZeroRegistrar();
        if ((bridge = bridge_) == address(0)) revert ZeroBridge();
    }

    ///////////////////////////////////////////////////////////////////////////
    //                     EXTERNAL VIEW/PURE FUNCTIONS                      //
    ///////////////////////////////////////////////////////////////////////////

    /// @inheritdoc IPortal
    function currentIndex() external view returns (uint128) {
        return _currentIndex();
    }

    ///////////////////////////////////////////////////////////////////////////
    //                     EXTERNAL INTERACTIVE FUNCTIONS                    //
    ///////////////////////////////////////////////////////////////////////////

    /// @inheritdoc IPortal
    function transfer(
        uint256 amount_,
        uint256 destinationChainId_,
        address recipient_,
        address refundAddress_
    ) external payable returns (bytes32 messageId_) {
        return _transferMLikeToken(
            amount_, mToken, destinationChainId_, destinationMToken[destinationChainId_], recipient_, refundAddress_
        );
    }

    /// @inheritdoc IPortal
    function transferMLikeToken(
        uint256 amount_,
        address sourceToken_,
        uint256 destinationChainId_,
        address destinationToken_,
        address recipient_,
        address refundAddress_
    ) external payable returns (bytes32 messageId_) {
        if (!supportedBridgingPath[sourceToken_][destinationChainId_][destinationToken_]) {
            revert UnsupportedBridgingPath(sourceToken_, destinationChainId_, destinationToken_);
        }

        return _transferMLikeToken(amount_, sourceToken_, destinationChainId_, destinationToken_, recipient_, refundAddress_);
    }

    /// @inheritdoc IPortal
    function receiveMessage(uint256 sourceChainId_, address sender_, bytes calldata payload_) external {
        if (msg.sender != bridge) revert NotBridge();

        PayloadType payloadType_ = payload_.getPayloadType();

        if (payloadType_ == PayloadType.Token) {
            _receiveMLikeToken(sourceChainId_, sender_, payload_);
            return;
        }

        _receiveCustomPayload(payloadType_, payload_);
    }

    ///////////////////////////////////////////////////////////////////////////
    //                     OWNER INTERACTIVE FUNCTIONS                       //
    ///////////////////////////////////////////////////////////////////////////

    /// @inheritdoc IPortal
    function setBridge(address newBridge_) external onlyOwner {
        if (newBridge_ == address(0)) revert ZeroBridge();
        address previousBridge_ = bridge;
        bridge = newBridge_;
        emit BridgeSet(previousBridge_, newBridge_);
    }

    /// @inheritdoc IPortal
    function setDestinationMToken(uint256 destinationChainId_, address mToken_) external onlyOwner {
        if (destinationChainId_ == block.chainid) revert InvalidDestinationChain(destinationChainId_);
        if (mToken_ == address(0)) revert ZeroMToken();

        destinationMToken[destinationChainId_] = mToken_;
        emit DestinationMTokenSet(destinationChainId_, mToken_);
    }

    /// @inheritdoc IPortal
    function setSupportedBridgingPath(
        address sourceToken_,
        uint256 destinationChainId_,
        address destinationToken_,
        bool supported_
    ) external onlyOwner {
        if (sourceToken_ == address(0)) revert ZeroSourceToken();
        if (destinationChainId_ == block.chainid) revert InvalidDestinationChain(destinationChainId_);
        if (destinationToken_ == address(0)) revert ZeroDestinationToken();

        supportedBridgingPath[sourceToken_][destinationChainId_][destinationToken_] = supported_;
        emit SupportedBridgingPathSet(sourceToken_, destinationChainId_, destinationToken_, supported_);
    }

    /// @inheritdoc IPortal
    function setPayloadGasLimit(uint256 destinationChainId_, PayloadType payloadType_, uint256 gasLimit_) external onlyOwner {
        payloadGasLimit[destinationChainId_][payloadType_] = gasLimit_;
        emit PayloadGasLimitSet(destinationChainId_, payloadType_, gasLimit_);
    }

    /**
     * @dev   Performs the contract migration by delegate-calling `migrator_`.
     * @param migrator_ The address of a migrator contract.
     */
    function migrate(address migrator_) external onlyOwner {
        _migrate(migrator_);
    }

    ///////////////////////////////////////////////////////////////////////////
    //                INTERNAL/PRIVATE INTERACTIVE FUNCTIONS                 //
    ///////////////////////////////////////////////////////////////////////////

    /**
     * @dev Transfers M or Wrapped M token to the remote chain.
     * @param  amount_             The amount of tokens to transfer.
     * @param  sourceToken_        The address of the source token.
     * @param  destinationChainId_ The EVM chain Id of the destination chain.
     * @param  destinationToken_   The address of the destination token.
     * @param  recipient_          The address of the recipient.
     * @param  refundAddress_      The address to receive the fee refund.
     * @return messageId_          The ID uniquely identifying the message.
     */
    function _transferMLikeToken(
        uint256 amount_,
        address sourceToken_,
        uint256 destinationChainId_,
        address destinationToken_,
        address recipient_,
        address refundAddress_
    ) private returns (bytes32 messageId_) {
        _verifyTransferAmount(amount_);

        if (destinationToken_ == address(0)) revert ZeroDestinationToken();
        if (recipient_ == address(0)) revert ZeroRecipient();
        if (refundAddress_ == address(0)) revert ZeroRefundAddress();

        IERC20 mToken_ = IERC20(mToken);
        uint256 startingBalance_ = mToken_.balanceOf(address(this));

        // transfer source token from the sender
        IERC20(sourceToken_).transferFrom(msg.sender, address(this), amount_);

        // if the source token isn't M token, unwrap it
        if (sourceToken_ != address(mToken_)) {
            IWrappedMTokenLike(sourceToken_).unwrap(address(this), amount_);
        }

        // The actual amount of M tokens that Portal received from the sender.
        // Accounts for potential rounding errors when transferring between earners and non-earners,
        // as well as potential fee-on-transfer functionality in the source token.
        uint256 actualAmount_ = mToken_.balanceOf(address(this)) - startingBalance_;

        if (amount_ > actualAmount_) {
            unchecked {
                // If the difference between the specified transfer amount and the actual amount exceeds
                // the maximum acceptable rounding error (e.g., due to fee-on-transfer in an extension token)
                // transfer the actual amount, not the specified.

                // Otherwise, the specified amount will be transferred and the deficit caused by rounding error will
                // be covered from the yield earned by HubPortal.
                if (amount_ - actualAmount_ > _getMaxRoundingError()) {
                    amount_ = actualAmount_;
                    // Ensure that updated transfer amount is greater than 0
                    _verifyTransferAmount(amount_);
                }
            }
        }

        // Burn the actual amount of M tokens on Spoke.
        // In case of Hub, do nothing, as tokens are already transferred.
        _burnOrLock(actualAmount_);

        uint128 index_ = _currentIndex();
        bytes memory payload_ = PayloadEncoder.encodeTokenTransfer(amount_, destinationToken_, recipient_, index_);
        messageId_ = _sendMessage(destinationChainId_, PayloadType.Token, refundAddress_, payload_);
        // prevent stack too deep
        uint256 transferAmount_ = amount_;

        emit MTokenSent(
            sourceToken_, destinationChainId_, destinationToken_, msg.sender, recipient_, transferAmount_, index_, messageId_
        );
    }

    /**
     * @dev   Sends a cross-chain message using bridge.
     * @param destinationChainId_ The EVM chain Id of the destination chain.
     * @param payloadType_        The type of the payload.
     * @param refundAddress_      The address to receive the fee refund.
     * @param payload_            The message payload to send.
     * @return messageId_         The ID uniquely identifying the message.
     */
    function _sendMessage(
        uint256 destinationChainId_,
        PayloadType payloadType_,
        address refundAddress_,
        bytes memory payload_
    ) internal returns (bytes32 messageId_) {
        return IBridge(bridge).sendMessage{ value: msg.value }(
            destinationChainId_, payloadGasLimit[destinationChainId_][payloadType_], refundAddress_, payload_
        );
    }

    /**
     * @dev   Handles token transfer message on the destination.
     * @param sourceChainId_ The EVM chain Id of the source chain.
     * @param sender_        The address of the message sender.
     * @param payload_       The message payload.
     */
    function _receiveMLikeToken(uint256 sourceChainId_, address sender_, bytes memory payload_) private {
        (uint256 amount_, address destinationToken_, address recipient_, uint128 index_) = payload_.decodeTokenTransfer();

        emit MTokenReceived(sourceChainId_, destinationToken_, sender_, recipient_, amount_, index_);

        address mToken_ = mToken;
        if (destinationToken_ == mToken_) {
            // mints or unlocks M Token to the recipient
            _mintOrUnlock(recipient_, amount_, index_);
        } else {
            // mints or unlocks M Token to the Portal
            _mintOrUnlock(address(this), amount_, index_);

            // wraps M token and transfers it to the recipient
            _wrap(mToken_, destinationToken_, recipient_, amount_);
        }
    }

    /**
     * @dev   Wraps M token to the token specified by `destinationWrappedToken_`.
     *        If wrapping fails transfers $M token to `recipient_`.
     * @param mToken_                  The address of M token.
     * @param destinationWrappedToken_ The address of the wrapped token.
     * @param recipient_               The account to receive wrapped token.
     * @param amount_                  The amount to wrap.
     */
    function _wrap(address mToken_, address destinationWrappedToken_, address recipient_, uint256 amount_) private {
        IERC20(mToken_).approve(destinationWrappedToken_, amount_);

        // Attempt to wrap $M token
        // NOTE: the call might fail with out-of-gas exception
        //       even if the destination token is the valid wrapped M token.
        //       Recipients must support both $M and wrapped $M transfers.
        bool success = destinationWrappedToken_.safeCall(abi.encodeCall(IWrappedMTokenLike.wrap, (recipient_, amount_)));

        if (!success) {
            emit WrapFailed(destinationWrappedToken_, recipient_, amount_);
            // reset approval to prevent a potential double-spend attack
            IERC20(mToken_).approve(destinationWrappedToken_, 0);
            // transfer $M token to the recipient
            IERC20(mToken_).transfer(recipient_, amount_);
        }
    }

    /**
     * @dev   Overridden in SpokePortal to handle custom payload messages.
     * @param payloadType_  The type of the payload (Index, Key, or List).
     * @param payload_      The message payload to process.
     */
    function _receiveCustomPayload(PayloadType payloadType_, bytes memory payload_) internal virtual { }

    /**
     * @dev   HubPortal:   unlocks and transfers `amount_` M tokens to `recipient_`.
     *        SpokePortal: mints `amount_` M tokens to `recipient_`.
     * @param recipient_ The account receiving M tokens.
     * @param amount_    The amount of M tokens to unlock/mint.
     * @param index_     The index from the source chain.
     */
    function _mintOrUnlock(address recipient_, uint256 amount_, uint128 index_) internal virtual { }

    /**
     * @dev   HubPortal:   locks amount_` M tokens.
     *        SpokePortal: burns `amount_` M tokens.
     * @param amount_ The amount of M tokens to lock/burn.
     */
    function _burnOrLock(uint256 amount_) internal virtual { }

    ///////////////////////////////////////////////////////////////////////////
    //                 INTERNAL/PRIVATE VIEW/PURE FUNCTIONS                  //
    ///////////////////////////////////////////////////////////////////////////

    /// @dev Verifies that the transfer amount isn't zero.
    function _verifyTransferAmount(uint256 amount_) private pure {
        if (amount_ == 0) revert ZeroAmount();
    }

    /// @inheritdoc Migratable
    function _getMigrator() internal pure override returns (address migrator_) {
        // NOTE: in this version only the owner-controlled migration via `migrate()` function is supported
        return address(0);
    }

    /// @dev Returns the current M token index used by the Portal.
    function _currentIndex() internal view virtual returns (uint128) { }

    /// @dev Returns the maximum rounding error that can occur when transferring M tokens to the Portal
    function _getMaxRoundingError() private view returns (uint256) {
        return _currentIndex() / IndexingMath.EXP_SCALED_ONE + 1;
    }
}
