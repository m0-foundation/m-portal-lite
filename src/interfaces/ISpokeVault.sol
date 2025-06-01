// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.26;

import { IMigratable } from "../../lib/common/src/interfaces/IMigratable.sol";

/**
 * @title  SpokeVault interface.
 * @author M^0 Labs
 */
interface ISpokeVault is IMigratable {
    ///////////////////////////////////////////////////////////////////////////
    //                                 EVENTS                                //
    ///////////////////////////////////////////////////////////////////////////

    /**
     * @notice Emitted when excess M token are sent to the Vault on Ethereum Mainnet.
     * @param  amount    The amount of bridged M tokens.
     * @param  messageId The unique identifier of the message sent.
     */
    event ExcessMTokenSent(uint256 amount, bytes32 messageId);

    ///////////////////////////////////////////////////////////////////////////
    //                             CUSTOM ERRORS                             //
    ///////////////////////////////////////////////////////////////////////////

    /// @notice Thrown when migrate function is called by an account other than the migration admin.
    error UnauthorizedMigration();

    /// @notice Thrown when the HubVault address is 0x0.
    error ZeroHubVault();

    /// @notice Thrown when the SpokePortal address is 0x0.
    error ZeroSpokePortal();

    /// @notice Thrown when the Hub chain is 0.
    error ZeroHubChain();

    /// @notice Thrown in constructor if Migration Admin is 0x0.
    error ZeroMigrationAdmin();

    ///////////////////////////////////////////////////////////////////////////
    //                         INTERACTIVE FUNCTIONS                         //
    ///////////////////////////////////////////////////////////////////////////

    /**
     * @notice Transfers the total excess amount of M in the SpokeVault to the HubVault on Ethereum Mainnet.
     * @param  refundAddress The refund address to receive excess native gas.
     * @return messageId     The unique identifier of the message sent.
     */
    function transferExcessM(address refundAddress) external payable returns (bytes32 messageId);

    /**
     * @notice Performs an arbitrarily defined migration.
     * @param  migrator The address of a migrator contract.
     */
    function migrate(address migrator) external;

    ///////////////////////////////////////////////////////////////////////////
    //                          VIEW/PURE FUNCTIONS                          //
    ///////////////////////////////////////////////////////////////////////////

    /// @notice The account that can call the `migrate(address migrator)` function.
    function migrationAdmin() external view returns (address migrationAdmin);

    /// @notice The EVM chain Id of the Hub chain (Ethereum Mainnet).
    function hubChainId() external view returns (uint256 hubChainId);

    /// @notice The address of the M token.
    function mToken() external view returns (address mToken);

    /// @notice Address of the Vault on the Hub that will receive the excess M.
    function hubVault() external view returns (address hubVault);

    /// @notice Address of the SpokePortal being used to bridge M back to the Hub.
    function spokePortal() external view returns (address spokePortal);
}
