// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.26;

import { Test } from "../../lib/forge-std/src/Test.sol";
import { IERC20 } from "../../lib/common/src/interfaces/IERC20.sol";

import { SpokeVault } from "../../src/SpokeVault.sol";
import { ISpokeVault } from "../../src/interfaces/ISpokeVault.sol";
import { IPortal } from "../../src/interfaces/IPortal.sol";

import { MockMToken } from "../mocks/MockMToken.sol";
import { MockPortal } from "../mocks/MockPortal.sol";

contract SpokeVaultTest is Test {
    uint256 public constant HUB_CHAIN_ID = 1;

    address public hubVault = makeAddr("hubVault");
    address public migrationAdmin = makeAddr("migrationAdmin");
    address public user = makeAddr("user");
    address public refundAddress = makeAddr("refundAddress");

    SpokeVault public spokeVault;
    MockMToken public wrappedMToken;
    MockPortal public spokePortal;

    function setUp() external {
        wrappedMToken = new MockMToken();
        spokePortal = new MockPortal();

        spokeVault = new SpokeVault(address(spokePortal), hubVault, HUB_CHAIN_ID, migrationAdmin, address(wrappedMToken));

        vm.deal(user, 10 ether);
        vm.deal(address(spokeVault), 5 ether);
    }

    ///////////////////////////////////////////////////////////////////////////
    //                              CONSTRUCTOR                              //
    ///////////////////////////////////////////////////////////////////////////

    function test_constructor_initialState() external view {
        assertEq(spokeVault.spokePortal(), address(spokePortal));
        assertEq(spokeVault.hubVault(), hubVault);
        assertEq(spokeVault.hubChainId(), HUB_CHAIN_ID);
        assertEq(spokeVault.migrationAdmin(), migrationAdmin);
        assertEq(spokeVault.wrappedMToken(), address(wrappedMToken));
    }

    function test_constructor_zeroSpokePortal() external {
        vm.expectRevert(ISpokeVault.ZeroSpokePortal.selector);
        new SpokeVault(address(0), hubVault, HUB_CHAIN_ID, migrationAdmin, address(wrappedMToken));
    }

    function test_constructor_zeroHubVault() external {
        vm.expectRevert(ISpokeVault.ZeroHubVault.selector);
        new SpokeVault(address(spokePortal), address(0), HUB_CHAIN_ID, migrationAdmin, address(wrappedMToken));
    }

    function test_constructor_zeroHubChain() external {
        vm.expectRevert(ISpokeVault.ZeroHubChain.selector);
        new SpokeVault(address(spokePortal), hubVault, 0, migrationAdmin, address(wrappedMToken));
    }

    function test_constructor_zeroMigrationAdmin() external {
        vm.expectRevert(ISpokeVault.ZeroMigrationAdmin.selector);
        new SpokeVault(address(spokePortal), hubVault, HUB_CHAIN_ID, address(0), address(wrappedMToken));
    }

    function test_constructor_zeroWrappedMToken() external {
        vm.expectRevert(ISpokeVault.ZeroWrappedMToken.selector);
        new SpokeVault(address(spokePortal), hubVault, HUB_CHAIN_ID, migrationAdmin, address(0));
    }

    ///////////////////////////////////////////////////////////////////////////
    //                      transferExcessWrappedM                          //
    ///////////////////////////////////////////////////////////////////////////

    function test_transferExcessWrappedM_success() external {
        uint256 amount = 1e6;
        bytes32 expectedMessageId = bytes32(0);

        wrappedMToken.mint(address(spokeVault), amount);

        vm.expectCall(
            address(spokePortal),
            abi.encodeCall(
                IPortal.transferMLikeToken,
                (amount, address(wrappedMToken), HUB_CHAIN_ID, address(wrappedMToken), hubVault, refundAddress)
            )
        );

        vm.expectEmit(true, false, false, true);
        emit ISpokeVault.ExcessMTokenSent(amount, expectedMessageId);

        vm.prank(user);
        spokeVault.transferExcessWrappedM{ value: 0.0001 ether }(refundAddress);
    }

    function test_transferExcessWrappedM_noTokensReturnsZero() external {
        assertEq(wrappedMToken.balanceOf(address(spokeVault)), 0);

        vm.prank(user);
        bytes32 messageId = spokeVault.transferExcessWrappedM{ value: 1 ether }(refundAddress);

        assertEq(messageId, bytes32(0));
    }
}
