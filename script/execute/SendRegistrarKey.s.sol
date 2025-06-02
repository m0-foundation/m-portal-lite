// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.26;

import { ExecuteBase } from "./ExecuteBase.sol";

import { IHubPortal } from "../../src/interfaces/IHubPortal.sol";

contract SendRegistrarKey is ExecuteBase {
    function run() external {
        (address bridge_,, address portal_,,,) = _readDeployment(block.chainid);
        uint256 destinationChainId_ = _promptForDestinationChainId(bridge_);
        bytes32 key_ = vm.parseBytes32(vm.prompt("Enter Registrar key"));
        uint256 fee_ = IHubPortal(portal_).quoteSendRegistrarKey(destinationChainId_, key_);
        address signer_ = vm.rememberKey(vm.envUint("PRIVATE_KEY"));

        vm.startBroadcast(signer_);

        IHubPortal(portal_).sendRegistrarKey{ value: fee_ }(destinationChainId_, key_, signer_);

        vm.stopBroadcast();
    }
}
