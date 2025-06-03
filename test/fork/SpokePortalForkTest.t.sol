// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.26;

import { Test } from "../../lib/forge-std/src/Test.sol";

import { IERC20 } from "../../lib/common/src/interfaces/IERC20.sol";
import { IndexingMath } from "../../lib/common/src/libs/IndexingMath.sol";
import { ERC1967Proxy } from "../../lib/openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

import { UpgradeSpokePortalBase } from "../../script/upgrade/UpgradeSpokePortalBase.sol";

import { IPortal } from "../../src/interfaces/IPortal.sol";
import { IMTokenLike } from "../../src/interfaces/IMTokenLike.sol";
import { IRegistrarLike } from "../../src/interfaces/IRegistrarLike.sol";
import { SpokePortal } from "../../src/SpokePortal.sol";
import { HyperlaneBridge } from "../../src/bridges/hyperlane/HyperlaneBridge.sol";
import { PayloadEncoder } from "../../src/libs/PayloadEncoder.sol";
import { TypeConverter } from "../../src/libs/TypeConverter.sol";

contract SpokePortalForkTest is Test, UpgradeSpokePortalBase {
    uint256 public constant ETHEREUM_CHAIN_ID = 1;
    uint256 public constant HYPEREVM_CHAIN_ID = 999;

    address public constant DEPLOYER = 0xF2f1ACbe0BA726fEE8d75f3E32900526874740BB;

    // The same addresses on Hyperevm and Ethereum
    address public constant PORTAL = 0x36f586A30502AE3afb555b8aA4dCc05d233c2ecE;
    address public constant REGISTRAR = 0x119FbeeDD4F4f4298Fb59B720d5654442b81ae2c;
    address public constant M_TOKEN = 0x866A2BF4E572CbcF37D5071A7a58503Bfb36be1b;
    address public constant WRAPPED_M_TOKEN = 0x437cc33344a0B27A429f795ff6B469C72698B291;

    address public constant USDHL = 0xb50A96253aBDF803D85efcDce07Ad8becBc52BD5;
    address public constant USDHL_HOLDER = 0x77BAB32F75996de8075eBA62aEa7b1205cf7E004;
    uint256 public constant HYPEREVM_FORK_BLOCK = 4_761_570;

    uint256 public constant TOKEN_TRANSFER_GAS_LIMIT = 250_000;

    function setUp() external {
        vm.createSelectFork({ urlOrAlias: "hyperevm", blockNumber: HYPEREVM_FORK_BLOCK });

        vm.deal(USDHL_HOLDER, 1 ether);
    }

    function test_transferUSDHL_reverts() external {
        uint256 amount = 1000;
        uint256 fee = IPortal(PORTAL).quoteTransfer(amount, ETHEREUM_CHAIN_ID, USDHL_HOLDER);

        vm.startPrank(USDHL_HOLDER);

        IERC20(USDHL).approve(PORTAL, amount);

        // Reverts due to difference in unwrap function signature used by USDHL and Portal
        vm.expectRevert();
        IPortal(PORTAL).transferMLikeToken{ value: fee }(amount, USDHL, ETHEREUM_CHAIN_ID, M_TOKEN, USDHL_HOLDER, USDHL_HOLDER);

        vm.stopPrank();
    }

    function test_upgradePortal_transferUSDHL() external {
        vm.startPrank(DEPLOYER);
        _upgradeSpokePortal(HYPEREVM_CHAIN_ID, PORTAL, M_TOKEN, REGISTRAR, DEPLOYER);
        vm.stopPrank();

        uint256 amount = 100;
        uint256 fee = IPortal(PORTAL).quoteTransfer(amount, ETHEREUM_CHAIN_ID, USDHL_HOLDER);

        vm.startPrank(USDHL_HOLDER);

        // Transfer USDHL that uses unwrap() function without return value
        IERC20(USDHL).approve(PORTAL, amount);
        IPortal(PORTAL).transferMLikeToken{ value: fee }(amount, USDHL, ETHEREUM_CHAIN_ID, M_TOKEN, USDHL_HOLDER, USDHL_HOLDER);

        // Transfer wM that uses unwrap() function with return value
        IERC20(WRAPPED_M_TOKEN).approve(PORTAL, amount);
        IPortal(PORTAL).transferMLikeToken{ value: fee }(
            amount, WRAPPED_M_TOKEN, ETHEREUM_CHAIN_ID, M_TOKEN, USDHL_HOLDER, USDHL_HOLDER
        );

        vm.stopPrank();
    }
}
