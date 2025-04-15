// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.26;

import { Test } from "forge-std/Test.sol";

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

    // Ownership Tests
    function test_transferOwnership() external {
        vm.prank(OWNER);
        pausable.transferOwnership(NEW_OWNER);

        assertEq(pausable.owner(), NEW_OWNER);
    }

    function test_transferOwnership_emitsEvent() external {
        vm.prank(OWNER);
        vm.expectEmit(true, true, false, true);
        emit IPausableOwnable.OwnershipTransferred(OWNER, NEW_OWNER);
        pausable.transferOwnership(NEW_OWNER);
    }

    function test_transferOwnership_nonOwner() external {
        vm.prank(address(0xBAD));
        vm.expectRevert(abi.encodeWithSelector(IPausableOwnable.Unauthorized.selector, address(0xBAD)));
        pausable.transferOwnership(NEW_OWNER);
    }

    function test_transferOwnership_zeroAddress() external {
        vm.prank(OWNER);
        vm.expectRevert(IPausableOwnable.ZeroOwner.selector);
        pausable.transferOwnership(address(0));
    }

    // Pauser Role Tests
    function test_transferPauserRole() external {
        vm.prank(OWNER);
        pausable.transferPauserRole(NEW_PAUSER);

        assertEq(pausable.pauser(), NEW_PAUSER);
    }

    function test_transferPauserRole_nonOwner() external {
        vm.prank(address(0xBAD));
        vm.expectRevert(abi.encodeWithSelector(IPausableOwnable.Unauthorized.selector, address(0xBAD)));
        pausable.transferPauserRole(NEW_PAUSER);
    }

    // Pause/Unpause Tests
    function test_pause() external {
        vm.prank(OWNER);
        vm.expectEmit(false, false, false, true);
        emit IPausableOwnable.Paused();
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
        emit IPausableOwnable.Unpaused();
        pausable.unpause();
        assertFalse(pausable.paused());
    }

    // Pause State Modifier
    function test_whenNotPausedModifier() external {
        vm.prank(OWNER);
        pausable.pause();

        vm.expectRevert(IPausableOwnable.OperationPaused.selector);
        pausable.exampleFunction();
    }

    // Edge Cases
    function test_pause_alreadyPaused() external {
        vm.prank(OWNER);
        pausable.pause();

        vm.prank(OWNER);
        vm.expectRevert(IPausableOwnable.AlreadyPaused.selector);
        pausable.pause();
    }

    function test_unpause_notPaused() external {
        vm.prank(OWNER);
        vm.expectRevert(IPausableOwnable.NotPaused.selector);
        pausable.unpause();
    }
}
