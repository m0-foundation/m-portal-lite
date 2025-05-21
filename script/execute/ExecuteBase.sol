// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.26;

import { IERC20 } from "../../lib/common/src/interfaces/IERC20.sol";

import { IHyperlaneBridge } from "../../src/bridges/hyperlane/interfaces/IHyperlaneBridge.sol";

import { ScriptBase } from "../ScriptBase.sol";

contract ExecuteBase is ScriptBase {
    function _promptForDestinationChainId(address bridge_) internal returns (uint256 destinationChainId_) {
        destinationChainId_ = uint256(vm.parseUint(vm.prompt("Enter EVM destination chain ID")));

        if (IHyperlaneBridge(bridge_).peer(destinationChainId_) == bytes32(0)) {
            revert("Unsupported destination chain");
        }
    }

    function _promptForTransferAmount(address mToken_, address account_) internal returns (uint256 amount_) {
        uint256 balance_ = IERC20(mToken_).balanceOf(account_);
        amount_ = vm.parseUint(vm.prompt("Enter amount to transfer"));

        if (amount_ > balance_) {
            revert("Insufficient balance");
        }
    }
}
