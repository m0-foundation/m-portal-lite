// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.26;

import { BytesParser } from "./BytesParser.sol";
import { TypeConverter } from "./TypeConverter.sol";

enum PayloadType {
    Token,
    Index,
    Key,
    List
}

/**
 * @title  PayloadEncoder
 * @author M^0 Labs
 * @notice Encodes and decodes cross-chain message payloads.
 */
library PayloadEncoder {
    using BytesParser for bytes;
    using TypeConverter for *;

    uint256 internal constant PAYLOAD_TYPE_LENGTH = 1;

    /// @dev PayloadType.Token = 0, PayloadType.Index = 1, PayloadType.Key = 2, PayloadType.List = 3
    uint256 internal constant MAX_PAYLOAD_TYPE = 3;

    error InvalidPayloadLength(uint256 length);
    error InvalidPayloadType(uint8 value);

    /**
     * @notice Decodes the payload type from the payload.
     * @param payload_      The payload to decode.
     * @return payloadType_ The decoded payload type.
     */
    function getPayloadType(bytes memory payload_) internal pure returns (PayloadType payloadType_) {
        if (payload_.length < PAYLOAD_TYPE_LENGTH) revert InvalidPayloadLength(payload_.length);

        uint8 type_;
        (type_,) = payload_.asUint8Unchecked(0);

        if (type_ > MAX_PAYLOAD_TYPE) revert InvalidPayloadType(type_);
        payloadType_ = PayloadType(type_);
    }

    /**
     * @notice Encodes a token transfer payload.
     * @dev    Encoded values are packed using `abi.encodePacked`.
     * @param amount_           The amount of tokens to transfer.
     * @param destinationToken_ The address of the destination token.
     * @param sender_           The address of the sender.
     * @param recipient_        The address of the recipient.
     * @param index_            The M token index.
     * @return encoded_         The encoded payload.
     */
    function encodeTokenTransfer(
        uint256 amount_,
        address destinationToken_,
        address sender_,
        address recipient_,
        uint128 index_
    ) internal pure returns (bytes memory encoded_) {
        encoded_ = abi.encodePacked(PayloadType.Token, amount_, destinationToken_, sender_, recipient_, index_);
    }

    /**
     * @notice Decodes a token transfer payload.
     * @param payload_           The payload to decode.
     * @return amount_           The amount of tokens to transfer.
     * @return destinationToken_ The address of the destination token.
     * @return sender_           The address of the sender.
     * @return recipient_        The address of the recipient.
     * @return index_            The M token index.
     */
    function decodeTokenTransfer(bytes memory payload_)
        internal
        pure
        returns (uint256 amount_, address destinationToken_, address sender_, address recipient_, uint128 index_)
    {
        uint256 offset_ = PAYLOAD_TYPE_LENGTH;

        (amount_, offset_) = payload_.asUint256Unchecked(offset_);
        (destinationToken_, offset_) = payload_.asAddressUnchecked(offset_);
        (sender_, offset_) = payload_.asAddressUnchecked(offset_);
        (recipient_, offset_) = payload_.asAddressUnchecked(offset_);
        (index_, offset_) = payload_.asUint128Unchecked(offset_);

        payload_.checkLength(offset_);
    }

    /**
     * @notice Encodes M token index payload.
     * @param index_    The M token index.
     * @return encoded_ The encoded payload.
     */
    function encodeIndex(uint128 index_) internal pure returns (bytes memory encoded_) {
        encoded_ = abi.encodePacked(PayloadType.Index, index_);
    }

    /**
     * @notice Decodes M token index payload.
     * @param payload_ The payload to decode.
     * @return index_  The M token index.
     */
    function decodeIndex(bytes memory payload_) internal pure returns (uint128 index_) {
        uint256 offset_ = PAYLOAD_TYPE_LENGTH;

        (index_, offset_) = payload_.asUint128Unchecked(offset_);

        payload_.checkLength(offset_);
    }

    /**
     * @notice Encodes a Registrar key-value pair payload.
     * @param key_      The key.
     * @param value_    The value.
     * @return encoded_ The encoded payload.
     */
    function encodeKey(bytes32 key_, bytes32 value_) internal pure returns (bytes memory encoded_) {
        encoded_ = abi.encodePacked(PayloadType.Key, key_, value_);
    }

    /**
     * @notice Decodes a Registrar key-value pair payload.
     * @param payload_ The payload to decode.
     * @return key_    The key.
     * @return value_  The value.
     */
    function decodeKey(bytes memory payload_) internal pure returns (bytes32 key_, bytes32 value_) {
        uint256 offset_ = PAYLOAD_TYPE_LENGTH;

        (key_, offset_) = payload_.asBytes32Unchecked(offset_);
        (value_, offset_) = payload_.asBytes32Unchecked(offset_);

        payload_.checkLength(offset_);
    }

    /**
     * @notice Encodes a list update payload.
     * @param listName_ The name of the list.
     * @param account_  The address of the account.
     * @param add_      Indicates whether to add or remove the account from the list.
     * @return encoded_ The encoded payload.
     */
    function encodeListUpdate(bytes32 listName_, address account_, bool add_) internal pure returns (bytes memory encoded_) {
        encoded_ = abi.encodePacked(PayloadType.List, listName_, account_, add_);
    }

    /**
     * @notice Decodes a list update payload.
     * @param payload_   The payload to decode.
     * @return listName_ The name of the list.
     * @return account_  The address of the account.
     * @return add_      Indicates whether the account was added or removed from the list.
     */
    function decodeListUpdate(bytes memory payload_) internal pure returns (bytes32 listName_, address account_, bool add_) {
        uint256 offset_ = PAYLOAD_TYPE_LENGTH;

        (listName_, offset_) = payload_.asBytes32Unchecked(offset_);
        (account_, offset_) = payload_.asAddressUnchecked(offset_);
        (add_, offset_) = payload_.asBoolUnchecked(offset_);

        payload_.checkLength(offset_);
    }
}
