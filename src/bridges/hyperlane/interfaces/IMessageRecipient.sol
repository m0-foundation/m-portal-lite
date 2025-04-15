// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity >=0.6.11;

/**
 * @title  MessageRecipient
 * @author Hyperlane
 * @dev    Copied from commit:
 *         https://github.com/hyperlane-xyz/hyperlane-monorepo/commit/7309f770ef948211a7bb637e56835f436d14eec7
 */
interface IMessageRecipient {
    /**
     * @dev   Called by Mailbox to deliver the message.
     * @param origin  The origin chain ID.
     * @param sender  The address of sender on origin chain as bytes32
     * @param message The raw bytes content of message body
     */
    function handle(uint32 origin, bytes32 sender, bytes calldata message) external payable;
}
