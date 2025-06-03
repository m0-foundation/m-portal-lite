// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.26;

import { ERC1967Proxy } from "../../lib/openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

import { Portal } from "../../src/Portal.sol";
import { SpokePortal } from "../../src/SpokePortal.sol";

import { Chains } from "../config/Chains.sol";
import { Migrator } from "./Migrator.sol";
import { ScriptBase } from "../ScriptBase.sol";

abstract contract UpgradeSpokePortalBase is ScriptBase {
    function _upgradeSpokePortal(
        uint256 chainId_,
        address portal_,
        address mToken_,
        address registrar_,
        address bridge_,
        address deployer_
    ) internal {
        SpokePortal implementation_ = new SpokePortal(Chains.getHubChainId(chainId_), mToken_, registrar_);
        Migrator migrator_ = new Migrator(address(implementation_));

        Portal(portal_).migrate(address(migrator_));
    }
}
