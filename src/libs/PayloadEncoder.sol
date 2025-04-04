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

library PayloadEncoder {
    using BytesParser for bytes;
    using TypeConverter for *;

    uint256 internal constant PAYLOAD_TYPE_LENGTH = 8;

    error InvalidPayloadLength(uint256 length);

    function getPayloadType(bytes memory payload_) internal pure returns (PayloadType payloadType_) {
        if (payload_.length < PAYLOAD_TYPE_LENGTH) revert InvalidPayloadLength(payload_.length);

        uint8 type_;
        (type_,) = payload_.asUint8Unchecked(0);
        payloadType_ = PayloadType(type_);
    }

    function encodeTokenTransfer(uint256 amount_, bytes32 destinationToken_, bytes32 recipient_, uint128 index_)
        internal
        pure
        returns (bytes memory encoded_)
    {
        encoded_ =
            abi.encodePacked(PayloadType.Token, amount_.toUint64(), destinationToken_, recipient_, index_.toUint64());
    }

    function decodeTokenTransfer(bytes memory payload_)
        internal
        pure
        returns (uint256 amount_, address destinationToken_, address recipient_, uint128 index_)
    {
        uint256 offset_ = PAYLOAD_TYPE_LENGTH;
        bytes32 tokenBytes32_;
        bytes32 recipientBytes32_;

        (amount_, offset_) = payload_.asUint64Unchecked(offset_);
        (tokenBytes32_, offset_) = payload_.asBytes32Unchecked(offset_);
        (recipientBytes32_, offset_) = payload_.asBytes32Unchecked(offset_);
        (index_, offset_) = payload_.asUint64Unchecked(offset_);

        destinationToken_ = tokenBytes32_.toAddress();
        recipient_ = recipientBytes32_.toAddress();

        payload_.checkLength(offset_);
    }

    function encodeIndex(uint128 index_) internal pure returns (bytes memory encoded_) {
        encoded_ = abi.encodePacked(PayloadType.Index, index_.toUint64());
    }

    function decodeIndex(bytes memory payload_) internal pure returns (uint128 index_) {
        uint256 offset_ = PAYLOAD_TYPE_LENGTH;

        (index_, offset_) = payload_.asUint64Unchecked(offset_);

        payload_.checkLength(offset_);
    }

    function encodeKey(bytes32 key_, bytes32 value_) internal pure returns (bytes memory encoded_) {
        encoded_ = abi.encodePacked(PayloadType.Key, key_, value_);
    }

    function decodeKey(bytes memory payload_) internal pure returns (bytes32 key_, bytes32 value_) {
        uint256 offset_ = PAYLOAD_TYPE_LENGTH;

        (key_, offset_) = payload_.asBytes32Unchecked(offset_);
        (value_, offset_) = payload_.asBytes32Unchecked(offset_);

        payload_.checkLength(offset_);
    }

    function encodeListUpdate(bytes32 listName_, address account_, bool add_)
        internal
        pure
        returns (bytes memory encoded_)
    {
        encoded_ = abi.encodePacked(PayloadType.List, listName_, account_, add_);
    }

    function decodeListUpdate(bytes memory payload_)
        internal
        pure
        returns (bytes32 listName_, address account_, bool add_)
    {
        uint256 offset_ = PAYLOAD_TYPE_LENGTH;

        (listName_, offset_) = payload_.asBytes32Unchecked(offset_);
        (account_, offset_) = payload_.asAddressUnchecked(offset_);
        (add_, offset_) = payload_.asBoolUnchecked(offset_);

        payload_.checkLength(offset_);
    }
}
