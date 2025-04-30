// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.26;

import { Script } from "../lib/forge-std/src/Script.sol";

contract ScriptBase is Script {
    struct Deployment {
        address mToken;
        address portal;
        address registrar;
        address transceiver;
        address vault;
        address wrappedMToken;
    }

    function _deployOutputPath(uint256 chainId_) internal view returns (string memory) {
        return string.concat(vm.projectRoot(), "/deployments/", vm.toString(chainId_), ".json");
    }

    function _readDeployment(uint256 chainId_)
        internal
        returns (
            address mToken_,
            address portal_,
            address registrar_,
            address transceiver_,
            address vault_,
            address wrappedMToken_
        )
    {
        if (!vm.isFile(_deployOutputPath(chainId_))) {
            revert("Deployment artifacts not found");
        }

        bytes memory data = vm.parseJson(vm.readFile(_deployOutputPath(chainId_)));
        Deployment memory deployment_ = abi.decode(data, (Deployment));
        return (
            deployment_.mToken,
            deployment_.portal,
            deployment_.registrar,
            deployment_.transceiver,
            deployment_.vault,
            deployment_.wrappedMToken
        );
    }
}
