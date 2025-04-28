// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.26;

import { Test } from "../../../lib/forge-std/src/Test.sol";
import { Ownable } from "../../../lib/openzeppelin/contracts/access/Ownable.sol";
import { Pausable } from "../../../lib/openzeppelin/contracts/utils/Pausable.sol";

import { IPausableOwnable } from "../../../src/interfaces/IPausableOwnable.sol";
import { PausableOwnable } from "../../../src/access/PausableOwnable.sol";

contract MockPausableOwnable is PausableOwnable {
    constructor(address initialOwner_, address initialPauser_) PausableOwnable(initialOwner_, initialPauser_) { }

    function exampleFunction() external view whenNotPaused returns (bool) {
        return true;
    }
}

contract PausableOwnableTest is Test {
    address public owner = makeAddr("owner");
    address public pauser = makeAddr("pauser");
    address public newOwner = makeAddr("new owner");
    address public newPauser = makeAddr("new pauser");

    MockPausableOwnable public pausable;

    function setUp() external {
        pausable = new MockPausableOwnable(owner, pauser);
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
        vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, address(0xBAD)));
        pausable.transferPauserRole(newPauser);
    }

    // Pause/Unpause Tests
    function test_pause() external {
        vm.prank(owner);
        vm.expectEmit(false, false, false, true);
        emit Pausable.Paused(owner);
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
        emit Pausable.Unpaused(owner);
        pausable.unpause();
        assertFalse(pausable.paused());
    }

    // Pause State Modifier
    function test_whenNotPausedModifier() external {
        vm.prank(owner);
        pausable.pause();

        vm.expectRevert(Pausable.EnforcedPause.selector);
        pausable.exampleFunction();
    }

    // Edge Cases
    function test_pause_alreadyPaused() external {
        vm.prank(owner);
        pausable.pause();

        vm.prank(owner);
        vm.expectRevert(Pausable.EnforcedPause.selector);
        pausable.pause();
    }

    function test_unpause_notPaused() external {
        vm.prank(owner);
        vm.expectRevert(Pausable.ExpectedPause.selector);
        pausable.unpause();
    }
}
