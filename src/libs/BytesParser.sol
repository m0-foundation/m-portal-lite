// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.26;

library BytesParser {
    error LengthMismatch(uint256 encodedLength, uint256 expectedLength);
    error InvalidBoolVal(uint8 value);

    function checkLength(bytes memory encoded, uint256 expected) internal pure {
        if (encoded.length != expected) {
            revert LengthMismatch(encoded.length, expected);
        }
    }

    function asUint8Unchecked(bytes memory encoded, uint256 offset)
        internal
        pure
        returns (uint8 value, uint256 nextOffset)
    {
        assembly ("memory-safe") {
            nextOffset := add(offset, 1)
            value := mload(add(encoded, nextOffset))
        }
        return (value, nextOffset);
    }

    function asBoolUnchecked(bytes memory encoded, uint256 offset)
        internal
        pure
        returns (bool value, uint256 nextOffset)
    {
        uint8 uint8Value;
        (uint8Value, nextOffset) = asUint8Unchecked(encoded, offset);

        if (uint8Value & 0xfe != 0) {
            revert InvalidBoolVal(uint8Value);
        }

        uint256 cleanedValue = uint256(uint8Value);
        // skip 2x iszero opcode
        assembly ("memory-safe") {
            value := cleanedValue
        }
        return (value, nextOffset);
    }

    function asBytes32Unchecked(bytes memory encoded, uint256 offset)
        internal
        pure
        returns (bytes32 value, uint256 nextOffset)
    {
        assembly ("memory-safe") {
            nextOffset := add(offset, 32)
            value := mload(add(encoded, nextOffset))
        }
        return (value, nextOffset);
    }

    function asUint64Unchecked(bytes memory encoded, uint256 offset)
        internal
        pure
        returns (uint64 value, uint256 nextOffset)
    {
        assembly ("memory-safe") {
            nextOffset := add(offset, 8)
            value := mload(add(encoded, nextOffset))
        }
        return (value, nextOffset);
    }

    function asAddressUnchecked(bytes memory encoded, uint256 offset)
        internal
        pure
        returns (address value, uint256 nextOffset)
    {
        assembly ("memory-safe") {
            nextOffset := add(offset, 20)
            value := mload(add(encoded, nextOffset))
        }
        return (value, nextOffset);
    }
}
