// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.26;

import { Test } from "../../lib/forge-std/src/Test.sol";
import { TimelockController } from "../../lib/openzeppelin/contracts/governance/TimelockController.sol";
import { OwnableUpgradeable } from "../../lib/openzeppelin-contracts-upgradeable/contracts/access/OwnableUpgradeable.sol";
import { IPausableOwnable } from "../../src/interfaces/IPausableOwnable.sol";
import { IRegistrarLike } from "../../src/interfaces/IRegistrarLike.sol";
import { Portal } from "../../src/Portal.sol";
import { HubPortal } from "../../src/HubPortal.sol";
import { PayloadType } from "../../src/libs/PayloadEncoder.sol";

contract TimeLockPortalForkTest is Test {
    uint256 public constant MAINNET_CHAIN_ID = 1;

    // Mainnet deployed contract addresses
    address public constant MAINNET_HUB_PORTAL = 0x36f586A30502AE3afb555b8aA4dCc05d233c2ecE;
    address public constant MAINNET_M_TOKEN = 0x866A2BF4E572CbcF37D5071A7a58503Bfb36be1b;

    address public constant MAINNET_TIMELOCK = 0x23CA665c8a73292Fc7AC2cC4493d2cE883BBA468;
    address public constant TIMELOCK_PROPOSER_1 = 0xb7A9B5f301eF3bAD36C2b4964E82931Dd7fb989C;
    address public constant TIMELOCK_EXECUTOR_1 = 0xF2f1ACbe0BA726fEE8d75f3E32900526874740BB;
    address public constant TIMELOCK_ADMIN = 0xdcf79C332cB3Fe9d39A830a5f8de7cE6b1BD6fD1;

    // Use latest block to avoid code absence issues; can pin if needed later
    uint256 public constant MAINNET_FORK_BLOCK = 23743449;

    // Timelock configuration matches deployed delay (3 days)
    uint256 public constant TIMELOCK_DELAY = 259200; // 3 days

    uint256 public mainnetForkId;
    HubPortal public hubPortal;
    TimelockController public timelock;

    // Test accounts
    address public currentOwner;

    function setUp() external {
        // Fork Ethereum Mainnet
        mainnetForkId = vm.createSelectFork({ urlOrAlias: "ethereum", blockNumber: MAINNET_FORK_BLOCK });

        // Load the deployed contracts from Mainnet
        hubPortal = HubPortal(MAINNET_HUB_PORTAL);
        timelock = TimelockController(payable(MAINNET_TIMELOCK));

        currentOwner = hubPortal.owner();

        // Fund role addresses and helpers for gas
        vm.deal(TIMELOCK_PROPOSER_1, 1 ether);
        vm.deal(TIMELOCK_EXECUTOR_1, 1 ether);

        // attempt timelock transfer (impersonation)
        vm.deal(currentOwner, 1 ether);
        vm.prank(currentOwner);
        hubPortal.transferOwnership(address(timelock));
        assertEq(hubPortal.owner(), address(timelock), "Timelock must own HubPortal");
    }

    /// @dev Pause via timelock using actual proposer/executor roles
    function test_timelock_pause_success() external {
        assertFalse(hubPortal.paused(), "Already paused");

        bytes32 operationId = timelock.hashOperation(
            MAINNET_HUB_PORTAL, 0, abi.encodeWithSelector(IPausableOwnable.pause.selector), bytes32(0), bytes32(0)
        );

        // Schedule using a valid proposer
        vm.prank(TIMELOCK_PROPOSER_1);
        timelock.schedule(
            MAINNET_HUB_PORTAL, 0, abi.encodeWithSelector(IPausableOwnable.pause.selector), bytes32(0), bytes32(0), TIMELOCK_DELAY
        );

        assertTrue(timelock.isOperationPending(operationId));
        assertFalse(timelock.isOperationReady(operationId));
        assertFalse(hubPortal.paused());

        // Advance time beyond delay
        vm.warp(block.timestamp + TIMELOCK_DELAY + 1);
        assertTrue(timelock.isOperationReady(operationId));

        // Execute with a valid executor
        vm.prank(TIMELOCK_EXECUTOR_1);
        timelock.execute(MAINNET_HUB_PORTAL, 0, abi.encodeWithSelector(IPausableOwnable.pause.selector), bytes32(0), bytes32(0));

        assertTrue(timelock.isOperationDone(operationId));
        assertTrue(hubPortal.paused());
    }

    /// @dev Enable cross-spoke connection via timelock (owner-only function enableCrossSpokeConnection(uint256))
    function test_timelock_enableCrossSpokeConnection_success() external {
        uint256 spokeChainId = 999; // sample spoke chain id used elsewhere

        assertFalse(hubPortal.crossSpokeConnectionEnabled(spokeChainId), "Connection already enabled");

        bytes32 opId = timelock.hashOperation(
            MAINNET_HUB_PORTAL,
            0,
            abi.encodeWithSelector(HubPortal.enableCrossSpokeConnection.selector, spokeChainId),
            bytes32(0),
            bytes32(0)
        );

        // Schedule by valid proposer
        vm.prank(TIMELOCK_PROPOSER_1);
        timelock.schedule(
            MAINNET_HUB_PORTAL,
            0,
            abi.encodeWithSelector(HubPortal.enableCrossSpokeConnection.selector, spokeChainId),
            bytes32(0),
            bytes32(0),
            TIMELOCK_DELAY
        );
        assertTrue(timelock.isOperationPending(opId));
        assertFalse(timelock.isOperationReady(opId));

        // Advance time
        vm.warp(block.timestamp + TIMELOCK_DELAY + 1);
        assertTrue(timelock.isOperationReady(opId));

        // Execute by valid executor
        vm.prank(TIMELOCK_EXECUTOR_1);
        timelock.execute(
            MAINNET_HUB_PORTAL,
            0,
            abi.encodeWithSelector(HubPortal.enableCrossSpokeConnection.selector, spokeChainId),
            bytes32(0),
            bytes32(0)
        );

        // Verify
        assertTrue(timelock.isOperationDone(opId));
        assertTrue(hubPortal.crossSpokeConnectionEnabled(spokeChainId));
    }

    function test_timelock_unpause_success() external {
        vm.prank(TIMELOCK_PROPOSER_1);
        timelock.schedule(
            MAINNET_HUB_PORTAL, 0, abi.encodeWithSelector(IPausableOwnable.pause.selector), bytes32(0), bytes32(0), TIMELOCK_DELAY
        );
        vm.warp(block.timestamp + TIMELOCK_DELAY + 1);
        vm.prank(TIMELOCK_EXECUTOR_1);
        timelock.execute(MAINNET_HUB_PORTAL, 0, abi.encodeWithSelector(IPausableOwnable.pause.selector), bytes32(0), bytes32(0));
        assertTrue(hubPortal.paused(), "Precondition pause failed");

        bytes32 opId = timelock.hashOperation(
            MAINNET_HUB_PORTAL, 0, abi.encodeWithSelector(IPausableOwnable.unpause.selector), bytes32(0), bytes32(0)
        );

        vm.prank(TIMELOCK_PROPOSER_1);
        timelock.schedule(
            MAINNET_HUB_PORTAL,
            0,
            abi.encodeWithSelector(IPausableOwnable.unpause.selector),
            bytes32(0),
            bytes32(0),
            TIMELOCK_DELAY
        );
        vm.warp(block.timestamp + TIMELOCK_DELAY + 1);
        vm.prank(TIMELOCK_EXECUTOR_1);
        timelock.execute(MAINNET_HUB_PORTAL, 0, abi.encodeWithSelector(IPausableOwnable.unpause.selector), bytes32(0), bytes32(0));
        assertTrue(timelock.isOperationDone(opId));
        assertFalse(hubPortal.paused());
    }

    function test_timelock_setPayloadGasLimit_success() external {
        // Use enum for clarity: PayloadType.Token = 0
        uint256 spokeChainId = 999;
        PayloadType payloadType = PayloadType.Token;
        uint256 newLimit = 500_000;

        bytes memory callData = abi.encodeWithSelector(Portal.setPayloadGasLimit.selector, spokeChainId, payloadType, newLimit);

        bytes32 opId = timelock.hashOperation(MAINNET_HUB_PORTAL, 0, callData, bytes32(0), bytes32(0));

        vm.prank(TIMELOCK_PROPOSER_1);
        timelock.schedule(MAINNET_HUB_PORTAL, 0, callData, bytes32(0), bytes32(0), TIMELOCK_DELAY);

        vm.warp(block.timestamp + TIMELOCK_DELAY + 1);

        vm.prank(TIMELOCK_EXECUTOR_1);
        timelock.execute(MAINNET_HUB_PORTAL, 0, callData, bytes32(0), bytes32(0));

        assertTrue(timelock.isOperationDone(opId));
        assertEq(Portal(MAINNET_HUB_PORTAL).payloadGasLimit(spokeChainId, payloadType), newLimit, "Gas limit not set");
    }

    function test_timelock_setDestinationAndPath_batch() external {
        uint256 spokeChainId = 999;
        // Using existing mToken address for destination (illustrative)
        address destMToken = MAINNET_M_TOKEN;
        // Use base Portal selectors (functions defined in Portal)
        bytes4 setDestSel = Portal.setDestinationMToken.selector;
        bytes4 setPathSel = Portal.setSupportedBridgingPath.selector;

        address[] memory targets = new address[](2);
        uint256[] memory values = new uint256[](2);
        bytes[] memory payloads = new bytes[](2);
        targets[0] = MAINNET_HUB_PORTAL;
        targets[1] = MAINNET_HUB_PORTAL;
        values[0] = 0;
        values[1] = 0;
        payloads[0] = abi.encodeWithSelector(setDestSel, spokeChainId, destMToken);
        payloads[1] = abi.encodeWithSelector(setPathSel, MAINNET_M_TOKEN, spokeChainId, destMToken, true);

        bytes32 opId = timelock.hashOperationBatch(targets, values, payloads, bytes32(0), bytes32(0));

        vm.prank(TIMELOCK_PROPOSER_1);
        timelock.scheduleBatch(targets, values, payloads, bytes32(0), bytes32(0), TIMELOCK_DELAY);
        vm.warp(block.timestamp + TIMELOCK_DELAY + 1);
        vm.prank(TIMELOCK_EXECUTOR_1);
        timelock.executeBatch(targets, values, payloads, bytes32(0), bytes32(0));
        assertTrue(timelock.isOperationDone(opId));
    }

    function test_direct_owner_call_reverts() external {
        address attacker = address(0xBEEF);
        vm.deal(attacker, 1 ether);
        vm.prank(attacker);
        vm.expectRevert();
        hubPortal.pause();
    }

    function test_timelock_setBridge_success() external {
        // choose a new (dummy) bridge address (non-zero). No interface calls in setter.
        address newBridge = makeAddr("alice");
        bytes32 opId = timelock.hashOperation(
            MAINNET_HUB_PORTAL, 0, abi.encodeWithSelector(Portal.setBridge.selector, newBridge), bytes32(0), bytes32(0)
        );
        vm.prank(TIMELOCK_PROPOSER_1);
        timelock.schedule(
            MAINNET_HUB_PORTAL,
            0,
            abi.encodeWithSelector(Portal.setBridge.selector, newBridge),
            bytes32(0),
            bytes32(0),
            TIMELOCK_DELAY
        );
        vm.warp(block.timestamp + TIMELOCK_DELAY + 1);
        vm.prank(TIMELOCK_EXECUTOR_1);
        timelock.execute(
            MAINNET_HUB_PORTAL, 0, abi.encodeWithSelector(Portal.setBridge.selector, newBridge), bytes32(0), bytes32(0)
        );
        assertTrue(timelock.isOperationDone(opId));
        // Cannot directly read `bridge` (public) since it's in Portal; cast works:
        assertEq(Portal(MAINNET_HUB_PORTAL).bridge(), newBridge);
    }

    function test_timelock_transferOwnership_success() external {
        address newOwner = makeAddr("alice");
        bytes32 opId = timelock.hashOperation(
            MAINNET_HUB_PORTAL,
            0,
            abi.encodeWithSelector(OwnableUpgradeable.transferOwnership.selector, newOwner),
            bytes32(0),
            bytes32(0)
        );
        vm.prank(TIMELOCK_PROPOSER_1);
        timelock.schedule(
            MAINNET_HUB_PORTAL,
            0,
            abi.encodeWithSelector(OwnableUpgradeable.transferOwnership.selector, newOwner),
            bytes32(0),
            bytes32(0),
            TIMELOCK_DELAY
        );
        vm.warp(block.timestamp + TIMELOCK_DELAY + 1);
        vm.prank(TIMELOCK_EXECUTOR_1);
        timelock.execute(
            MAINNET_HUB_PORTAL,
            0,
            abi.encodeWithSelector(OwnableUpgradeable.transferOwnership.selector, newOwner),
            bytes32(0),
            bytes32(0)
        );
        assertTrue(timelock.isOperationDone(opId));
        assertEq(hubPortal.owner(), newOwner);
    }

    function test_timelock_renounceOwnership_success() external {
        bytes32 opId = timelock.hashOperation(
            MAINNET_HUB_PORTAL, 0, abi.encodeWithSelector(OwnableUpgradeable.renounceOwnership.selector), bytes32(0), bytes32(0)
        );
        vm.prank(TIMELOCK_PROPOSER_1);
        timelock.schedule(
            MAINNET_HUB_PORTAL,
            0,
            abi.encodeWithSelector(OwnableUpgradeable.renounceOwnership.selector),
            bytes32(0),
            bytes32(0),
            TIMELOCK_DELAY
        );
        vm.warp(block.timestamp + TIMELOCK_DELAY + 1);
        vm.prank(TIMELOCK_EXECUTOR_1);
        timelock.execute(
            MAINNET_HUB_PORTAL, 0, abi.encodeWithSelector(OwnableUpgradeable.renounceOwnership.selector), bytes32(0), bytes32(0)
        );
        assertTrue(timelock.isOperationDone(opId));
        assertEq(hubPortal.owner(), address(0));
    }

    // ----------------------- Cancellation Tests ----------------------- //

    function test_timelock_cancel_pending_single() external {
        bytes memory callData = abi.encodeWithSelector(IPausableOwnable.pause.selector);
        bytes32 opId = timelock.hashOperation(MAINNET_HUB_PORTAL, 0, callData, bytes32(0), bytes32(0));
        vm.prank(TIMELOCK_PROPOSER_1);
        timelock.schedule(MAINNET_HUB_PORTAL, 0, callData, bytes32(0), bytes32(0), TIMELOCK_DELAY);
        assertTrue(timelock.isOperationPending(opId));
        vm.prank(TIMELOCK_PROPOSER_1); // proposer has CANCELLER_ROLE per OZ constructor
        timelock.cancel(opId);
        assertFalse(timelock.isOperation(opId));
        vm.prank(TIMELOCK_EXECUTOR_1);
        vm.expectRevert();
        timelock.execute(MAINNET_HUB_PORTAL, 0, callData, bytes32(0), bytes32(0));
    }

    function test_timelock_cancel_ready_single() external {
        bytes memory callData = abi.encodeWithSelector(IPausableOwnable.pause.selector);
        bytes32 opId = timelock.hashOperation(MAINNET_HUB_PORTAL, 0, callData, bytes32(0), bytes32(0));
        vm.prank(TIMELOCK_PROPOSER_1);
        timelock.schedule(MAINNET_HUB_PORTAL, 0, callData, bytes32(0), bytes32(0), TIMELOCK_DELAY);
        vm.warp(block.timestamp + TIMELOCK_DELAY + 1);
        assertTrue(timelock.isOperationReady(opId));
        vm.prank(TIMELOCK_PROPOSER_1);
        timelock.cancel(opId);
        assertFalse(timelock.isOperation(opId));
        vm.prank(TIMELOCK_EXECUTOR_1);
        vm.expectRevert();
        timelock.execute(MAINNET_HUB_PORTAL, 0, callData, bytes32(0), bytes32(0));
    }

    function test_timelock_cancel_unauthorized_reverts() external {
        bytes memory callData = abi.encodeWithSelector(IPausableOwnable.pause.selector);
        bytes32 opId = timelock.hashOperation(MAINNET_HUB_PORTAL, 0, callData, bytes32(0), bytes32(0));
        vm.prank(TIMELOCK_PROPOSER_1);
        timelock.schedule(MAINNET_HUB_PORTAL, 0, callData, bytes32(0), bytes32(0), TIMELOCK_DELAY);
        address attacker = makeAddr("attacker");
        vm.prank(attacker);
        vm.expectRevert();
        timelock.cancel(opId);
        // Valid canceller still succeeds
        vm.prank(TIMELOCK_PROPOSER_1);
        timelock.cancel(opId);
        assertFalse(timelock.isOperation(opId));
    }

    function test_timelock_cancel_after_execute_reverts() external {
        bytes memory callData = abi.encodeWithSelector(IPausableOwnable.pause.selector);
        bytes32 opId = timelock.hashOperation(MAINNET_HUB_PORTAL, 0, callData, bytes32(0), bytes32(0));
        vm.prank(TIMELOCK_PROPOSER_1);
        timelock.schedule(MAINNET_HUB_PORTAL, 0, callData, bytes32(0), bytes32(0), TIMELOCK_DELAY);
        vm.warp(block.timestamp + TIMELOCK_DELAY + 1);
        vm.prank(TIMELOCK_EXECUTOR_1);
        timelock.execute(MAINNET_HUB_PORTAL, 0, callData, bytes32(0), bytes32(0));
        assertTrue(timelock.isOperationDone(opId));
        vm.prank(TIMELOCK_PROPOSER_1);
        vm.expectRevert();
        timelock.cancel(opId);
    }

    function test_timelock_cancel_batch_pending() external {
        uint256 spokeChainId = 999;
        bytes4 setDestSel = Portal.setDestinationMToken.selector;
        bytes4 setPathSel = Portal.setSupportedBridgingPath.selector;
        address destMToken = MAINNET_M_TOKEN;
        address[] memory targets = new address[](2);
        uint256[] memory values = new uint256[](2);
        bytes[] memory payloads = new bytes[](2);
        targets[0] = MAINNET_HUB_PORTAL;
        targets[1] = MAINNET_HUB_PORTAL;
        values[0] = 0;
        values[1] = 0;
        payloads[0] = abi.encodeWithSelector(setDestSel, spokeChainId, destMToken);
        payloads[1] = abi.encodeWithSelector(setPathSel, MAINNET_M_TOKEN, spokeChainId, destMToken, true);
        bytes32 opId = timelock.hashOperationBatch(targets, values, payloads, bytes32(0), bytes32(0));
        vm.prank(TIMELOCK_PROPOSER_1);
        timelock.scheduleBatch(targets, values, payloads, bytes32(0), bytes32(0), TIMELOCK_DELAY);
        assertTrue(timelock.isOperationPending(opId));
        vm.prank(TIMELOCK_PROPOSER_1);
        timelock.cancel(opId);
        assertFalse(timelock.isOperation(opId));
        vm.prank(TIMELOCK_EXECUTOR_1);
        vm.expectRevert();
        timelock.executeBatch(targets, values, payloads, bytes32(0), bytes32(0));
    }
}

