// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.26;

import { IERC20 } from "../lib/common/src/interfaces/IERC20.sol";
import { IndexingMath } from "../lib/common/src/libs/IndexingMath.sol";

import { IBridge } from "./interfaces/IBridge.sol";
import { IMTokenLike } from "./interfaces/IMTokenLike.sol";
import { IRegistrarLike } from "./interfaces/IRegistrarLike.sol";
import { IPortal } from "./interfaces/IPortal.sol";
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
    address public constant MAIN_PORTAL = 0xD925C84b55E4e44a53749fF5F2a5A13F63D128fd;
    address public constant MIGRATOR = 0xb7A9B5f301eF3bAD36C2b4964E82931Dd7fb989C;

    /// @inheritdoc IHubPortal
    bool public wasEarningEnabled;

    /// @inheritdoc IHubPortal
    uint128 public disableEarningIndex;

    /// @inheritdoc IHubPortal
    mapping(uint256 spokeChainId => uint256 principal) public bridgedPrincipal;

    /// @inheritdoc IHubPortal
    mapping(uint256 spokeChainId => bool enabled) public crossSpokeConnectionEnabled; 

    /**
     * @notice Constructs HubPortal Implementation contract
     * @dev    Sets immutable storage.
     * @param  mToken_    The address of M token.
     * @param  registrar_ The address of Registrar.
     * @param  swapFacility_ The address of Swap Facility.
     */
    constructor(address mToken_, address registrar_, address swapFacility_) Portal(mToken_, registrar_, swapFacility_) { }

    /// @inheritdoc IPortal
    function initialize(address bridge_, address initialOwner_, address initialPauser_) external initializer {
        _initialize(bridge_, initialOwner_, initialPauser_);
        disableEarningIndex = IndexingMath.EXP_SCALED_ONE;
    }

    ///////////////////////////////////////////////////////////////////////////
    //                     EXTERNAL VIEW/PURE FUNCTIONS                      //
    ///////////////////////////////////////////////////////////////////////////

    /// @inheritdoc IHubPortal
    function quoteSendIndex(uint256 destinationChainId_) external view returns (uint256 fee) {
        bytes memory payload_ = PayloadEncoder.encodeIndex(_currentIndex());
        return IBridge(bridge).quote(destinationChainId_, payloadGasLimit[destinationChainId_][PayloadType.Index], payload_);
    }

    /// @inheritdoc IHubPortal
    function quoteSendRegistrarKey(uint256 destinationChainId_, bytes32 key_) external view returns (uint256 fee_) {
        bytes32 value_ = IRegistrarLike(registrar).get(key_);
        bytes memory payload_ = PayloadEncoder.encodeKey(key_, value_);
        return IBridge(bridge).quote(destinationChainId_, payloadGasLimit[destinationChainId_][PayloadType.Key], payload_);
    }

    /// @inheritdoc IHubPortal
    function quoteSendRegistrarListStatus(
        uint256 destinationChainId_,
        bytes32 listName_,
        address account_
    ) external view returns (uint256 fee_) {
        bool status_ = IRegistrarLike(registrar).listContains(listName_, account_);
        bytes memory payload_ = PayloadEncoder.encodeListUpdate(listName_, account_, status_);
        return IBridge(bridge).quote(destinationChainId_, payloadGasLimit[destinationChainId_][PayloadType.List], payload_);
    }

    ///////////////////////////////////////////////////////////////////////////
    //                     EXTERNAL INTERACTIVE FUNCTIONS                    //
    ///////////////////////////////////////////////////////////////////////////

    /// @inheritdoc IHubPortal
    function sendMTokenIndex(uint256 destinationChainId_, address refundAddress_) external payable returns (bytes32 messageId_) {
        _revertIfZeroRefundAddress(refundAddress_);

        uint128 index_ = _currentIndex();
        bytes memory payload_ = PayloadEncoder.encodeIndex(index_);

        messageId_ = _sendMessage(destinationChainId_, PayloadType.Index, refundAddress_, payload_);

        emit MTokenIndexSent(destinationChainId_, messageId_, index_);
    }

    /// @inheritdoc IHubPortal
    function sendRegistrarKey(
        uint256 destinationChainId_,
        bytes32 key_,
        address refundAddress_
    ) external payable returns (bytes32 messageId_) {
        _revertIfZeroRefundAddress(refundAddress_);

        bytes32 value_ = IRegistrarLike(registrar).get(key_);
        bytes memory payload_ = PayloadEncoder.encodeKey(key_, value_);

        messageId_ = _sendMessage(destinationChainId_, PayloadType.Key, refundAddress_, payload_);

        emit RegistrarKeySent(destinationChainId_, messageId_, key_, value_);
    }

    /// @inheritdoc IHubPortal
    function sendRegistrarListStatus(
        uint256 destinationChainId_,
        bytes32 listName_,
        address account_,
        address refundAddress_
    ) external payable returns (bytes32 messageId_) {
        _revertIfZeroRefundAddress(refundAddress_);

        bool status_ = IRegistrarLike(registrar).listContains(listName_, account_);
        bytes memory payload_ = PayloadEncoder.encodeListUpdate(listName_, account_, status_);

        messageId_ = _sendMessage(destinationChainId_, PayloadType.List, refundAddress_, payload_);

        emit RegistrarListStatusSent(destinationChainId_, messageId_, listName_, account_, status_);
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

    /// @inheritdoc IHubPortal
    function migrateM(uint256 amount) external whenPaused {
        if (msg.sender != MIGRATOR) revert Unauthorized(msg.sender);

        uint256 balance = IERC20(mToken).balanceOf(address(this));
        if (amount > balance) revert InsufficientBalance(balance, amount);

        IERC20(mToken).transfer(MAIN_PORTAL, amount);
    }

    ///////////////////////////////////////////////////////////////////////////
    //                     OWNER INTERACTIVE FUNCTIONS                       //
    ///////////////////////////////////////////////////////////////////////////

    /// @inheritdoc IHubPortal
    function enableCrossSpokeConnection(uint256 spokeChainId_) external onlyOwner {
        if (crossSpokeConnectionEnabled[spokeChainId_]) return;
        
        crossSpokeConnectionEnabled[spokeChainId_] = true;
        uint256 bridgedPrincipal_ = bridgedPrincipal[spokeChainId_];

        // NOTE: Reset bridged principal, as tracking it 
        //       for connected Spokes isn't possible on-chain.
        bridgedPrincipal[spokeChainId_] = 0;

        emit CrossSpokeConnectionEnabled(spokeChainId_, bridgedPrincipal_);
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
        // Only track bridged principal for isolated Spokes
        if (crossSpokeConnectionEnabled[destinationChainId_]) return;

        // Won't overflow since `getPrincipalAmountRoundedDown` returns uint112
        unchecked {
            bridgedPrincipal[destinationChainId_] += IndexingMath.getPrincipalAmountRoundedDown(uint240(amount_), _currentIndex());
        }
    }

    /**
     * @dev   Unlocks M tokens to `recipient_`.
     * @param sourceChainId_ The EVM id of the source chain.
     * @param recipient_     The account to unlock/transfer M tokens to.
     * @param amount_        The amount of M Token to unlock to the recipient.
     */
    function _mintOrUnlock(uint256 sourceChainId_, address recipient_, uint256 amount_, uint128) internal override {
        // Only track bridged principal for isolated Spokes
        if (!crossSpokeConnectionEnabled[sourceChainId_]) {
            _decreaseBridgedPrincipal(sourceChainId_, amount_);
        }

        if (recipient_ != address(this)) {
            IERC20(mToken).transfer(recipient_, amount_);
        }
    }

    /// @dev Decreases the principal amount bridged when receiving transfer from a Spoke chain.
    ///      Reverts when trying to unlock more than was bridged to the Spoke.
    function _decreaseBridgedPrincipal(uint256 spokeChainId_, uint256 amount_) private {
        uint256 totalBridgedPrincipal = bridgedPrincipal[spokeChainId_];
        uint256 principalAmount = IndexingMath.getPrincipalAmountRoundedDown(uint240(amount_), _currentIndex());

        // Prevents unlocking more than was bridged to the Spoke
        if (principalAmount > totalBridgedPrincipal) revert InsufficientBridgedBalance();

        unchecked {
            bridgedPrincipal[spokeChainId_] = totalBridgedPrincipal - principalAmount;
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
        return wasEarningEnabled && disableEarningIndex == IndexingMath.EXP_SCALED_ONE;
    }
}
