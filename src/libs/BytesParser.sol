// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.26;

/**
 * @title  BytesParser
 * @author Wormhole Labs
 * @notice Parses tightly packed data.
 * @dev    Modified from
 *         https://github.com/wormhole-foundation/wormhole-solidity-sdk/blob/main/src/libraries/BytesParsing.sol
 */
library BytesParser {
    error LengthMismatch(uint256 encodedLength, uint256 expectedLength);
    error InvalidBool(uint8 value);

    function checkLength(bytes memory encoded_, uint256 expected_) internal pure {
        if (encoded_.length != expected_) revert LengthMismatch(encoded_.length, expected_);
    }

    function asUint8Unchecked(bytes memory encoded_, uint256 offset_) internal pure returns (uint8 value_, uint256 nextOffset_) {
        assembly ("memory-safe") {
            nextOffset_ := add(offset_, 1)
            value_ := mload(add(encoded_, nextOffset_))
        }
    }

    function asBoolUnchecked(bytes memory encoded_, uint256 offset_) internal pure returns (bool value_, uint256 nextOffset_) {
        uint8 uint8Value_;
        (uint8Value_, nextOffset_) = asUint8Unchecked(encoded_, offset_);

        if (uint8Value_ & 0xfe != 0) revert InvalidBool(uint8Value_);

        uint256 cleanedValue_ = uint256(uint8Value_);
        // skip 2x iszero opcode
        assembly ("memory-safe") {
            value_ := cleanedValue_
        }
    }

    function asUint256Unchecked(
        bytes memory encoded_,
        uint256 offset_
    ) internal pure returns (uint256 value_, uint256 nextOffset_) {
        assembly ("memory-safe") {
            nextOffset_ := add(offset_, 32)
            value_ := mload(add(encoded_, nextOffset_))
        }
    }

    function asBytes32Unchecked(
        bytes memory encoded_,
        uint256 offset_
    ) internal pure returns (bytes32 value_, uint256 nextOffset_) {
        uint256 uint256Value_;
        (uint256Value_, nextOffset_) = asUint256Unchecked(encoded_, offset_);
        value_ = bytes32(uint256Value_);
    }

    function asUint128Unchecked(
        bytes memory encoded_,
        uint256 offset_
    ) internal pure returns (uint128 value_, uint256 nextOffset_) {
        assembly ("memory-safe") {
            nextOffset_ := add(offset_, 16)
            value_ := mload(add(encoded_, nextOffset_))
        }
    }

    function asAddressUnchecked(
        bytes memory encoded_,
        uint256 offset_
    ) internal pure returns (address value_, uint256 nextOffset_) {
        assembly ("memory-safe") {
            nextOffset_ := add(offset_, 20)
            value_ := mload(add(encoded_, nextOffset_))
        }
    }
}
