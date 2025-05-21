// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.26;

import { Test } from "../../../lib/forge-std/src/Test.sol";
import { OwnableUpgradeable } from "../../../lib/openzeppelin-contracts-upgradeable/contracts/access/OwnableUpgradeable.sol";
import { PausableUpgradeable } from "../../../lib/openzeppelin-contracts-upgradeable/contracts/utils/PausableUpgradeable.sol";

import { IPausableOwnable } from "../../../src/interfaces/IPausableOwnable.sol";
import { PausableOwnableUpgradeable } from "../../../src/access/PausableOwnableUpgradeable.sol";

contract MockPausableOwnableUpgradeable is PausableOwnableUpgradeable {
    function initialize(address initialOwner_, address initialPauser_) external initializer {
        __PausableOwnable_init(initialOwner_, initialPauser_);
    }

    function exampleFunction() external view whenNotPaused returns (bool) {
        return true;
    }
}

contract PausableOwnableUpgradeableTest is Test {
    address public owner = makeAddr("owner");
    address public pauser = makeAddr("pauser");
    address public newOwner = makeAddr("new owner");
    address public newPauser = makeAddr("new pauser");

    MockPausableOwnableUpgradeable public pausable;

    function setUp() external {
        pausable = new MockPausableOwnableUpgradeable();
        pausable.initialize(owner, pauser);
    }

    // Test Initial State
    function test_initialState() external {
        assertEq(pausable.owner(), owner);
        assertEq(pausable.pauser(), pauser);
        assertFalse(pausable.paused());
    }

    // Pauser Role Tests
    function test_transferPauserRole() external {
        vm.prank(owner);
        pausable.transferPauserRole(newPauser);

        assertEq(pausable.pauser(), newPauser);
    }

    function test_transferPauserRole_nonOwner() external {
        vm.prank(address(0xBAD));
        vm.expectRevert(abi.encodeWithSelector(OwnableUpgradeable.OwnableUnauthorizedAccount.selector, address(0xBAD)));
        pausable.transferPauserRole(newPauser);
    }

    // Pause/Unpause Tests
    function test_pause() external {
        vm.prank(owner);
        vm.expectEmit(false, false, false, true);
        emit PausableUpgradeable.Paused(owner);
        pausable.pause();
        assertTrue(pausable.paused());
    }

    function test_pause_asPauser() external {
        vm.prank(pauser);
        pausable.pause();
        assertTrue(pausable.paused());
    }

    function test_pause_unauthorized() external {
        vm.prank(address(0xBAD));
        vm.expectRevert(abi.encodeWithSelector(IPausableOwnable.Unauthorized.selector, address(0xBAD)));
        pausable.pause();
    }

    function test_unpause() external {
        vm.prank(owner);
        pausable.pause();

        vm.prank(owner);
        vm.expectEmit(false, false, false, true);
        emit PausableUpgradeable.Unpaused(owner);
        pausable.unpause();
        assertFalse(pausable.paused());
    }

    // Pause State Modifier
    function test_whenNotPausedModifier() external {
        vm.prank(owner);
        pausable.pause();

        vm.expectRevert(PausableUpgradeable.EnforcedPause.selector);
        pausable.exampleFunction();
    }

    // Edge Cases
    function test_pause_alreadyPaused() external {
        vm.prank(owner);
        pausable.pause();

        vm.prank(owner);
        vm.expectRevert(PausableUpgradeable.EnforcedPause.selector);
        pausable.pause();
    }

    function test_unpause_notPaused() external {
        vm.prank(owner);
        vm.expectRevert(PausableUpgradeable.ExpectedPause.selector);
        pausable.unpause();
    }
}
