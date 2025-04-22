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
    address public constant OWNER = address(1);
    address public constant PAUSER = address(2);
    address public constant NEW_OWNER = address(3);
    address public constant NEW_PAUSER = address(4);

    MockPausableOwnable public pausable;

    function setUp() external {
        pausable = new MockPausableOwnable(OWNER, PAUSER);
    }

    // Test Initial State
    function test_initialState() external {
        assertEq(pausable.owner(), OWNER);
        assertEq(pausable.pauser(), PAUSER);
        assertFalse(pausable.paused());
    }

    // Pauser Role Tests
    function test_transferPauserRole() external {
        vm.prank(OWNER);
        pausable.transferPauserRole(NEW_PAUSER);

        assertEq(pausable.pauser(), NEW_PAUSER);
    }

    function test_transferPauserRole_nonOwner() external {
        vm.prank(address(0xBAD));
        vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, address(0xBAD)));
        pausable.transferPauserRole(NEW_PAUSER);
    }

    // Pause/Unpause Tests
    function test_pause() external {
        vm.prank(OWNER);
        vm.expectEmit(false, false, false, true);
        emit Pausable.Paused(OWNER);
        pausable.pause();
        assertTrue(pausable.paused());
    }

    function test_pause_asPauser() external {
        vm.prank(PAUSER);
        pausable.pause();
        assertTrue(pausable.paused());
    }

    function test_pause_unauthorized() external {
        vm.prank(address(0xBAD));
        vm.expectRevert(abi.encodeWithSelector(IPausableOwnable.Unauthorized.selector, address(0xBAD)));
        pausable.pause();
    }

    function test_unpause() external {
        vm.prank(OWNER);
        pausable.pause();

        vm.prank(OWNER);
        vm.expectEmit(false, false, false, true);
        emit Pausable.Unpaused(OWNER);
        pausable.unpause();
        assertFalse(pausable.paused());
    }

    // Pause State Modifier
    function test_whenNotPausedModifier() external {
        vm.prank(OWNER);
        pausable.pause();

        vm.expectRevert(Pausable.EnforcedPause.selector);
        pausable.exampleFunction();
    }

    // Edge Cases
    function test_pause_alreadyPaused() external {
        vm.prank(OWNER);
        pausable.pause();

        vm.prank(OWNER);
        vm.expectRevert(Pausable.EnforcedPause.selector);
        pausable.pause();
    }

    function test_unpause_notPaused() external {
        vm.prank(OWNER);
        vm.expectRevert(Pausable.ExpectedPause.selector);
        pausable.unpause();
    }
}
