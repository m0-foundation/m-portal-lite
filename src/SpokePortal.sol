// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.26;

import { UIntMath } from "../lib/common/src/libs/UIntMath.sol";

import { ISpokeMTokenLike } from "./interfaces/ISpokeMTokenLike.sol";
import { IRegistrarLike } from "./interfaces/IRegistrarLike.sol";
import { ISpokePortal } from "./interfaces/ISpokePortal.sol";

import { Portal } from "./Portal.sol";
import { PayloadType, PayloadEncoder } from "./libs/PayloadEncoder.sol";

/**
 * @title  SpokePortal
 * @author M^0 Labs
 * @notice Deployed on Spoke chains and responsible for sending and receiving M tokens
 *         as well as updating M index and Registrar keys.
 * @dev    Tokens are bridged using mint-burn mechanism.
 */
contract SpokePortal is Portal, ISpokePortal {
    using PayloadEncoder for bytes;

    constructor(
        address mToken_,
        address remoteMToken_,
        address registrar_,
        address bridge_,
        address initialOwner_,
        address initialPauser_
    ) Portal(mToken_, remoteMToken_, registrar_, bridge_, initialOwner_, initialPauser_) { }

    ///////////////////////////////////////////////////////////////////////////
    //                INTERNAL/PRIVATE INTERACTIVE FUNCTIONS                 //
    ///////////////////////////////////////////////////////////////////////////

    function _receiveCustomPayload(PayloadType payloadType_, bytes memory payload_) internal override {
        if (payloadType_ == PayloadType.Index) {
            _updateMTokenIndex(payload_);
        } else if (payloadType_ == PayloadType.Key) {
            _setRegistrarKey(payload_);
        } else if (payloadType_ == PayloadType.List) {
            _updateRegistrarList(payload_);
        }
    }

    /// @notice Updates M Token index to the index received from the remote chain.
    function _updateMTokenIndex(bytes memory payload_) private {
        uint128 index_ = payload_.decodeIndex();

        emit MTokenIndexReceived(index_);

        if (index_ > _currentIndex()) {
            ISpokeMTokenLike(mToken).updateIndex(index_);
        }
    }

    /// @notice Sets a Registrar key received from the Hub chain.
    function _setRegistrarKey(bytes memory payload_) private {
        (bytes32 key_, bytes32 value_) = payload_.decodeKey();

        emit RegistrarKeyReceived(key_, value_);

        IRegistrarLike(registrar).setKey(key_, value_);
    }

    /// @notice Adds or removes an account from the Registrar List based on the message from the Hub chain.
    function _updateRegistrarList(bytes memory payload_) private {
        (bytes32 listName_, address account_, bool add_) = payload_.decodeListUpdate();

        emit RegistrarListStatusReceived(listName_, account_, add_);

        if (add_) {
            IRegistrarLike(registrar).addToList(listName_, account_);
        } else {
            IRegistrarLike(registrar).removeFromList(listName_, account_);
        }
    }

    /**
     * @dev Mints M Token to the `recipient_`.
     * @param recipient_ The account to mint M tokens to.
     * @param amount_    The amount of M Token to mint to the recipient.
     * @param index_     The index from the source chain.
     */
    function _mintOrUnlock(address recipient_, uint256 amount_, uint128 index_) internal override {
        // Update M token index only if the index received from the remote chain is bigger
        if (index_ > _currentIndex()) {
            ISpokeMTokenLike(mToken).mint(recipient_, amount_, index_);
        } else {
            ISpokeMTokenLike(mToken).mint(recipient_, amount_);
        }
    }

    /**
     * @dev Burns M Token.
     * @param amount_ The amount of M Token to burn from the SpokePortal.
     */
    function _burnOrLock(uint256 amount_) internal override {
        ISpokeMTokenLike(mToken).burn(amount_);
    }

    ///////////////////////////////////////////////////////////////////////////
    //                 INTERNAL/PRIVATE VIEW/PURE FUNCTIONS                  //
    ///////////////////////////////////////////////////////////////////////////

    /// @dev Returns the current M token index used by the Spoke Portal.
    function _currentIndex() internal view override returns (uint128) {
        return ISpokeMTokenLike(mToken).currentIndex();
    }
}
