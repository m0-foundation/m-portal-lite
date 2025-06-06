// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.26;

import { Chains } from "./Chains.sol";

library HyperlaneConfig {
    /**
     * @notice Returns the address of Hyperlane Mailbox contract
     * @dev    https://docs.hyperlane.xyz/docs/reference/addresses/mailbox-addresses
     * @param  chainId_ EVM chain id.
     * @return mailbox_ The address of Hyperlane Mailbox contract.
     */
    function getMailbox(uint256 chainId_) internal pure returns (address mailbox_) {
        // Mainnet
        if (chainId_ == Chains.ETHEREUM) return 0xc005dc82818d67AF737725bD4bf75435d065D239;
        if (chainId_ == Chains.HYPER_EVM) return 0x3a464f746D23Ab22155710f44dB16dcA53e0775E;
        if (chainId_ == Chains.PLUME) return 0x3a464f746D23Ab22155710f44dB16dcA53e0775E;

        // Testnet
        if (chainId_ == Chains.ETHEREUM_SEPOLIA) return 0xfFAEF09B3cd11D9b20d1a19bECca54EEC2884766;
        if (chainId_ == Chains.HYPER_EVM_TESTNET) return 0x589C201a07c26b4725A4A829d772f24423da480B;
        if (chainId_ == Chains.PLUME_TESTNET) return 0xDDcFEcF17586D08A5740B7D91735fcCE3dfe3eeD;

        revert Chains.UnsupportedChain(chainId_);
    }
}
