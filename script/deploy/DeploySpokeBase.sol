// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.26;

import { ERC1967Proxy } from "../../lib/openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import { ContractHelper } from "../../lib/common/src/libs/ContractHelper.sol";
import { MToken } from "../../lib/protocol/src/MToken.sol";
import { Registrar } from "../../lib/ttg/src/Registrar.sol";

import { IPortal } from "../../src/interfaces/IPortal.sol";
import { SpokePortal } from "../../src/SpokePortal.sol";

import { Chains } from "../config/Chains.sol";
import { DeployBase } from "./DeployBase.sol";

contract DeploySpokeBase is DeployBase {
    uint64 internal constant _SPOKE_M_TOKEN_IMPLEMENTATION_NONCE = 6;
    uint64 internal constant _SPOKE_REGISTRAR_NONCE = 7;
    uint64 internal constant _SPOKE_M_TOKEN_NONCE = 8;
    uint64 internal constant _SPOKE_WRAPPED_M_TOKEN_IMPLEMENTATION_NONCE = 39;
    uint64 internal constant _SPOKE_WRAPPED_M_TOKEN_NONCE = 40;

    address internal constant _EXPECTED_WRAPPED_M_TOKEN_ADDRESS = 0x437cc33344a0B27A429f795ff6B469C72698B291;

    error DeployerNonceTooHigh();
    error UnexpectedDeployerNonce();

    function _deployMTokenImplementation(
        address migrationAdmin_,
        address deployer_,
        uint64 currentNonce_
    ) internal returns (address registrar_) {
        if (currentNonce_ > _SPOKE_M_TOKEN_IMPLEMENTATION_NONCE) revert DeployerNonceTooHigh();

        while (currentNonce_ < _SPOKE_M_TOKEN_IMPLEMENTATION_NONCE) {
            payable(deployer_).transfer(0);
            ++currentNonce_;
        }

        if (currentNonce_ != _SPOKE_M_TOKEN_IMPLEMENTATION_NONCE) revert UnexpectedDeployerNonce();

        address registrarAddress_ = ContractHelper.getContractFrom(deployer_, _SPOKE_REGISTRAR_NONCE);

        return address(new MToken(registrarAddress_, _computePortalAddress(deployer_), migrationAdmin_));
    }

    function _deployRegistrar(address deployer_, uint64 currentNonce_) internal returns (address registrar_) {
        if (currentNonce_ != _SPOKE_REGISTRAR_NONCE) revert UnexpectedDeployerNonce();
        return address(new Registrar(_computePortalAddress(deployer_)));
    }

    function _deployMToken(uint64 currentNonce_, address implementation_) internal returns (address mToken_) {
        if (currentNonce_ != _SPOKE_M_TOKEN_NONCE) revert UnexpectedDeployerNonce();
        return address(new ERC1967Proxy(implementation_, abi.encodeCall(MToken.initialize, ())));
    }

    function _deploySpokePortal(
        uint256 chainId_,
        address mToken_,
        address registrar_,
        address bridge_,
        address deployer_
    ) internal returns (address portal_) {
        uint256 hubChainId = Chains.getHubChainId(chainId_);
        SpokePortal implementation_ = new SpokePortal(hubChainId, mToken_, registrar_);
        bytes memory initializeCall = abi.encodeCall(IPortal.initialize, (bridge_, deployer_, deployer_));
        return _deployCreate3Proxy(address(implementation_), _computeSalt(deployer_, _PORTAL_CONTRACT_NAME), initializeCall);
    }

    function _deployVault(
        address deployer_,
        address spokePortal_,
        address hubVault_,
        uint256 hubChainId_,
        address migrationAdmin_
    ) internal returns (address spokeVaultImplementation_, address spokeVaultProxy_) {
        spokeVaultImplementation_ = address(new SpokeVault(spokePortal_, hubVault_, hubChainId_, migrationAdmin_));

        spokeVaultProxy_ =
            _deployCreate3Proxy(address(spokeVaultImplementation_), _computeSalt(deployer_, _VAULT_CONTRACT_NAME), "");
    }

    function _deployWrappedMToken(
        address deployer_,
        address mToken_,
        address registrar_,
        address vault_,
        address migrationAdmin_
    ) internal returns (address wrappedMTokenImplementation_, address wrappedMTokenProxy_) {
        uint64 deployerNonce_ = vm.getNonce(deployer_);

        if (currentNonce_ > _SPOKE_WRAPPED_M_TOKEN_IMPLEMENTATION_NONCE) revert DeployerNonceTooHigh();

        while (currentNonce_ < _SPOKE_WRAPPED_M_TOKEN_IMPLEMENTATION_NONCE) {
            payable(deployer_).transfer(0);
            ++currentNonce_;
        }

        if (currentNonce_ != _SPOKE_WRAPPED_M_TOKEN_IMPLEMENTATION_NONCE) revert UnexpectedDeployerNonce();

        wrappedMTokenImplementation_ = address(new WrappedMToken(mToken_, registrar_, vault_, migrationAdmin_));

        deployerNonce_ = vm.getNonce(deployer_);
        if (deployerNonce_ != _SPOKE_WRAPPED_M_TOKEN_NONCE) revert DeployerNonceTooHigh();

        wrappedMTokenProxy_ = address(new ERC1967Proxy(spokeWrappedMTokenImplementation_), "");

        if (wrappedMTokenProxy_ != _EXPECTED_WRAPPED_M_TOKEN_ADDRESS) {
            revert ExpectedAddressMismatch(expectedWrappedMTokenProxy_, spokeWrappedMTokenProxy_);
        }
    }
}
