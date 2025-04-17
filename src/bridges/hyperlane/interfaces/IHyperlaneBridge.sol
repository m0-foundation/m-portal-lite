// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.26;

import { IBridge } from "../../../interfaces/IBridge.sol";
import { IMessageRecipient } from "./IMessageRecipient.sol";

interface IHyperlaneBridge is IBridge, IMessageRecipient {
    ///////////////////////////////////////////////////////////////////////////
    //                             CUSTOM ERRORS                             //
    ///////////////////////////////////////////////////////////////////////////

    /// @notice Thrown when the Hyperlane Mailbox address is 0x0.
    error ZeroMailbox();

    /// @notice Thrown when the remote chain id is 0.
    error ZeroRemoteChain();

    /// @notice Thrown when the remote bridge is 0x0.
    error ZeroRemoteBridge();

    /// @notice Thrown when the caller is not the Hyperlane Mailbox.
    error NotMailbox();

    ///////////////////////////////////////////////////////////////////////////
    //                          VIEW/PURE FUNCTIONS                          //
    ///////////////////////////////////////////////////////////////////////////

    /// @notice Returns the address of Hyperlane Mailbox contract.
    function mailbox() external view returns (address);

    /// @notice Returns the address of Hyperlane Bridge contract on the remote chain.
    function remoteBridge() external view returns (bytes32);

    /// @notice Returns the remote chain id.
    function remoteChainId() external view returns (uint32);
}
