// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.26;

import { Script } from "../lib/forge-std/src/Script.sol";

contract ScriptBase is Script {
    struct Deployment {
        address bridge;
        address mToken;
        address portal;
        address registrar;
        address vault;
        address wrappedM;
    }

    function _deployOutputPath(uint256 chainId_) internal view returns (string memory) {
        return string.concat(vm.projectRoot(), "/deployments/", vm.toString(chainId_), ".json");
    }

    function _writeDeployments(
        uint256 chainId_,
        address bridge_,
        address mToken_,
        address portal_,
        address registrar_,
        address vault_,
        address wrappedMToken_
    ) internal {
        string memory root = "";

        vm.serializeAddress(root, "bridge", bridge_);
        vm.serializeAddress(root, "m_token", mToken_);
        vm.serializeAddress(root, "portal", portal_);
        vm.serializeAddress(root, "registrar", registrar_);
        vm.serializeAddress(root, "vault", vault_);
        vm.writeJson(vm.serializeAddress(root, "wrapped_m", wrappedMToken_), _deployOutputPath(chainId_));
    }

    function _readDeployment(uint256 chainId_)
        internal
        returns (address bridge_, address mToken_, address portal_, address registrar_, address vault_, address wrappedMToken_)
    {
        if (!vm.isFile(_deployOutputPath(chainId_))) {
            revert("Deployment artifacts not found");
        }

        bytes memory data = vm.parseJson(vm.readFile(_deployOutputPath(chainId_)));
        Deployment memory deployment_ = abi.decode(data, (Deployment));
        return (
            deployment_.bridge,
            deployment_.mToken,
            deployment_.portal,
            deployment_.registrar,
            deployment_.vault,
            deployment_.wrappedM
        );
    }
}
