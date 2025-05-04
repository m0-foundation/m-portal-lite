// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.26;

import { IBridge } from "../../../interfaces/IBridge.sol";
import { IMessageRecipient } from "./IMessageRecipient.sol";

interface IHyperlaneBridge is IBridge, IMessageRecipient {
    ///////////////////////////////////////////////////////////////////////////
    //                                 EVENTS                                //
    ///////////////////////////////////////////////////////////////////////////

    /**
     * @notice Emitted when the address of Hyperlane bridge on the remote chain is set.
     * @param  destinationChainId The EVM chain Id of the destination chain.
     * @param  peer               The the address of the bridge contract on the remote chain.
     */
    event PeerSet(uint256 destinationChainId, bytes32 peer);

    ///////////////////////////////////////////////////////////////////////////
    //                             CUSTOM ERRORS                             //
    ///////////////////////////////////////////////////////////////////////////

    /// @notice Thrown when the Hyperlane Mailbox address is 0x0.
    error ZeroMailbox();

    /// @notice Thrown when the remote chain id is 0.
    error ZeroDestinationChain();

    /// @notice Thrown when the remote bridge is 0x0.
    error ZeroPeer();

    /// @notice Thrown when the caller is not the Hyperlane Mailbox.
    error NotMailbox();

    /// @notice Thrown when the destination chain isn't supported.
    error UnsupportedDestinationChain(uint256 destinationChainId);

    /// @notice Thrown when the source chain isn't supported or configured peer doesn't match the sender.
    error UnsupportedSender(bytes32 sender);

    ///////////////////////////////////////////////////////////////////////////
    //                          VIEW/PURE FUNCTIONS                          //
    ///////////////////////////////////////////////////////////////////////////

    /// @notice Returns the address of Hyperlane Mailbox contract.
    function mailbox() external view returns (address);

    /// @notice Returns the address of Hyperlane Bridge contract on the remote chain.
    function peer(uint256 destinationChainId) external view returns (bytes32);

    ///////////////////////////////////////////////////////////////////////////
    //                         INTERACTIVE FUNCTIONS                         //
    ///////////////////////////////////////////////////////////////////////////

    /**
     * @notice Sets an address of Hyperlane Bridge contract on the remote chain.
     * @param  destinationChainId The EVM chain Id of the destination chain.
     * @param  peer               The address of of the bridge contract on the remote chain.
     */
    function setPeer(uint256 destinationChainId, bytes32 peer) external;
}
