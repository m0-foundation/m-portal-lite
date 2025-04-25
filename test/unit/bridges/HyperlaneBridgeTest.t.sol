// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.26;

import { Test } from "../../../lib/forge-std/src/Test.sol";
import { Ownable } from "../../../lib/openzeppelin/contracts/access/Ownable.sol";

import { HyperlaneBridge } from "../../../src/bridges/hyperlane/HyperlaneBridge.sol";
import { IHyperlaneBridge } from "../../../src/bridges/hyperlane/interfaces/IHyperlaneBridge.sol";
import { StandardHookMetadata } from "../../../src/bridges/hyperlane/libs/StandardHookMetadata.sol";
import { IMailbox } from "../../../src/bridges/hyperlane/interfaces/IMailbox.sol";
import { IPortal } from "../../../src/interfaces/IPortal.sol";
import { IBridge } from "../../../src/interfaces/IBridge.sol";
import { TypeConverter } from "../../../src/libs/TypeConverter.sol";

import { MockMailbox } from "../../mocks/MockMailbox.sol";
import { MockPortal } from "../../mocks/MockPortal.sol";

contract HyperlaneBridgeTest is Test {
    using TypeConverter for *;

    uint256 public constant REMOTE_CHAIN_ID = 111;

    address public owner = makeAddr("owner");
    address public alice = makeAddr("alice");

    HyperlaneBridge public bridge;
    address public mailbox;
    address public portal;
    bytes32 public remotePeer;

    function setUp() public {
        mailbox = address(new MockMailbox());
        portal = address(new MockPortal());
        bridge = new HyperlaneBridge(mailbox, portal, owner);
        remotePeer = makeAddr("remotePeer").toBytes32();

        vm.prank(owner);
        bridge.setPeer(REMOTE_CHAIN_ID, remotePeer);
    }

    function test_constructor_zeroAddress() public {
        vm.expectRevert(IHyperlaneBridge.ZeroMailbox.selector);
        new HyperlaneBridge(address(0), portal, owner);

        vm.expectRevert(IBridge.ZeroPortal.selector);
        new HyperlaneBridge(mailbox, address(0), owner);
    }

    function test_setPeer() public {
        uint256 newChainId = 10;
        bytes32 newPeer = makeAddr("newPeer").toBytes32();

        vm.prank(owner);
        vm.expectEmit(address(bridge));
        emit IHyperlaneBridge.PeerSet(newChainId, newPeer);

        bridge.setPeer(newChainId, newPeer);

        assertEq(bridge.peer(newChainId), newPeer);
    }

    function test_setPeer_nonOwner() public {
        vm.prank(address(0xBAD));
        vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, address(0xBAD)));
        bridge.setPeer(REMOTE_CHAIN_ID, remotePeer);
    }

    function test_setPeer_zeroInputs() public {
        vm.prank(owner);
        vm.expectRevert(IHyperlaneBridge.ZeroDestinationChain.selector);
        bridge.setPeer(0, remotePeer);

        vm.prank(owner);
        vm.expectRevert(IHyperlaneBridge.ZeroPeer.selector);
        bridge.setPeer(REMOTE_CHAIN_ID, bytes32(0));
    }

    function testFuzz_quote(uint256 gasLimit_, bytes memory payload_, uint256 mailboxFee_) public {
        bytes memory metadata_ = StandardHookMetadata.formatMetadata(uint256(0), gasLimit_, address(alice), "");

        vm.mockCall(
            mailbox,
            abi.encodeCall(IMailbox.quoteDispatch, (uint32(REMOTE_CHAIN_ID), remotePeer, payload_, metadata_)),
            abi.encode(mailboxFee_)
        );

        vm.prank(alice);
        uint256 bridgeFee_ = bridge.quote(REMOTE_CHAIN_ID, gasLimit_, payload_);

        assertEq(bridgeFee_, mailboxFee_);
    }

    function test_quote_unsupportedChain() public {
        uint256 unsupportedChainId_ = 222;
        uint256 gasLimit_ = 200_000;
        bytes memory payload_ = bytes("payload");

        vm.expectRevert(abi.encodeWithSelector(IHyperlaneBridge.UnsupportedDestinationChain.selector, unsupportedChainId_));
        bridge.quote(unsupportedChainId_, gasLimit_, payload_);
    }

    function test_sendMessage() public {
        uint256 gasLimit_ = 100_000;
        bytes memory payload_ = bytes("payload");
        uint256 value_ = 0.001 ether;
        bytes memory metadata_ = StandardHookMetadata.formatMetadata(uint256(0), gasLimit_, address(alice), "");

        vm.expectCall(mailbox, abi.encodeCall(IMailbox.dispatch, (uint32(REMOTE_CHAIN_ID), remotePeer, payload_, metadata_)));

        vm.deal(portal, value_);
        vm.prank(portal);

        bridge.sendMessage{ value: value_ }(REMOTE_CHAIN_ID, gasLimit_, alice, payload_);
    }

    function test_sendMessage_notPortal() public {
        uint256 value_ = 0.001 ether;

        vm.expectRevert(IBridge.NotPortal.selector);

        vm.deal(alice, value_);
        vm.prank(alice);

        bridge.sendMessage{ value: value_ }(REMOTE_CHAIN_ID, 100_000, alice, bytes("payload"));
    }

    function test_handle() public {
        bytes memory payload_ = bytes("payload");

        vm.expectCall(portal, abi.encodeCall(IPortal.receiveMessage, (REMOTE_CHAIN_ID, alice, payload_)));

        vm.prank(mailbox);
        bridge.handle(uint32(REMOTE_CHAIN_ID), alice.toBytes32(), bytes("payload"));
    }

    function test_handle_notMailbox() public {
        vm.expectRevert(IHyperlaneBridge.NotMailbox.selector);

        vm.prank(alice);

        bridge.handle(uint32(REMOTE_CHAIN_ID), alice.toBytes32(), bytes("payload"));
    }
}
