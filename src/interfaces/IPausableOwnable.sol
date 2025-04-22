// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.26;

interface IPausableOwnable {
    ///////////////////////////////////////////////////////////////////////////
    //                                 EVENTS                                //
    ///////////////////////////////////////////////////////////////////////////

    /**
     * @notice Emitted when the pauser role is transferred.
     * @param previousPauser The previous pauser.
     * @param newPauser      The new pauser.
     */
    event PauserTransferred(address indexed previousPauser, address indexed newPauser);

    /// @notice Emitted when the pause is triggered.
    event Paused();

    /// @notice Emitted when the pause is lifted.
    event Unpaused();

    ///////////////////////////////////////////////////////////////////////////
    //                             CUSTOM ERRORS                             //
    ///////////////////////////////////////////////////////////////////////////

    /// @notice Thrown when the pauser address is 0x0.
    error ZeroPauser();

    /**
     * @notice Thrown when the caller account is not authorized to perform an operation.
     * @param  account The caller.
     */
    error Unauthorized(address account);

    /// @notice Thrown when calling a function isn't allowed when the contract is paused.
    error OperationPaused();

    /// @notice Thrown when calling `pause()` function if the contract is already paused.
    error AlreadyPaused();

    /// @notice Thrown when calling `unpause()` function if the contract isn't paused.
    error NotPaused();

    ///////////////////////////////////////////////////////////////////////////
    //                          VIEW/PURE FUNCTIONS                          //
    ///////////////////////////////////////////////////////////////////////////

    /// @notice Returns the address of the pauser.
    function pauser() external view returns (address);

    /// @notice Returns `true` if the contract is paused, and `false` otherwise.
    function paused() external view returns (bool);

    ///////////////////////////////////////////////////////////////////////////
    //                         INTERACTIVE FUNCTIONS                         //
    ///////////////////////////////////////////////////////////////////////////

    /**
     * @notice Transfers the pauser role to new address
     * @param newPauser Address of the new pauser
     */
    function transferPauserRole(address newPauser) external;

    /**
     * @notice Triggers the paused state.
     * @dev    The contract must not be paused.
     */
    function pause() external;

    /**
     * @notice Returns to normal state.
     * @dev    The contract must be paused.
     */
    function unpause() external;
}
