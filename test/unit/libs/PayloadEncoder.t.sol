// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.26;

import { Test } from "forge-std/Test.sol";
import { PayloadType, PayloadEncoder } from "../../../src/libs/PayloadEncoder.sol";

contract PayloadEncoderTest is Test {
    using PayloadEncoder for bytes;

    /// forge-config: default.allow_internal_expect_revert = true
    function test_getPayloadType_invalidPayloadLength() external {
        bytes memory payload_ = "";

        vm.expectRevert(abi.encodeWithSelector(PayloadEncoder.InvalidPayloadLength.selector, payload_.length));
        PayloadEncoder.getPayloadType(payload_);
    }

    /// forge-config: default.allow_internal_expect_revert = true
    function test_getPayloadType_invalidPayloadType() external {
        bytes memory payload_ = abi.encodePacked(uint8(4));

        vm.expectRevert(abi.encodeWithSelector(PayloadEncoder.InvalidPayloadType.selector, 4));
        PayloadEncoder.getPayloadType(payload_);
    }

    function test_getPayloadType() external {
        bytes memory payload_ = abi.encodePacked(PayloadType.Token);
        assertEq(uint8(PayloadEncoder.getPayloadType(payload_)), uint8(PayloadType.Token));

        payload_ = abi.encodePacked(PayloadType.Index);
        assertEq(uint8(PayloadEncoder.getPayloadType(payload_)), uint8(PayloadType.Index));

        payload_ = abi.encodePacked(PayloadType.Key);
        assertEq(uint8(PayloadEncoder.getPayloadType(payload_)), uint8(PayloadType.Key));

        payload_ = abi.encodePacked(PayloadType.List);
        assertEq(uint8(PayloadEncoder.getPayloadType(payload_)), uint8(PayloadType.List));
    }

    function test_encodeTokenTransfer() external {
        uint256 amount_ = 1e6;
        address token_ = makeAddr("destinationToken");
        address recipient_ = makeAddr("recipient");
        uint128 index_ = 1.2e12;

        bytes memory payload_ = PayloadEncoder.encodeTokenTransfer(amount_, token_, recipient_, index_);
        assertEq(payload_, abi.encodePacked(PayloadType.Token, amount_, token_, recipient_, index_));
    }

    function testFuzz_encodeTokenTransfer(
        uint256 amount_,
        address token_,
        address recipient_,
        uint128 index_
    ) external {
        bytes memory payload_ = PayloadEncoder.encodeTokenTransfer(amount_, token_, recipient_, index_);
        assertEq(payload_, abi.encodePacked(PayloadType.Token, amount_, token_, recipient_, index_));
    }

    function test_decodeTokenTransfer() external {
        uint256 amount_ = 1e6;
        address token_ = makeAddr("destinationToken");
        address recipient_ = makeAddr("recipient");
        uint128 index_ = 1.2e12;

        bytes memory payload_ = PayloadEncoder.encodeTokenTransfer(amount_, token_, recipient_, index_);

        (uint256 decodedAmount_, address decodedToken_, address decodedRecipient_, uint128 decodedIndex_) =
            PayloadEncoder.decodeTokenTransfer(payload_);

        assertEq(decodedAmount_, amount_);
        assertEq(decodedToken_, token_);
        assertEq(decodedRecipient_, recipient_);
        assertEq(decodedIndex_, index_);
    }

    function testFuzz_decodeTokenTransfer(
        uint256 amount_,
        address token_,
        address recipient_,
        uint128 index_
    ) external {
        bytes memory payload_ = PayloadEncoder.encodeTokenTransfer(amount_, token_, recipient_, index_);
        (uint256 decodedAmount_, address decodedToken_, address decodedRecipient_, uint128 decodedIndex_) =
            PayloadEncoder.decodeTokenTransfer(payload_);

        assertEq(decodedAmount_, amount_);
        assertEq(decodedToken_, token_);
        assertEq(decodedRecipient_, recipient_);
        assertEq(decodedIndex_, index_);
    }

    function test_encodeIndex() external {
        uint128 index_ = 1.2e12;
        bytes memory payload_ = PayloadEncoder.encodeIndex(index_);
        assertEq(payload_, abi.encodePacked(PayloadType.Index, index_));
    }

    function testFuzz_encodeIndex(uint128 index_) external {
        bytes memory payload_ = PayloadEncoder.encodeIndex(index_);
        assertEq(payload_, abi.encodePacked(PayloadType.Index, index_));
    }

    function test_decodeIndex() external {
        uint128 index_ = 1.2e12;
        bytes memory payload_ = PayloadEncoder.encodeIndex(index_);
        (uint128 decodedIndex_) = PayloadEncoder.decodeIndex(payload_);
        assertEq(decodedIndex_, index_);
    }

    function testFuzz_decodeIndex(uint128 index_) external {
        bytes memory payload_ = PayloadEncoder.encodeIndex(index_);
        (uint128 decodedIndex_) = PayloadEncoder.decodeIndex(payload_);
        assertEq(decodedIndex_, index_);
    }

    function test_encodeKey() external {
        bytes32 key_ = "key";
        bytes32 value_ = "value";
        bytes memory payload_ = PayloadEncoder.encodeKey(key_, value_);
        assertEq(payload_, abi.encodePacked(PayloadType.Key, key_, value_));
    }

    function testFuzz_encodeKey(bytes32 key_, bytes32 value_) external {
        bytes memory payload_ = PayloadEncoder.encodeKey(key_, value_);
        assertEq(payload_, abi.encodePacked(PayloadType.Key, key_, value_));
    }

    function test_decodeKey() external {
        bytes32 key_ = "key";
        bytes32 value_ = "value";
        bytes memory payload_ = PayloadEncoder.encodeKey(key_, value_);

        (bytes32 decodedKey_, bytes32 decodedValue_) = PayloadEncoder.decodeKey(payload_);
        assertEq(decodedKey_, key_);
        assertEq(decodedValue_, value_);
    }

    function testFuzz_decodeKey(bytes32 key_, bytes32 value_) external {
        bytes memory payload_ = PayloadEncoder.encodeKey(key_, value_);
        (bytes32 decodedKey_, bytes32 decodedValue_) = PayloadEncoder.decodeKey(payload_);
        assertEq(decodedKey_, key_);
        assertEq(decodedValue_, value_);
    }

    function test_encodeListUpdate() external {
        bytes32 listName_ = "list";
        address account_ = makeAddr("account");
        bool add_ = true;
        bytes memory payload_ = abi.encodePacked(PayloadType.List, listName_, account_, add_);

        assertEq(PayloadEncoder.encodeListUpdate(listName_, account_, add_), payload_);
    }

    function testFuzz_encodeListUpdate(bytes32 listName_, address account_, bool add_) external {
        bytes memory payload_ = PayloadEncoder.encodeListUpdate(listName_, account_, add_);
        assertEq(payload_, abi.encodePacked(PayloadType.List, listName_, account_, add_));
    }

    function test_decodeListUpdate() external {
        bytes32 listName_ = "list";
        address account_ = makeAddr("account");
        bool add_ = true;
        bytes memory payload_ = PayloadEncoder.encodeListUpdate(listName_, account_, add_);
        (bytes32 decodedListName_, address decodedAccount_, bool decodedStatus_) =
            PayloadEncoder.decodeListUpdate(payload_);

        assertEq(decodedListName_, listName_);
        assertEq(decodedAccount_, account_);
        assertEq(decodedStatus_, add_);
    }

    function testFuzz_decodeListUpdate(bytes32 listName_, address account_, bool add_) external {
        bytes memory payload_ = PayloadEncoder.encodeListUpdate(listName_, account_, add_);
        (bytes32 decodedListName_, address decodedAccount_, bool decodedStatus_) =
            PayloadEncoder.decodeListUpdate(payload_);

        assertEq(decodedListName_, listName_);
        assertEq(decodedAccount_, account_);
        assertEq(decodedStatus_, add_);
    }
}
