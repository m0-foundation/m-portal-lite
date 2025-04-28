// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.26;

import { Test } from "../../lib/forge-std/src/Test.sol";
import { Ownable } from "../../lib/openzeppelin/contracts/access/Ownable.sol";
import { Pausable } from "../../lib/openzeppelin/contracts/utils/Pausable.sol";

import { IPortal } from "../../src/interfaces/IPortal.sol";
import { IBridge } from "../../src/interfaces/IBridge.sol";
import { IRegistrarLike } from "../../src/interfaces/IRegistrarLike.sol";
import { IPausableOwnable } from "../../src/interfaces/IPausableOwnable.sol";
import { ISpokePortal } from "../../src/interfaces/ISpokePortal.sol";
import { ISpokeMTokenLike } from "../../src/interfaces/ISpokeMTokenLike.sol";
import { SpokePortal } from "../../src/SpokePortal.sol";
import { PayloadType, PayloadEncoder } from "../../src/libs/PayloadEncoder.sol";

import { MockSpokeMToken } from "../mocks/MockSpokeMToken.sol";
import { MockWrappedMToken } from "../mocks/MockWrappedMToken.sol";
import { MockSpokeRegistrar } from "../mocks/MockSpokeRegistrar.sol";
import { MockBridge } from "../mocks/MockBridge.sol";

contract SpokePortalTest is Test {
    uint256 public constant HUB_CHAIN_ID = 1;
    uint256 public constant SPOKE_CHAIN_ID = 999;

    uint256 public constant TOKEN_TRANSFER_GAS_LIMIT = 250_000;

    SpokePortal public spokePortal;
    MockSpokeMToken public mToken;
    MockWrappedMToken public wrappedMToken;
    MockSpokeRegistrar public registrar;
    MockBridge public bridge;

    address public hubMToken = makeAddr("hubMToken");
    address public hubWrappedMToken = makeAddr("hubWrappedMToken");

    address public owner = makeAddr("owner");
    address public user = makeAddr("user");

    function setUp() external {
        mToken = new MockSpokeMToken();
        wrappedMToken = new MockWrappedMToken(address(mToken));
        registrar = new MockSpokeRegistrar();
        bridge = new MockBridge();
        spokePortal = new SpokePortal(HUB_CHAIN_ID, address(mToken), address(registrar), address(bridge), owner, owner);

        vm.startPrank(owner);

        // Configure
        spokePortal.setDestinationMToken(HUB_CHAIN_ID, hubMToken);

        spokePortal.setSupportedBridgingPath(address(mToken), HUB_CHAIN_ID, hubMToken, true);
        spokePortal.setSupportedBridgingPath(address(mToken), HUB_CHAIN_ID, hubWrappedMToken, true);
        spokePortal.setSupportedBridgingPath(address(wrappedMToken), HUB_CHAIN_ID, hubMToken, true);
        spokePortal.setSupportedBridgingPath(address(wrappedMToken), HUB_CHAIN_ID, hubWrappedMToken, true);

        spokePortal.setPayloadGasLimit(SPOKE_CHAIN_ID, PayloadType.Token, TOKEN_TRANSFER_GAS_LIMIT);
        vm.stopPrank();

        vm.deal(owner, 1 ether);
        vm.deal(user, 1 ether);
    }

    ///////////////////////////////////////////////////////////////////////////
    //                              CONSTRUCTOR                              //
    ///////////////////////////////////////////////////////////////////////////

    function test_constructor_initialState() external {
        assertEq(spokePortal.hubChainId(), HUB_CHAIN_ID);
        assertEq(address(spokePortal.mToken()), address(mToken));
        assertEq(address(spokePortal.registrar()), address(registrar));
        assertEq(address(spokePortal.bridge()), address(bridge));
        assertEq(address(spokePortal.owner()), owner);
        assertEq(address(spokePortal.pauser()), owner);
    }

    function test_constructor_zeroHubChain() external {
        vm.expectRevert(ISpokePortal.ZeroHubChain.selector);
        new SpokePortal(0, address(mToken), address(registrar), address(bridge), owner, owner);
    }

    ///////////////////////////////////////////////////////////////////////////
    //                                transfer                               //
    ///////////////////////////////////////////////////////////////////////////

    function test_transfer_unsupportedDestinationChain() external {
        // Not Hub chain
        uint256 destinationChainId_ = 2;

        vm.expectRevert(abi.encodeWithSelector(ISpokePortal.UnsupportedDestinationChain.selector, destinationChainId_));
        vm.prank(user);
        spokePortal.transfer{ value: 0 }(1000, destinationChainId_, user, user);
    }

    ///////////////////////////////////////////////////////////////////////////
    //                           receiveMessage                              //
    ///////////////////////////////////////////////////////////////////////////

    function test_receiveMessage_index() external {
        uint128 spokeIndex_ = 1_090000008200;
        uint128 hubIndex_ = 1_100000068703;
        bytes memory payload_ = PayloadEncoder.encodeIndex(hubIndex_);
        mToken.setCurrentIndex(spokeIndex_);

        vm.expectEmit();
        emit ISpokePortal.MTokenIndexReceived(hubIndex_);
        vm.expectCall(address(mToken), abi.encodeCall(ISpokeMTokenLike.updateIndex, (hubIndex_)));

        vm.prank(address(bridge));
        spokePortal.receiveMessage(HUB_CHAIN_ID, user, payload_);

        assertEq(spokePortal.currentIndex(), hubIndex_);
    }

    function test_receiveMessage_key() external {
        bytes32 key_ = bytes32("key");
        bytes32 value_ = bytes32("value");

        bytes memory payload_ = PayloadEncoder.encodeKey(key_, value_);

        vm.expectEmit();
        emit ISpokePortal.RegistrarKeyReceived(key_, value_);
        vm.expectCall(address(registrar), abi.encodeCall(IRegistrarLike.setKey, (key_, value_)));

        vm.prank(address(bridge));
        spokePortal.receiveMessage(HUB_CHAIN_ID, user, payload_);
    }

    function test_receiveMessage_listUpdate() external {
        bytes32 listName_ = bytes32("listName");
        address account_ = user;

        // Add to list
        bool add_ = true;
        bytes memory payload_ = PayloadEncoder.encodeListUpdate(listName_, account_, add_);

        vm.expectEmit();
        emit ISpokePortal.RegistrarListStatusReceived(listName_, account_, add_);
        vm.expectCall(address(registrar), abi.encodeCall(IRegistrarLike.addToList, (listName_, account_)));

        vm.prank(address(bridge));
        spokePortal.receiveMessage(HUB_CHAIN_ID, user, payload_);

        // Remove from list
        add_ = false;
        payload_ = PayloadEncoder.encodeListUpdate(listName_, account_, add_);

        vm.expectEmit();
        emit ISpokePortal.RegistrarListStatusReceived(listName_, account_, add_);
        vm.expectCall(address(registrar), abi.encodeCall(IRegistrarLike.removeFromList, (listName_, account_)));

        vm.prank(address(bridge));
        spokePortal.receiveMessage(HUB_CHAIN_ID, user, payload_);
    }
}
