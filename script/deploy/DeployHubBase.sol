// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.26;

import { IPortal } from "../../src/interfaces/IPortal.sol";
import { HubPortal } from "../../src/HubPortal.sol";

import { DeployBase } from "./DeployBase.sol";

contract DeployHubBase is DeployBase {
    address internal constant _M_TOKEN = 0x866A2BF4E572CbcF37D5071A7a58503Bfb36be1b;
    address internal constant _REGISTRAR = 0x119FbeeDD4F4f4298Fb59B720d5654442b81ae2c;
    address internal constant _WRAPPED_M_TOKEN = 0x437cc33344a0B27A429f795ff6B469C72698B291;
    address internal constant _VAULT = 0xd7298f620B0F752Cf41BD818a16C756d9dCAA34f;

    function _deployHubPortal(address bridge_, address deployer_) internal returns (address portal_) {
        HubPortal implementation_ = new HubPortal(_M_TOKEN, _REGISTRAR);
        bytes memory initializeCall = abi.encodeWithSelector(IPortal.initialize.selector, bridge_, deployer_, deployer_);
        return _deployCreate3Proxy(address(implementation_), _computeSalt(deployer_, _PORTAL_CONTRACT_NAME), initializeCall);
    }
}
