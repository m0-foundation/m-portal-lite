// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.26;

import { Test } from "../../lib/forge-std/src/Test.sol";

import { IERC20 } from "../../lib/common/src/interfaces/IERC20.sol";
import { IndexingMath } from "../../lib/common/src/libs/IndexingMath.sol";
import { ERC1967Proxy } from "../../lib/openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

import { IPortal } from "../../src/interfaces/IPortal.sol";
import { IMTokenLike } from "../../src/interfaces/IMTokenLike.sol";
import { IRegistrarLike } from "../../src/interfaces/IRegistrarLike.sol";
import { HubPortal } from "../../src/HubPortal.sol";
import { HyperlaneBridge } from "../../src/bridges/hyperlane/HyperlaneBridge.sol";
import { PayloadEncoder } from "../../src/libs/PayloadEncoder.sol";
import { TypeConverter } from "../../src/libs/TypeConverter.sol";

contract HubPortalForkTest is Test {
    using TypeConverter for *;

    uint256 public constant ETHEREUM_CHAIN_ID = 1;
    uint256 public constant HYPEREVM_CHAIN_ID = 999;

    address public constant DEPLOYER = 0xF2f1ACbe0BA726fEE8d75f3E32900526874740BB;
    address public constant ETHEREUM_REGISTRAR = 0x119FbeeDD4F4f4298Fb59B720d5654442b81ae2c;
    address public constant ETHEREUM_M_TOKEN = 0x866A2BF4E572CbcF37D5071A7a58503Bfb36be1b;
    address public constant HYPER_M_TOKEN = 0x866A2BF4E572CbcF37D5071A7a58503Bfb36be1b;
    address public constant ETHEREUM_MAILBOX = 0xc005dc82818d67AF737725bD4bf75435d065D239;
    address public constant M_HOLDER = 0x3f0376da3Ae4313E7a5F1dA184BAFC716252d759;
    uint256 public constant ETHEREUM_FORK_BLOCK = 22_434_210;

    uint256 public constant TOKEN_TRANSFER_GAS_LIMIT = 250_000;

    uint256 public ethereumForkId;
    HubPortal public hubPortal;
    HyperlaneBridge public hubBridge;
    bytes32 public spokeBridge;

    address public alice = makeAddr("alice");

    function setUp() external {
        ethereumForkId = vm.createSelectFork({ urlOrAlias: "ethereum", blockNumber: ETHEREUM_FORK_BLOCK });

        vm.deal(DEPLOYER, 1 ether);
        vm.deal(M_HOLDER, 1 ether);
        vm.deal(alice, 1 ether);
        vm.deal(ETHEREUM_MAILBOX, 1 ether);

        vm.startPrank(DEPLOYER);

        uint256 nonce_ = vm.getNonce(DEPLOYER);
        address hubPortalAddress_ = vm.computeCreateAddress(DEPLOYER, nonce_ + 2);
        hubBridge = new HyperlaneBridge(ETHEREUM_MAILBOX, hubPortalAddress_, DEPLOYER);
        HubPortal implementation = new HubPortal(ETHEREUM_M_TOKEN, ETHEREUM_REGISTRAR);
        ERC1967Proxy proxy_ = new ERC1967Proxy(
            address(implementation), abi.encodeWithSelector(IPortal.initialize.selector, address(hubBridge), DEPLOYER, DEPLOYER)
        );
        hubPortal = HubPortal(address(proxy_));

        hubPortal.setDestinationMToken(HYPEREVM_CHAIN_ID, HYPER_M_TOKEN);
        hubPortal.setSupportedBridgingPath(ETHEREUM_M_TOKEN, HYPEREVM_CHAIN_ID, HYPER_M_TOKEN, true);

        spokeBridge = address(hubBridge).toBytes32();
        hubBridge.setPeer(HYPEREVM_CHAIN_ID, spokeBridge);

        vm.stopPrank();

        // Enable earning for the Hub Portal
        vm.mockCall(
            ETHEREUM_REGISTRAR,
            abi.encodeWithSelector(IRegistrarLike.listContains.selector, bytes32("earners"), address(hubPortal)),
            abi.encode(true)
        );

        hubPortal.enableEarning();
    }

    function test_transfer_bridgedPrincipal() external {
        uint256 amount_ = 1e6;
        address sender_ = M_HOLDER;
        address recipient_ = M_HOLDER;
        address refundAddress_ = M_HOLDER;
        uint256 fee_ = hubPortal.quoteTransfer(amount_, HYPEREVM_CHAIN_ID, recipient_);
        uint128 index_ = IMTokenLike(ETHEREUM_M_TOKEN).currentIndex();

        assertEq(hubPortal.bridgedPrincipal(HYPEREVM_CHAIN_ID), 0);

        vm.startPrank(M_HOLDER);
        IERC20(ETHEREUM_M_TOKEN).approve(address(hubPortal), amount_);
        hubPortal.transfer{ value: fee_ }(amount_, HYPEREVM_CHAIN_ID, recipient_, refundAddress_);
        vm.stopPrank();

        assertEq(IERC20(ETHEREUM_M_TOKEN).balanceOf(address(hubPortal)), 999_999);

        // Bridged principal = amount/index
        assertEq(hubPortal.bridgedPrincipal(HYPEREVM_CHAIN_ID), 959_443);

        // Simulate time passage to increase M token index
        vm.warp(block.timestamp + 10 minutes);

        // Simulte transfer from Spoke back to Hub
        bytes memory payload_ = PayloadEncoder.encodeTokenTransfer(amount_, ETHEREUM_M_TOKEN, sender_, recipient_, index_);
        vm.prank(ETHEREUM_MAILBOX);
        hubBridge.handle(uint32(HYPEREVM_CHAIN_ID), spokeBridge, payload_);

        // Bridged Principal isn't zero since the index has increased
        assertEq(hubPortal.bridgedPrincipal(HYPEREVM_CHAIN_ID), 1);
    }

    function test_transfer_insufficientBalance() external {
        uint256 amount_ = 1000;
        uint256 fee_ = hubPortal.quoteTransfer(amount_, HYPEREVM_CHAIN_ID, alice);
        uint128 index_ = IMTokenLike(ETHEREUM_M_TOKEN).currentIndex();

        vm.prank(M_HOLDER);
        IERC20(ETHEREUM_M_TOKEN).transfer(alice, amount_);

        assertEq(IERC20(ETHEREUM_M_TOKEN).balanceOf(alice), amount_);
        assertEq(IERC20(ETHEREUM_M_TOKEN).balanceOf(address(hubPortal)), 0);

        vm.startPrank(alice);
        IERC20(ETHEREUM_M_TOKEN).approve(address(hubPortal), amount_);
        hubPortal.transfer{ value: fee_ }(amount_, HYPEREVM_CHAIN_ID, alice, alice);
        vm.stopPrank();

        assertEq(IERC20(ETHEREUM_M_TOKEN).balanceOf(alice), 0);
        // The amount is rounded down when transferring from a non-earner to the earner HubPortal
        assertEq(IERC20(ETHEREUM_M_TOKEN).balanceOf(address(hubPortal)), 999);

        // Simulte transfer from Spoke back to Hub
        bytes memory payload_ = PayloadEncoder.encodeTokenTransfer(amount_, ETHEREUM_M_TOKEN, alice, alice, index_);
        vm.prank(ETHEREUM_MAILBOX);

        // HubPortal doesn't have enough balance to fulfill transfer
        vm.expectRevert(abi.encodeWithSelector(IMTokenLike.InsufficientBalance.selector, address(hubPortal), 959, 960));
        hubBridge.handle(uint32(HYPEREVM_CHAIN_ID), spokeBridge, payload_);

        // Simulate time passage to increase M token index
        vm.warp(block.timestamp + 5 days);

        // HubPortal has enough balance to fulfill transfer
        vm.prank(ETHEREUM_MAILBOX);
        hubBridge.handle(uint32(HYPEREVM_CHAIN_ID), spokeBridge, payload_);

        assertEq(IERC20(ETHEREUM_M_TOKEN).balanceOf(alice), amount_);
        assertEq(IERC20(ETHEREUM_M_TOKEN).balanceOf(address(hubPortal)), 0);
    }

    function test_stopEarning_fromMToken() external {
        assertTrue(IMTokenLike(ETHEREUM_M_TOKEN).isEarning(address(hubPortal)));

        // Remove HubPortal from the Earner list
        vm.mockCall(
            ETHEREUM_REGISTRAR,
            abi.encodeWithSelector(IRegistrarLike.listContains.selector, bytes32("earners"), address(hubPortal)),
            abi.encode(false)
        );

        // Stop earning
        IMTokenLike(ETHEREUM_M_TOKEN).stopEarning(address(hubPortal));

        assertEq(hubPortal.currentIndex(), IMTokenLike(ETHEREUM_M_TOKEN).currentIndex());
        // disableEarningIndex isn't set
        assertEq(hubPortal.disableEarningIndex(), IndexingMath.EXP_SCALED_ONE);

        hubPortal.disableEarning();
        assertEq(hubPortal.disableEarningIndex(), IMTokenLike(ETHEREUM_M_TOKEN).currentIndex());

        // Simulate time passage to increase M token index
        vm.warp(block.timestamp + 5 days);

        assertLt(hubPortal.disableEarningIndex(), IMTokenLike(ETHEREUM_M_TOKEN).currentIndex());
    }

    function test_disableEarning_fromHubPortal() external {
        assertTrue(IMTokenLike(ETHEREUM_M_TOKEN).isEarning(address(hubPortal)));

        // Remove HubPortal from the Earner list
        vm.mockCall(
            ETHEREUM_REGISTRAR,
            abi.encodeWithSelector(IRegistrarLike.listContains.selector, bytes32("earners"), address(hubPortal)),
            abi.encode(false)
        );

        hubPortal.disableEarning();
        assertEq(hubPortal.disableEarningIndex(), IMTokenLike(ETHEREUM_M_TOKEN).currentIndex());

        // Simulate time passage to increase M token index
        vm.warp(block.timestamp + 5 days);

        assertLt(hubPortal.disableEarningIndex(), IMTokenLike(ETHEREUM_M_TOKEN).currentIndex());
    }
}
