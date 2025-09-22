// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.26;

import { IBridge } from "../../../interfaces/IBridge.sol";
import { IMetalayerRecipient } from "./IMetalayerRecipient.sol";

interface IMetalayerBridge is IBridge, IMetalayerRecipient {
    ///////////////////////////////////////////////////////////////////////////
    //                                 EVENTS                                //
    ///////////////////////////////////////////////////////////////////////////

    /**
     * @notice Emitted when the address of Metalayer bridge on the remote chain is set.
     * @param  destinationChainId The EVM chain Id of the destination chain.
     * @param  peer               The address of the bridge contract on the remote chain.
     */
    event PeerSet(uint256 destinationChainId, bytes32 peer);

    /**
     * @notice Emitted when a domain override is set for a chain ID.
     * @param  chainId The EVM chain ID.
     * @param  domain  The custom domain ID to use for this chain.
     */
    event DomainOverrideSet(uint256 chainId, uint32 domain);

    ///////////////////////////////////////////////////////////////////////////
    //                             CUSTOM ERRORS                             //
    ///////////////////////////////////////////////////////////////////////////

    /// @notice Thrown when the Metalayer Router address is 0x0.
    error ZeroRouter();

    /// @notice Thrown when the remote chain id is 0.
    error ZeroDestinationChain();

    /// @notice Thrown when the remote bridge is 0x0.
    error ZeroPeer();

    /// @notice Thrown when the domain is 0.
    error ZeroDomain();

    /// @notice Thrown when the caller is not the Metalayer Router.
    error NotRouter();

    /// @notice Thrown when the destination chain isn't supported.
    error UnsupportedDestinationChain(uint256 destinationChainId);

    /// @notice Thrown when the source chain isn't supported or configured peer doesn't match the sender.
    error UnsupportedSender(bytes32 sender);

    ///////////////////////////////////////////////////////////////////////////
    //                          VIEW/PURE FUNCTIONS                          //
    ///////////////////////////////////////////////////////////////////////////

    /// @notice Returns the address of Metalayer Router contract.
    function router() external view returns (address);

    /// @notice Returns the address of Metalayer Bridge contract on the remote chain.
    function peer(uint256 destinationChainId) external view returns (bytes32);

    /// @notice Returns the custom domain override for a chain ID (0 if not set).
    function domainOverride(uint256 chainId) external view returns (uint32);

    ///////////////////////////////////////////////////////////////////////////
    //                         INTERACTIVE FUNCTIONS                         //
    ///////////////////////////////////////////////////////////////////////////

    /**
     * @notice Sets an address of Metalayer Bridge contract on the remote chain.
     * @param  destinationChainId The EVM chain Id of the destination chain.
     * @param  peer               The address of the bridge contract on the remote chain.
     */
    function setPeer(uint256 destinationChainId, bytes32 peer) external;

    /**
     * @notice Sets a custom domain override for a specific chain ID.
     * @param  chainId The EVM chain ID to set an override for.
     * @param  domain  The custom domain ID to use for this chain.
     */
    function setDomainOverride(uint256 chainId, uint32 domain) external;
}