// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.26;

import { SpokePortal } from "../../src/SpokePortal.sol";

import { Chains } from "../config/Chains.sol";
import { DeployBase } from "./DeployBase.sol";

contract DeploySpokeBase is DeployBase {
    uint64 internal constant _SPOKE_REGISTRAR_NONCE = 7;
    uint64 internal constant _SPOKE_M_TOKEN_NONCE = 8;
    uint64 internal constant _SPOKE_WRAPPED_M_TOKEN_NONCE = 39;
    uint64 internal constant _SPOKE_WRAPPED_M_TOKEN_PROXY_NONCE = 40;

    error DeployerNonceTooHigh();
    error UnexpectedDeployerNonce();

    function _deployRegistrar(address deployer_, uint64 currentNonce_) internal returns (address registrar_) {
        if (currentNonce_ > _SPOKE_REGISTRAR_NONCE) revert DeployerNonceTooHigh();

        while (currentNonce_ < _SPOKE_REGISTRAR_NONCE) {
            payable(deployer_).transfer(0);
            ++currentNonce_;
        }

        if (currentNonce_ != _SPOKE_REGISTRAR_NONCE) revert UnexpectedDeployerNonce();
    }

    function _deployMToken(address deployer_, uint64 currentNonce_, address registrar_) internal returns (address mToken_) {
        if (currentNonce_ != _SPOKE_M_TOKEN_NONCE) revert UnexpectedDeployerNonce();
    }

    function _deploySpokePortal(
        uint256 chainId_,
        address mToken_,
        address registrar_,
        address bridge_,
        address deployer_
    ) internal returns (address portal_) {
        uint256 hubChainId = Chains.getHubChainId(chainId_);
        SpokePortal implementation_ = new SpokePortal(hubChainId, mToken_, registrar_, bridge_, deployer_, deployer_);
        return _deployCreate3Proxy(address(implementation_), _computeSalt(deployer_, _PORTAL_CONTRACT_NAME));
    }

    function _burnNonces(address deployer_, uint64 currentNonce_, uint256 targetNonce) {
        while (currentNonce_ < startNonce_) {
            payable(deployer_).transfer(0);
            ++currentNonce_;
        }
    }
}
