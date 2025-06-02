// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.26;

import { IERC20 } from "../../lib/common/src/interfaces/IERC20.sol";

import { IPortal } from "../../src/interfaces/IPortal.sol";

import { ExecuteBase } from "./ExecuteBase.sol";

contract Transfer is ExecuteBase {
    function run() external {
        address signer_ = vm.rememberKey(vm.envUint("PRIVATE_KEY"));
        (address bridge_, address mToken_, address portal_,,,) = _readDeployment(block.chainid);
        uint256 destinationChainId_ = _promptForDestinationChainId(bridge_);
        address recipient_ = signer_;
        address refundAddress_ = recipient_;
        uint256 amount_ = _promptForTransferAmount(mToken_, signer_);
        uint256 fee_ = IPortal(portal_).quoteTransfer(amount_, destinationChainId_, recipient_);

        vm.startBroadcast(signer_);

        IERC20(mToken_).approve(portal_, amount_);
        IPortal(portal_).transfer{ value: fee_ }(amount_, destinationChainId_, recipient_, refundAddress_);

        vm.stopBroadcast();
    }
}
