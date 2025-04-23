// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.26;

import { IERC20 } from "../lib/common/src/interfaces/IERC20.sol";
import { IndexingMath } from "../lib/common/src/libs/IndexingMath.sol";

import { IMTokenLike } from "./interfaces/IMTokenLike.sol";
import { IRegistrarLike } from "./interfaces/IRegistrarLike.sol";
import { IHubPortal } from "./interfaces/IHubPortal.sol";

import { Portal } from "./Portal.sol";
import { PayloadType, PayloadEncoder } from "./libs/PayloadEncoder.sol";

/**
 * @title  HubPortal
 * @author M^0 Labs
 * @notice Deployed on Ethereum Mainnet and responsible for sending and receiving M tokens
 *         as well as propagating M token index, Registrar keys and list status to the Spoke chain.
 * @dev    Tokens are bridged using lock-release mechanism.
 */
contract HubPortal is Portal, IHubPortal {
    /// @inheritdoc IHubPortal
    bool public wasEarningEnabled;

    /// @inheritdoc IHubPortal
    uint128 public disableEarningIndex;

    /// @inheritdoc IHubPortal
    mapping(uint256 destinationChainId => uint256 principal) public bridgedPrincipal;

    constructor(
        address mToken_,
        address registrar_,
        address bridge_,
        address initialOwner_,
        address initialPauser_
    ) Portal(mToken_, registrar_, bridge_, initialOwner_, initialPauser_) { }

    ///////////////////////////////////////////////////////////////////////////
    //                     EXTERNAL INTERACTIVE FUNCTIONS                    //
    ///////////////////////////////////////////////////////////////////////////

    /// @inheritdoc IHubPortal
    function sendMTokenIndex(uint256 destinationChainId_, address refundAddress_) external payable returns (bytes32 messageId_) {
        uint128 index_ = _currentIndex();
        bytes memory payload_ = PayloadEncoder.encodeIndex(index_);

        messageId_ = _sendMessage(destinationChainId_, PayloadType.Index, refundAddress_, payload_);

        emit MTokenIndexSent(messageId_, index_);
    }

    /// @inheritdoc IHubPortal
    function sendRegistrarKey(
        uint256 destinationChainId_,
        bytes32 key_,
        address refundAddress_
    ) external payable returns (bytes32 messageId_) {
        bytes32 value_ = IRegistrarLike(registrar).get(key_);
        bytes memory payload_ = PayloadEncoder.encodeKey(key_, value_);

        messageId_ = _sendMessage(destinationChainId_, PayloadType.Key, refundAddress_, payload_);

        emit RegistrarKeySent(messageId_, key_, value_);
    }

    /// @inheritdoc IHubPortal
    function sendRegistrarListStatus(
        uint256 destinationChainId_,
        bytes32 listName_,
        address account_,
        address refundAddress_
    ) external payable returns (bytes32 messageId_) {
        bool status_ = IRegistrarLike(registrar).listContains(listName_, account_);
        bytes memory payload_ = PayloadEncoder.encodeListUpdate(listName_, account_, status_);

        messageId_ = _sendMessage(destinationChainId_, PayloadType.List, refundAddress_, payload_);

        emit RegistrarListStatusSent(messageId_, listName_, account_, status_);
    }

    /// @inheritdoc IHubPortal
    function enableEarning() external {
        if (_isEarningEnabled()) revert EarningIsEnabled();
        if (wasEarningEnabled) revert EarningCannotBeReenabled();

        wasEarningEnabled = true;

        IMTokenLike(mToken).startEarning();

        emit EarningEnabled(IMTokenLike(mToken).currentIndex());
    }

    /// @inheritdoc IHubPortal
    function disableEarning() external {
        if (!_isEarningEnabled()) revert EarningIsDisabled();

        uint128 currentMIndex_ = IMTokenLike(mToken).currentIndex();
        disableEarningIndex = currentMIndex_;

        IMTokenLike(mToken).stopEarning(address(this));

        emit EarningDisabled(currentMIndex_);
    }

    ///////////////////////////////////////////////////////////////////////////
    //                INTERNAL/PRIVATE INTERACTIVE FUNCTIONS                 //
    ///////////////////////////////////////////////////////////////////////////

    /**
     * @dev   Updates principal amount bridged to the destination chain.
     * @param destinationChainId_ The EVM id of the destination chain.
     * @param amount_             The amount of M Token to transfer.
     */
    function _burnOrLock(uint256 destinationChainId_, uint256 amount_) internal override {
        bridgedPrincipal[destinationChainId_] += IndexingMath.getPrincipalAmountRoundedDown(uint240(amount_), _currentIndex());
    }

    /**
     * @dev   Unlocks M tokens to `recipient_`.
     * @param sourceChainId_ The EVM id of the source chain.
     * @param recipient_     The account to unlock/transfer M tokens to.
     * @param amount_        The amount of M Token to unlock to the recipient.
     */
    function _mintOrUnlock(uint256 sourceChainId_, address recipient_, uint256 amount_, uint128) internal override {
        uint256 totalBridgedPrincipal = bridgedPrincipal[sourceChainId_];
        uint256 principalAmount = IndexingMath.getPrincipalAmountRoundedDown(uint240(amount_), _currentIndex());

        // Prevents unlocking more than was bridged to the Spoke
        if (principalAmount > totalBridgedPrincipal) revert InsufficientBridgedBalance();

        unchecked {
            bridgedPrincipal[sourceChainId_] = totalBridgedPrincipal - principalAmount;
        }

        if (recipient_ != address(this)) {
            IERC20(mToken).transfer(recipient_, amount_);
        }
    }

    ///////////////////////////////////////////////////////////////////////////
    //                 INTERNAL/PRIVATE VIEW/PURE FUNCTIONS                  //
    ///////////////////////////////////////////////////////////////////////////

    /// @dev If earning is enabled returns the current M token index,
    ///      otherwise, returns the index at the time when earning was disabled.
    function _currentIndex() internal view override returns (uint128) {
        return _isEarningEnabled() ? IMTokenLike(mToken).currentIndex() : disableEarningIndex;
    }

    /// @dev Returns whether earning was enabled for HubPortal or not.
    function _isEarningEnabled() internal view returns (bool) {
        return wasEarningEnabled && disableEarningIndex == 0;
    }
}
