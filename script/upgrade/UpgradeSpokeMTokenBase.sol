// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.26;

import { ContractHelper } from "../../lib/common/src/libs/ContractHelper.sol";

import { ERC1967Proxy } from "../../lib/openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

import { MToken } from "../../lib/protocol/src/MToken.sol";

import { Migrator } from "./Migrator.sol";
import { ScriptBase } from "../ScriptBase.sol";

abstract contract UpgradeSpokeMTokenBase is ScriptBase {
    function _upgradeSpokeMToken(
        address mToken_,
        address portal_,
        address registrar_,
        address migrationAdmin_
    ) internal {
        MToken implementation_ = new MToken(registrar_, portal_, migrationAdmin_);
        Migrator migrator_ = new Migrator(address(implementation_));

        MToken(mToken_).migrate(address(migrator_));
    }
}
