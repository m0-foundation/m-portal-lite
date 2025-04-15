// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.26;

import { Test } from "forge-std/Test.sol";

import { BytesParser } from "../../../src/libs/BytesParser.sol";

contract BytesParserTest is Test {
    using BytesParser for bytes;

    function test_asUint8Unchecked() external {
        bytes memory data_ = hex"0203";

        (uint8 value_, uint256 nextOffset_) = data_.asUint8Unchecked(0);
        assertEq(value_, 2);
        assertEq(nextOffset_, 1);

        (value_, nextOffset_) = data_.asUint8Unchecked(nextOffset_);
        assertEq(value_, 3);
        assertEq(nextOffset_, 2);
    }

    function testFuzz_asUint8Unchecked(uint8 inputValue_) external {
        bytes memory data_ = abi.encodePacked(uint8(inputValue_));

        (uint8 value_, uint256 nextOffset_) = data_.asUint8Unchecked(0);
        assertEq(value_, inputValue_);
        assertEq(nextOffset_, 1);
    }

    function test_asBoolUnchecked() external {
        bytes memory trueData_ = abi.encodePacked(true);
        bytes memory falseData_ = abi.encodePacked(false);

        (bool trueValue_,) = trueData_.asBoolUnchecked(0);
        (bool falseValue_,) = falseData_.asBoolUnchecked(0);

        assertTrue(trueValue_);
        assertFalse(falseValue_);
    }

    /// forge-config: default.allow_internal_expect_revert = true
    function test_asBoolUnchecked_invalidValue() external {
        bytes memory invalidData_ = abi.encodePacked(uint8(2));

        vm.expectRevert(abi.encodeWithSelector(BytesParser.InvalidBool.selector, 0x02));
        invalidData_.asBoolUnchecked(0);
    }

    function test_asUint256Unchecked() external {
        bytes memory data_ = abi.encodePacked(uint256(1));

        (uint256 value_, uint256 nextOffset_) = data_.asUint256Unchecked(0);
        assertEq(value_, 1);
        assertEq(nextOffset_, 32);
    }

    function testFuzz_asUint256Unchecked(uint256 inputValue_) external {
        bytes memory data_ = abi.encodePacked(inputValue_);

        (uint256 value_, uint256 nextOffset_) = data_.asUint256Unchecked(0);
        assertEq(value_, inputValue_);
        assertEq(nextOffset_, 32);
    }

    function test_asUint128Unchecked() external {
        bytes memory data_ = abi.encodePacked(uint128(1));

        (uint128 value_, uint256 nextOffset_) = data_.asUint128Unchecked(0);
        assertEq(value_, 1);
        assertEq(nextOffset_, 16);
    }

    function testFuzz_asUint128Unchecked(uint128 inputValue_) external {
        bytes memory data_ = abi.encodePacked(inputValue_);

        (uint128 value_, uint256 nextOffset_) = data_.asUint128Unchecked(0);
        assertEq(value_, inputValue_);
        assertEq(nextOffset_, 16);
    }

    function test_asBytes32Unchecked() external {
        bytes memory data_ = abi.encodePacked(bytes32(uint256(1)));

        (bytes32 value_, uint256 nextOffset_) = data_.asBytes32Unchecked(0);
        assertEq(value_, bytes32(uint256(1)));
        assertEq(nextOffset_, 32);
    }

    function testFuzz_asBytes32Unchecked(bytes32 inputValue_) external {
        bytes memory data_ = abi.encodePacked(inputValue_);

        (bytes32 value_, uint256 nextOffset_) = data_.asBytes32Unchecked(0);
        assertEq(value_, inputValue_);
        assertEq(nextOffset_, 32);
    }

    function test_asAddressUnchecked() external {
        bytes memory data_ = abi.encodePacked(address(1));

        (address value_, uint256 nextOffset_) = data_.asAddressUnchecked(0);
        assertEq(value_, address(1));
        assertEq(nextOffset_, 20);
    }

    function testFuzz_asAddressUnchecked(address inputValue_) external {
        bytes memory data_ = abi.encodePacked(inputValue_);

        (address value_, uint256 nextOffset_) = data_.asAddressUnchecked(0);
        assertEq(value_, inputValue_);
        assertEq(nextOffset_, 20);
    }
}
