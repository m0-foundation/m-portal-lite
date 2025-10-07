// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.26;

import { console } from "../../lib/forge-std/src/console.sol";

import { IPortal } from "../../src/interfaces/IPortal.sol";

import { DeployBase } from "./DeployBase.sol";


contract DeployBridge is DeployBase {
    function run() external {
        address deployer_ = vm.rememberKey(vm.envUint("PRIVATE_KEY"));
        uint256 chainId_ = block.chainid;
        
        console.log("Deployer:", deployer_);

        (address bridge_, address mToken_, address portal_, address registrar_, address vault_, address wrappedMToken_) =
            _readDeployment(chainId_);

        vm.startBroadcast(deployer_);

        //bridge_ = _deployMetalayerBridge(chainId_, deployer_);
        //console.log("Bridge:  ", bridge_);

        IPortal(portal_).setBridge(bridge_);

        vm.stopBroadcast();

        //_writeDeployments(chainId_, bridge_, mToken_, portal_, registrar_, vault_, wrappedMToken_);
    }
}
