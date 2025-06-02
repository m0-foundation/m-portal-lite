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
    MockMToken public mToken;
    MockPortal public spokePortal;

    function setUp() external {
        mToken = new MockMToken();
        spokePortal = new MockPortal();

        vm.mockCall(address(spokePortal), abi.encodeWithSelector(IPortal.mToken.selector), abi.encode(address(mToken)));

        spokeVault = new SpokeVault(address(spokePortal), hubVault, HUB_CHAIN_ID, migrationAdmin);

        vm.deal(user, 10 ether);
        vm.deal(address(spokeVault), 5 ether);
    }

    ///////////////////////////////////////////////////////////////////////////
    //                              CONSTRUCTOR                              //
    ///////////////////////////////////////////////////////////////////////////

    function test_constructor_initialState() external {
        assertEq(spokeVault.spokePortal(), address(spokePortal));
        assertEq(spokeVault.hubVault(), hubVault);
        assertEq(spokeVault.hubChainId(), HUB_CHAIN_ID);
        assertEq(spokeVault.migrationAdmin(), migrationAdmin);
        assertEq(spokeVault.mToken(), address(mToken));
    }

    function test_constructor_zeroSpokePortal() external {
        vm.expectRevert(ISpokeVault.ZeroSpokePortal.selector);
        new SpokeVault(address(0), hubVault, HUB_CHAIN_ID, migrationAdmin);
    }

    function test_constructor_zeroHubVault() external {
        vm.expectRevert(ISpokeVault.ZeroHubVault.selector);
        new SpokeVault(address(spokePortal), address(0), HUB_CHAIN_ID, migrationAdmin);
    }

    function test_constructor_zeroHubChain() external {
        vm.expectRevert(ISpokeVault.ZeroHubChain.selector);
        new SpokeVault(address(spokePortal), hubVault, 0, migrationAdmin);
    }

    function test_constructor_zeroMigrationAdmin() external {
        vm.expectRevert(ISpokeVault.ZeroMigrationAdmin.selector);
        new SpokeVault(address(spokePortal), hubVault, HUB_CHAIN_ID, address(0));
    }

    ///////////////////////////////////////////////////////////////////////////
    //                          transferExcessM                             //
    ///////////////////////////////////////////////////////////////////////////

    function test_transferExcessM_success() external {
        uint256 amount = 1e6;
        bytes32 expectedMessageId = bytes32(0);

        // Mint tokens to the vault
        mToken.mint(address(spokeVault), amount);

        vm.expectCall(address(spokePortal), abi.encodeCall(IPortal.transfer, (amount, HUB_CHAIN_ID, hubVault, refundAddress)));

        vm.expectEmit(true, false, false, true);
        emit ISpokeVault.ExcessMTokenSent(amount, expectedMessageId);

        vm.prank(user);
        spokeVault.transferExcessM{ value: 0.0001 ether }(refundAddress);
    }

    function test_transferExcessM_noTokensReturnsZero() external {
        // No tokens in vault
        assertEq(mToken.balanceOf(address(spokeVault)), 0);

        vm.prank(user);
        bytes32 messageId = spokeVault.transferExcessM{ value: 1 ether }(refundAddress);

        assertEq(messageId, bytes32(0));
    }
}
