// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.26;

import { ExecuteBase } from "./ExecuteBase.sol";

import { IHubPortal } from "../../src/interfaces/IHubPortal.sol";

contract SendMTokenIndex is ExecuteBase {
    function run() external {
        (address bridge_,, address portal_,) = _readDeployment(block.chainid);
        uint256 destinationChainId_ = _promptForDestinationChainId(bridge_);
        uint256 fee_ = IHubPortal(portal_).quoteSendIndex(destinationChainId_);
        address signer_ = vm.rememberKey(vm.envUint("PRIVATE_KEY"));

        vm.startBroadcast(signer_);

        IHubPortal(portal_).sendMTokenIndex{ value: fee_ }(destinationChainId_, signer_);

        vm.stopBroadcast();
    }
}
