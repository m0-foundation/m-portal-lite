// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.26;

/**
 * @title IMTokenLike interface
 * @author M^0 Labs
 * @notice  Subset of M Token interface required for Portal contracts.
 */
interface IMTokenLike {
    /**
     * @notice Emitted when there is insufficient balance to decrement from `account`.
     * @param  account     The account with insufficient balance.
     * @param  rawBalance  The raw balance of the account.
     * @param  amount      The amount to decrement the `rawBalance` by.
     */
    error InsufficientBalance(address account, uint256 rawBalance, uint256 amount);

    /// @notice The current index that would be written to storage if `updateIndex` is called.
    function currentIndex() external view returns (uint128);

    /**
     * @notice Checks if account is an earner.
     * @param  account The account to check.
     * @return True if account is an earner, false otherwise.
     */
    function isEarning(address account) external view returns (bool);

    /// @notice Starts earning for caller if allowed by TTG.
    function startEarning() external;

    /// @notice Stops earning for the account.
    function stopEarning(address account) external;
}
