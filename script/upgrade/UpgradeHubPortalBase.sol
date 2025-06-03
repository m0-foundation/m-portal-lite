// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.26;

import { ERC1967Proxy } from "../../lib/openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

import { HubPortal } from "../../src/HubPortal.sol";

import { Migrator } from "./Migrator.sol";
import { ScriptBase } from "../ScriptBase.sol";

abstract contract UpgradeHubPortalBase is ScriptBase {
    function _upgradeHubPortal(address portal_, address mToken_, address registrar_, address deployer_) internal {
        HubPortal implementation_ = new HubPortal(mToken_, registrar_);
        Migrator migrator_ = new Migrator(address(implementation_));

        HubPortal(portal_).migrate(address(migrator_));
    }
}
