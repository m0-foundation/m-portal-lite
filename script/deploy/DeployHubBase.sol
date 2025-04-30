// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.26;

import { HubPortal } from "../../src/HubPortal.sol";
import { DeployBase } from "./DeployBase.sol";

contract DeployHubBase is DeployBase {
    address internal constant _M_TOKEN = 0x866A2BF4E572CbcF37D5071A7a58503Bfb36be1b;
    address internal constant _REGISTRAR = 0x119FbeeDD4F4f4298Fb59B720d5654442b81ae2c;

    function _deployHubPortal(address bridge_, address deployer_) internal returns (address portal_) {
        HubPortal implementation_ = new HubPortal(_M_TOKEN, _REGISTRAR, bridge_, deployer_, deployer_);
        return _deployCreate3Proxy(address(implementation_), _computeSalt(deployer_, _PORTAL_CONTRACT_NAME));
    }
}
