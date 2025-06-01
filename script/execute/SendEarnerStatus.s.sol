// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.26;

import { ExecuteBase } from "./ExecuteBase.sol";

import { IHubPortal } from "../../src/interfaces/IHubPortal.sol";

contract SendEarnerStatus is ExecuteBase {
    bytes32 internal constant _EARNERS_LIST = "earners";

    function run() external {
        (address bridge_,, address portal_,,,) = _readDeployment(block.chainid);
        uint256 destinationChainId_ = _promptForDestinationChainId(bridge_);
        address account_ = vm.parseAddress(vm.prompt("Enter account address"));
        uint256 fee_ = IHubPortal(portal_).quoteSendRegistrarListStatus(destinationChainId_, _EARNERS_LIST, account_);
        address signer_ = vm.rememberKey(vm.envUint("PRIVATE_KEY"));

        vm.startBroadcast(signer_);

        IHubPortal(portal_).sendRegistrarListStatus{ value: fee_ }(destinationChainId_, _EARNERS_LIST, account_, signer_);

        vm.stopBroadcast();
    }
}
