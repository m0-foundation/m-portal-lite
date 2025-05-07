// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.26;

import { Test } from "../../lib/forge-std/src/Test.sol";
import { ERC1967Proxy } from "../../lib/openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import { OwnableUpgradeable } from "../../lib/openzeppelin-contracts-upgradeable/contracts/access/OwnableUpgradeable.sol";
import { PausableUpgradeable } from "../../lib/openzeppelin-contracts-upgradeable/contracts/utils/PausableUpgradeable.sol";
import { IndexingMath } from "../../lib/common/src/libs/IndexingMath.sol";

import { IPortal } from "../../src/interfaces/IPortal.sol";
import { IBridge } from "../../src/interfaces/IBridge.sol";
import { IPausableOwnable } from "../../src/interfaces/IPausableOwnable.sol";
import { IHubPortal } from "../../src/interfaces/IHubPortal.sol";
import { IMTokenLike } from "../../src/interfaces/IMTokenLike.sol";
import { HubPortal } from "../../src/HubPortal.sol";
import { PayloadType, PayloadEncoder } from "../../src/libs/PayloadEncoder.sol";

import { MockMToken } from "../mocks/MockMToken.sol";
import { MockWrappedMToken } from "../mocks/MockWrappedMToken.sol";
import { MockHubRegistrar } from "../mocks/MockHubRegistrar.sol";
import { MockBridge } from "../mocks/MockBridge.sol";

contract HubPortalTest is Test {
    uint256 public constant HUB_CHAIN_ID = 1;
    uint256 public constant SPOKE_CHAIN_ID = 999;

    uint256 public constant INDEX_UPDATE_GAS_LIMIT = 100_000;
    uint256 public constant KEY_UPDATE_GAS_LIMIT = 100_000;
    uint256 public constant LIST_UPDATE_GAS_LIMIT = 100_000;
    uint256 public constant TOKEN_TRANSFER_GAS_LIMIT = 250_000;

    /// @dev Registrar key of earners list.
    bytes32 internal constant EARNERS_LIST = "earners";

    /// @dev Registrar key holding value of whether the earners list can be ignored or not.
    bytes32 internal constant EARNERS_LIST_IGNORED = "earners_list_ignored";

    HubPortal public implementation;
    HubPortal public hubPortal;
    MockMToken public mToken;
    MockWrappedMToken public wrappedMToken;
    MockHubRegistrar public registrar;
    MockBridge public bridge;

    address public spokeMToken = makeAddr("spokeMToken");
    address public spokeWrappedMToken = makeAddr("spokeWrappedMToken");

    address public owner = makeAddr("owner");
    address public user = makeAddr("user");

    function setUp() external {
        mToken = new MockMToken();
        wrappedMToken = new MockWrappedMToken(address(mToken));
        registrar = new MockHubRegistrar();
        bridge = new MockBridge();
        implementation = new HubPortal(address(mToken), address(registrar));
        ERC1967Proxy proxy_ = new ERC1967Proxy(
            address(implementation), abi.encodeWithSelector(IPortal.initialize.selector, address(bridge), owner, owner)
        );
        hubPortal = HubPortal(address(proxy_));

        vm.startPrank(owner);

        // Configure
        hubPortal.setDestinationMToken(SPOKE_CHAIN_ID, spokeMToken);

        hubPortal.setSupportedBridgingPath(address(mToken), SPOKE_CHAIN_ID, spokeMToken, true);
        hubPortal.setSupportedBridgingPath(address(mToken), SPOKE_CHAIN_ID, spokeWrappedMToken, true);
        hubPortal.setSupportedBridgingPath(address(wrappedMToken), SPOKE_CHAIN_ID, spokeMToken, true);
        hubPortal.setSupportedBridgingPath(address(wrappedMToken), SPOKE_CHAIN_ID, spokeWrappedMToken, true);

        hubPortal.setPayloadGasLimit(SPOKE_CHAIN_ID, PayloadType.Token, TOKEN_TRANSFER_GAS_LIMIT);
        hubPortal.setPayloadGasLimit(SPOKE_CHAIN_ID, PayloadType.Index, INDEX_UPDATE_GAS_LIMIT);
        hubPortal.setPayloadGasLimit(SPOKE_CHAIN_ID, PayloadType.Key, KEY_UPDATE_GAS_LIMIT);
        hubPortal.setPayloadGasLimit(SPOKE_CHAIN_ID, PayloadType.List, LIST_UPDATE_GAS_LIMIT);
        vm.stopPrank();

        vm.deal(owner, 1 ether);
        vm.deal(user, 1 ether);
    }

    ///////////////////////////////////////////////////////////////////////////
    //                              CONSTRUCTOR                              //
    ///////////////////////////////////////////////////////////////////////////

    function test_constructor_initialState() external {
        assertEq(address(hubPortal.mToken()), address(mToken));
        assertEq(address(hubPortal.registrar()), address(registrar));
        assertEq(address(hubPortal.bridge()), address(bridge));
        assertEq(address(hubPortal.owner()), owner);
        assertEq(address(hubPortal.pauser()), owner);
        assertEq(hubPortal.disableEarningIndex(), IndexingMath.EXP_SCALED_ONE);
        assertEq(hubPortal.wasEarningEnabled(), false);
    }

    function test_constructor_zeroMToken() external {
        vm.expectRevert(IPortal.ZeroMToken.selector);
        new HubPortal(address(0), address(registrar));
    }

    function test_constructor_zeroRegistrar() external {
        vm.expectRevert(IPortal.ZeroRegistrar.selector);
        new HubPortal(address(mToken), address(0));
    }

    ///////////////////////////////////////////////////////////////////////////
    //                              initialize                               //
    ///////////////////////////////////////////////////////////////////////////

    function test_initialize_zeroBridge() external {
        vm.expectRevert(IPortal.ZeroBridge.selector);
        new ERC1967Proxy(address(implementation), abi.encodeWithSelector(IPortal.initialize.selector, address(0), owner, owner));
    }

    function test_initialize_zeroOwner() external {
        vm.expectRevert(abi.encodeWithSelector(OwnableUpgradeable.OwnableInvalidOwner.selector, address(0)));
        new ERC1967Proxy(
            address(implementation), abi.encodeWithSelector(IPortal.initialize.selector, address(bridge), address(0), owner)
        );
    }

    function test_initialize_zeroPauser() external {
        vm.expectRevert(IPausableOwnable.ZeroPauser.selector);
        new ERC1967Proxy(
            address(implementation), abi.encodeWithSelector(IPortal.initialize.selector, address(bridge), owner, address(0))
        );
    }

    ///////////////////////////////////////////////////////////////////////////
    //                               setBridge                               //
    ///////////////////////////////////////////////////////////////////////////

    function test_setBridge() public {
        address newBridge_ = makeAddr("new bridge");
        address currentBridge_ = address(bridge);

        vm.expectEmit(true, true, true, true);
        emit IPortal.BridgeSet(currentBridge_, newBridge_);

        vm.prank(owner);
        hubPortal.setBridge(newBridge_);

        assertEq(hubPortal.bridge(), newBridge_);
    }

    function test_setBridge_zeroBridge() public {
        vm.prank(owner);
        vm.expectRevert(IPortal.ZeroBridge.selector);

        hubPortal.setBridge(address(0));
    }

    function test_setBridge_notOwner() public {
        vm.prank(user);
        vm.expectRevert(abi.encodeWithSelector(OwnableUpgradeable.OwnableUnauthorizedAccount.selector, user));

        hubPortal.setBridge(makeAddr("new bridge"));
    }

    ///////////////////////////////////////////////////////////////////////////
    //                          setDestinationMToken                         //
    ///////////////////////////////////////////////////////////////////////////

    function test_setDestinationMToken() public {
        address destinationMToken_ = makeAddr("mToken");
        uint256 destinationChainId_ = 222;

        vm.expectEmit(true, true, true, true);
        emit IPortal.DestinationMTokenSet(destinationChainId_, destinationMToken_);

        vm.prank(owner);
        hubPortal.setDestinationMToken(destinationChainId_, destinationMToken_);

        assertEq(hubPortal.destinationMToken(destinationChainId_), destinationMToken_);
    }

    function test_setDestinationMToken_invalidDestinationChain() public {
        address destinationMToken_ = makeAddr("mToken");
        uint256 destinationChainId_ = block.chainid;

        vm.prank(owner);
        vm.expectRevert(abi.encodeWithSelector(IPortal.InvalidDestinationChain.selector, destinationChainId_));

        hubPortal.setDestinationMToken(destinationChainId_, destinationMToken_);
    }

    function test_setDestinationMToken_zeroMToken() public {
        vm.prank(owner);
        vm.expectRevert(IPortal.ZeroMToken.selector);

        hubPortal.setDestinationMToken(SPOKE_CHAIN_ID, address(0));
    }

    function test_setDestinationMToken_notOwner() external {
        vm.prank(user);
        vm.expectRevert(abi.encodeWithSelector(OwnableUpgradeable.OwnableUnauthorizedAccount.selector, user));

        hubPortal.setDestinationMToken(SPOKE_CHAIN_ID, spokeMToken);
    }

    ///////////////////////////////////////////////////////////////////////////
    //                        setSupportedBridgingPath                       //
    ///////////////////////////////////////////////////////////////////////////

    function test_setSupportedBridgingPath() external {
        address hubMToken_ = address(mToken);
        address spokeMToken_ = makeAddr("mToken");

        // Support path
        vm.expectEmit(true, true, true, true);
        emit IPortal.SupportedBridgingPathSet(hubMToken_, SPOKE_CHAIN_ID, spokeMToken_, true);
        vm.prank(owner);
        hubPortal.setSupportedBridgingPath(hubMToken_, SPOKE_CHAIN_ID, spokeMToken_, true);

        assertTrue(hubPortal.supportedBridgingPath(hubMToken_, SPOKE_CHAIN_ID, spokeMToken_));

        // Don't support path
        vm.expectEmit(true, true, true, true);
        emit IPortal.SupportedBridgingPathSet(hubMToken_, SPOKE_CHAIN_ID, spokeMToken_, false);
        vm.prank(owner);
        hubPortal.setSupportedBridgingPath(hubMToken_, SPOKE_CHAIN_ID, spokeMToken_, false);

        assertFalse(hubPortal.supportedBridgingPath(hubMToken_, SPOKE_CHAIN_ID, spokeMToken_));
    }

    function test_setSupportedBridgingPath_zeroSourceToken() external {
        vm.prank(owner);
        vm.expectRevert(IPortal.ZeroSourceToken.selector);
        hubPortal.setSupportedBridgingPath(address(0), SPOKE_CHAIN_ID, spokeMToken, true);
    }

    function test_setSupportedBridgingPath_invalidDestinationChain() external {
        uint256 localChainId = block.chainid;
        vm.prank(owner);
        vm.expectRevert(abi.encodeWithSelector(IPortal.InvalidDestinationChain.selector, localChainId));
        hubPortal.setSupportedBridgingPath(address(mToken), localChainId, spokeMToken, true);
    }

    function test_setSupportedBridgingPath_zeroDestinationToken() external {
        vm.prank(owner);
        vm.expectRevert(IPortal.ZeroDestinationToken.selector);
        hubPortal.setSupportedBridgingPath(address(mToken), SPOKE_CHAIN_ID, address(0), true);
    }

    function test_setSupportedBridgingPath_notOwner() external {
        vm.prank(user);
        vm.expectRevert(abi.encodeWithSelector(OwnableUpgradeable.OwnableUnauthorizedAccount.selector, user));
        hubPortal.setSupportedBridgingPath(address(mToken), SPOKE_CHAIN_ID, spokeMToken, false);
    }

    ///////////////////////////////////////////////////////////////////////////
    //                           setPayloadGasLimit                          //
    ///////////////////////////////////////////////////////////////////////////

    function test_setPayloadGasLimit() public {
        PayloadType payloadType_ = PayloadType.Token;
        uint256 gasLimit_ = 200_000;

        vm.expectEmit(true, true, true, true);
        emit IPortal.PayloadGasLimitSet(SPOKE_CHAIN_ID, payloadType_, gasLimit_);

        vm.prank(owner);
        hubPortal.setPayloadGasLimit(SPOKE_CHAIN_ID, payloadType_, gasLimit_);

        assertEq(hubPortal.payloadGasLimit(SPOKE_CHAIN_ID, payloadType_), gasLimit_);
    }

    function test_setPayloadGasLimit_notOwner() public {
        vm.prank(user);
        vm.expectRevert(abi.encodeWithSelector(OwnableUpgradeable.OwnableUnauthorizedAccount.selector, user));

        hubPortal.setPayloadGasLimit(SPOKE_CHAIN_ID, PayloadType.Token, 200_000);
    }

    ///////////////////////////////////////////////////////////////////////////
    //                             enableEarning                             //
    ///////////////////////////////////////////////////////////////////////////

    function test_enableEarning() external {
        uint128 currentMIndex_ = 1_100000068703;

        mToken.setCurrentIndex(currentMIndex_);
        registrar.set(EARNERS_LIST_IGNORED, bytes32("1"));

        vm.expectEmit();
        emit IHubPortal.EarningEnabled(currentMIndex_);

        vm.expectCall(address(mToken), abi.encodeCall(IMTokenLike.startEarning, ()));
        hubPortal.enableEarning();
    }

    function test_enableEarning_earningIsEnabled() external {
        registrar.setListContains(EARNERS_LIST, address(hubPortal), true);
        hubPortal.enableEarning();

        vm.expectRevert(IHubPortal.EarningIsEnabled.selector);
        hubPortal.enableEarning();
    }

    function test_enableEarning_earningCannotBeReenabled() external {
        mToken.setCurrentIndex(1_100000068703);

        // enable
        registrar.setListContains(EARNERS_LIST, address(hubPortal), true);
        hubPortal.enableEarning();

        // disable
        registrar.setListContains(EARNERS_LIST, address(hubPortal), false);
        hubPortal.disableEarning();

        // fail to re-enable
        registrar.setListContains(EARNERS_LIST, address(hubPortal), true);
        vm.expectRevert(IHubPortal.EarningCannotBeReenabled.selector);
        hubPortal.enableEarning();
    }

    ///////////////////////////////////////////////////////////////////////////
    //                             disableEarning                            //
    ///////////////////////////////////////////////////////////////////////////

    function test_disableEarning() external {
        uint128 currentMIndex_ = 1_100000068703;

        mToken.setCurrentIndex(currentMIndex_);

        // enable
        registrar.setListContains(EARNERS_LIST, address(hubPortal), true);
        hubPortal.enableEarning();

        // disable
        registrar.setListContains(EARNERS_LIST, address(hubPortal), false);

        vm.expectEmit();
        emit IHubPortal.EarningDisabled(currentMIndex_);

        vm.expectCall(address(mToken), abi.encodeCall(IMTokenLike.stopEarning, (address(hubPortal))));

        hubPortal.disableEarning();
    }

    function test_disableEarning_earningIsDisabled() external {
        vm.expectRevert(IHubPortal.EarningIsDisabled.selector);
        hubPortal.disableEarning();
    }

    ///////////////////////////////////////////////////////////////////////////
    //                             sendMTokenIndex                           //
    ///////////////////////////////////////////////////////////////////////////

    function test_sendMTokenIndex() external {
        uint128 index_ = 1_100000068703;
        uint256 fee_ = 1;
        bytes32 messageId_ = bytes32("id");
        bytes memory payload_ = PayloadEncoder.encodeIndex(index_);

        mToken.setCurrentIndex(index_);
        bridge.setMessageId(messageId_);
        registrar.setListContains(EARNERS_LIST, address(hubPortal), true);
        hubPortal.enableEarning();

        vm.expectCall(
            address(bridge), abi.encodeCall(IBridge.sendMessage, (SPOKE_CHAIN_ID, INDEX_UPDATE_GAS_LIMIT, user, payload_))
        );
        vm.expectEmit();
        emit IHubPortal.MTokenIndexSent(SPOKE_CHAIN_ID, messageId_, index_);

        vm.prank(user);
        hubPortal.sendMTokenIndex{ value: fee_ }(SPOKE_CHAIN_ID, user);
    }

    function test_sendMTokenIndex_zeroRefundAddress() external {
        vm.expectRevert(IPortal.ZeroRefundAddress.selector);

        vm.prank(user);
        hubPortal.sendMTokenIndex(SPOKE_CHAIN_ID, address(0));
    }

    ///////////////////////////////////////////////////////////////////////////
    //                            sendRegistrarKey                           //
    ///////////////////////////////////////////////////////////////////////////

    function test_sendRegistrarKey() external {
        uint256 fee_ = 1;
        bytes32 key_ = bytes32("key");
        bytes32 value_ = bytes32("value");
        bytes32 messageId_ = bytes32("id");
        bytes memory payload_ = PayloadEncoder.encodeKey(key_, value_);

        registrar.set(key_, value_);
        bridge.setMessageId(messageId_);

        vm.expectCall(
            address(bridge), abi.encodeCall(IBridge.sendMessage, (SPOKE_CHAIN_ID, KEY_UPDATE_GAS_LIMIT, user, payload_))
        );
        vm.expectEmit();
        emit IHubPortal.RegistrarKeySent(SPOKE_CHAIN_ID, messageId_, key_, value_);

        vm.prank(user);
        hubPortal.sendRegistrarKey{ value: fee_ }(SPOKE_CHAIN_ID, key_, user);
    }

    function test_sendRegistrarKey_zeroRefundAddress() external {
        vm.expectRevert(IPortal.ZeroRefundAddress.selector);

        vm.prank(user);
        hubPortal.sendRegistrarKey(SPOKE_CHAIN_ID, bytes32("key"), address(0));
    }

    ///////////////////////////////////////////////////////////////////////////
    //                        sendRegistrarListStatus                        //
    ///////////////////////////////////////////////////////////////////////////

    function test_sendRegistrarListStatus() external {
        bytes32 listName_ = bytes32("listName");
        bool status_ = true;
        address account_ = user;
        uint256 fee_ = 1;
        bytes32 messageId_ = bytes32("id");
        bytes memory payload_ = PayloadEncoder.encodeListUpdate(listName_, account_, status_);

        registrar.setListContains(listName_, account_, status_);
        bridge.setMessageId(messageId_);

        vm.expectCall(
            address(bridge), abi.encodeCall(IBridge.sendMessage, (SPOKE_CHAIN_ID, LIST_UPDATE_GAS_LIMIT, user, payload_))
        );
        vm.expectEmit();
        emit IHubPortal.RegistrarListStatusSent(SPOKE_CHAIN_ID, messageId_, listName_, account_, status_);

        vm.prank(user);
        hubPortal.sendRegistrarListStatus{ value: fee_ }(SPOKE_CHAIN_ID, listName_, account_, user);
    }

    function test_sendRegistrarListStatus_zeroRefundAddress() external {
        vm.expectRevert(IPortal.ZeroRefundAddress.selector);

        vm.prank(user);
        hubPortal.sendRegistrarListStatus(SPOKE_CHAIN_ID, bytes32("listName"), user, address(0));
    }

    ///////////////////////////////////////////////////////////////////////////
    //                               transfer                                //
    ///////////////////////////////////////////////////////////////////////////

    function test_transfer() external {
        uint128 index_ = 1_100000068703;
        uint256 amount_ = 1000;
        uint256 fee_ = 1;
        bytes32 messageId_ = bytes32("id");
        address destinationToken_ = spokeMToken;
        address recipient_ = user;
        bytes memory payload_ = PayloadEncoder.encodeTokenTransfer(amount_, destinationToken_, recipient_, index_);

        mToken.mint(user, amount_);

        registrar.setListContains(EARNERS_LIST, address(hubPortal), true);
        hubPortal.enableEarning();

        mToken.setCurrentIndex(index_);
        bridge.setMessageId(messageId_);

        vm.prank(user);
        mToken.approve(address(hubPortal), amount_);

        vm.expectCall(
            address(bridge), abi.encodeCall(IBridge.sendMessage, (SPOKE_CHAIN_ID, TOKEN_TRANSFER_GAS_LIMIT, user, payload_))
        );
        vm.expectEmit();
        emit IPortal.MTokenSent(address(mToken), SPOKE_CHAIN_ID, destinationToken_, user, recipient_, amount_, index_, messageId_);

        vm.prank(user);
        hubPortal.transfer{ value: fee_ }(amount_, SPOKE_CHAIN_ID, recipient_, user);

        // M tokens locked
        assertEq(mToken.balanceOf(address(hubPortal)), amount_);
    }

    function test_transfer_paused() external {
        vm.prank(owner);
        hubPortal.pause();

        vm.expectRevert(PausableUpgradeable.EnforcedPause.selector);
        vm.prank(user);
        hubPortal.transfer{ value: 0 }(1000, SPOKE_CHAIN_ID, user, user);
    }

    function test_transfer_zeroAmount() external {
        uint256 fee_ = 1;
        vm.deal(user, fee_);

        vm.expectRevert(IPortal.ZeroAmount.selector);
        vm.prank(user);
        hubPortal.transfer{ value: fee_ }(0, SPOKE_CHAIN_ID, user, user);
    }

    function test_transfer_zeroRefundAddress() external {
        vm.expectRevert(IPortal.ZeroRefundAddress.selector);
        vm.prank(user);
        hubPortal.transfer{ value: 0 }(1000, SPOKE_CHAIN_ID, user, address(0));
    }

    function test_transfer_zeroDestinationToken() external {
        uint256 destinationChainId_ = 333;

        vm.expectRevert(IPortal.ZeroDestinationToken.selector);
        vm.prank(user);
        hubPortal.transfer{ value: 0 }(1000, destinationChainId_, user, user);
    }

    function test_transfer_zeroRecipient() external {
        vm.expectRevert(IPortal.ZeroRecipient.selector);
        vm.prank(user);
        hubPortal.transfer{ value: 0 }(1000, SPOKE_CHAIN_ID, address(0), user);
    }

    ///////////////////////////////////////////////////////////////////////////
    //                         transferMLikeToken                            //
    ///////////////////////////////////////////////////////////////////////////

    function test_transferMLikeToken() external {
        uint128 index_ = 1_100000068703;
        uint256 amount_ = 1000;
        uint256 fee_ = 1;
        bytes32 messageId_ = bytes32("id");
        address sourceToken_ = address(wrappedMToken);
        address destinationToken_ = spokeMToken;
        address recipient_ = user;
        bytes memory payload_ = PayloadEncoder.encodeTokenTransfer(amount_, destinationToken_, recipient_, index_);

        mToken.mint(user, amount_);
        registrar.setListContains(EARNERS_LIST, address(hubPortal), true);
        hubPortal.enableEarning();

        vm.startPrank(user);
        mToken.approve(address(wrappedMToken), amount_);
        wrappedMToken.wrap(user, amount_);
        vm.stopPrank();

        mToken.setCurrentIndex(index_);
        bridge.setMessageId(messageId_);

        vm.prank(user);
        wrappedMToken.approve(address(hubPortal), amount_);

        vm.expectCall(
            address(bridge), abi.encodeCall(IBridge.sendMessage, (SPOKE_CHAIN_ID, TOKEN_TRANSFER_GAS_LIMIT, user, payload_))
        );
        vm.expectEmit();
        emit IPortal.MTokenSent(sourceToken_, SPOKE_CHAIN_ID, destinationToken_, user, recipient_, amount_, index_, messageId_);

        vm.prank(user);
        hubPortal.transferMLikeToken{ value: fee_ }(amount_, sourceToken_, SPOKE_CHAIN_ID, destinationToken_, recipient_, user);

        // M tokens locked
        assertEq(mToken.balanceOf(address(hubPortal)), amount_);
    }

    ///////////////////////////////////////////////////////////////////////////
    //                           receiveMessage                              //
    ///////////////////////////////////////////////////////////////////////////

    function test_receiveMessage_mToken() external {
        uint128 index_ = 1_100000068703;
        uint256 amount_ = 1000;
        address destinationToken_ = address(mToken);
        address recipient_ = user;
        bytes memory payload_ = PayloadEncoder.encodeTokenTransfer(amount_, destinationToken_, recipient_, index_);

        mToken.setCurrentIndex(index_);
        mToken.mint(user, amount_);
        registrar.setListContains(EARNERS_LIST, address(hubPortal), true);
        hubPortal.enableEarning();

        // Initiate transfer to lock tokens and update bridgedPrincipal value
        vm.startPrank(user);
        mToken.approve(address(hubPortal), amount_);
        hubPortal.transfer{ value: 10 }(amount_, SPOKE_CHAIN_ID, recipient_, user);
        vm.stopPrank();

        assertEq(mToken.balanceOf(address(hubPortal)), amount_);
        assertEq(mToken.balanceOf(user), 0);

        vm.expectEmit();
        emit IPortal.MTokenReceived(SPOKE_CHAIN_ID, destinationToken_, user, recipient_, amount_, index_);

        vm.prank(address(bridge));
        hubPortal.receiveMessage(SPOKE_CHAIN_ID, user, payload_);

        assertEq(mToken.balanceOf(address(hubPortal)), 0);
        assertEq(mToken.balanceOf(user), amount_);
    }

    function test_receiveMessage_wrappedMToken() external {
        uint128 index_ = 1_100000068703;
        uint256 amount_ = 1000;
        address destinationToken_ = address(wrappedMToken);
        address recipient_ = user;
        bytes memory payload_ = PayloadEncoder.encodeTokenTransfer(amount_, destinationToken_, recipient_, index_);

        mToken.setCurrentIndex(index_);
        mToken.mint(user, amount_);
        registrar.setListContains(EARNERS_LIST, address(hubPortal), true);
        hubPortal.enableEarning();

        // Initiate transfer to lock tokens and update bridgedPrincipal value
        vm.startPrank(user);
        mToken.approve(address(hubPortal), amount_);
        hubPortal.transfer{ value: 10 }(amount_, SPOKE_CHAIN_ID, recipient_, user);
        vm.stopPrank();

        assertEq(mToken.balanceOf(address(hubPortal)), amount_);
        assertEq(mToken.balanceOf(user), 0);
        assertEq(wrappedMToken.balanceOf(user), 0);

        vm.expectEmit();
        emit IPortal.MTokenReceived(SPOKE_CHAIN_ID, destinationToken_, user, recipient_, amount_, index_);

        vm.prank(address(bridge));
        hubPortal.receiveMessage(SPOKE_CHAIN_ID, user, payload_);

        assertEq(mToken.balanceOf(address(hubPortal)), 0);
        assertEq(mToken.balanceOf(user), 0);
        assertEq(wrappedMToken.balanceOf(user), amount_);
    }

    function test_receiveMessage_wrapFailed() external {
        uint128 index_ = 1_100000068703;
        uint256 amount_ = 1000;
        address destinationToken_ = spokeMToken;
        address recipient_ = user;
        bytes memory payload_ = PayloadEncoder.encodeTokenTransfer(amount_, destinationToken_, recipient_, index_);

        mToken.setCurrentIndex(index_);
        mToken.mint(user, amount_);
        registrar.setListContains(EARNERS_LIST, address(hubPortal), true);
        hubPortal.enableEarning();

        // Initiate transfer to lock tokens and update bridgedPrincipal value
        vm.startPrank(user);
        mToken.approve(address(hubPortal), amount_);
        hubPortal.transfer{ value: 10 }(amount_, SPOKE_CHAIN_ID, recipient_, user);
        vm.stopPrank();

        assertEq(mToken.balanceOf(address(hubPortal)), amount_);
        assertEq(mToken.balanceOf(user), 0);

        vm.expectEmit();
        emit IPortal.MTokenReceived(SPOKE_CHAIN_ID, destinationToken_, user, recipient_, amount_, index_);
        vm.expectEmit();
        emit IPortal.WrapFailed(destinationToken_, recipient_, amount_);

        vm.prank(address(bridge));
        hubPortal.receiveMessage(SPOKE_CHAIN_ID, user, payload_);

        assertEq(mToken.balanceOf(address(hubPortal)), 0);
        assertEq(mToken.balanceOf(user), amount_);
    }

    function test_receiveMessage_notBridge() external {
        vm.expectRevert(IPortal.NotBridge.selector);
        hubPortal.receiveMessage(SPOKE_CHAIN_ID, user, bytes("payload"));
    }
}
