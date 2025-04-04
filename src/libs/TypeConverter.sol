// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.26;

library TypeConverter {
    error Uint64Overflow();

    function toBytes32(address address_) internal pure returns (bytes32) {
        return bytes32(uint256(uint160(address_)));
    }

    function toAddress(bytes32 addressBytes32_) internal pure returns (address) {
        return address(uint160(uint256(addressBytes32_)));
    }

    function toUint64(uint256 value_) internal pure returns (uint64) {
        if (value_ > type(uint64).max) {
            revert Uint64Overflow();
        }
        return uint64(value_);
    }
}
