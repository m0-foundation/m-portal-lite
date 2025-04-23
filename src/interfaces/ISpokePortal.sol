// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.26;

import { IPortal } from "./IPortal.sol";

/**
 * @title  SpokePortal interface.
 * @author M^0 Labs
 */
interface ISpokePortal is IPortal {
    ///////////////////////////////////////////////////////////////////////////
    //                                 EVENTS                                //
    ///////////////////////////////////////////////////////////////////////////

    /**
     * @notice Emitted when M Token index is received from Mainnet.
     * @param  index M token index.
     */
    event MTokenIndexReceived(uint128 index);

    /**
     * @notice Emitted when the Registrar key is received from Mainnet.
     * @param  key   The Registrar key of some value.
     * @param  value The value.
     */
    event RegistrarKeyReceived(bytes32 indexed key, bytes32 value);

    /**
     * @notice Emitted when the Registrar list status is received from Mainnet.
     * @param  listName The name of the list.
     * @param  account  The account.
     * @param  status   Indicates if the account is added or removed from the list.
     */
    event RegistrarListStatusReceived(bytes32 indexed listName, address indexed account, bool status);

    ///////////////////////////////////////////////////////////////////////////
    //                             CUSTOM ERRORS                             //
    ///////////////////////////////////////////////////////////////////////////

    /// @notice Thrown when the Hub chain is 0.
    error ZeroHubChain();

    /// @notice Thrown when the destination chain isn't Hub chain.
    error UnsupportedDestinationChain(uint256 destinationChainId);
}
