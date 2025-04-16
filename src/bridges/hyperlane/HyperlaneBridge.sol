// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.26;

import { IBridge } from "../../interfaces/IBridge.sol";
import { IMailbox } from "./interfaces/IMailbox.sol";
import { IMessageRecipient } from "./interfaces/IMessageRecipient.sol";
import { IHyperlaneBridge } from "./interfaces/IHyperlaneBridge.sol";
import { StandardHookMetadata } from "./libs/StandardHookMetadata.sol";
import { IPortal } from "../../interfaces/IPortal.sol";
import { TypeConverter } from "../../libs/TypeConverter.sol";

/// @title  HyperLane Bridge
/// @notice Sends and receives messages to and from a single remote chain using Hyperlane protocol
contract HyperlaneBridge is IHyperlaneBridge {
    using TypeConverter for *;

    /// @inheritdoc IHyperlaneBridge
    address public immutable mailbox;

    /// @inheritdoc IBridge
    address public immutable portal;

    /// @inheritdoc IHyperlaneBridge
    bytes32 public immutable remoteBridge;

    /// @inheritdoc IHyperlaneBridge
    uint32 public immutable remoteChainId;

    /*
     * @notice Constructs Hyperlane Bridge
     * @param mailbox_       The address of the Hyperlane Mailbox.
     * @param portal_        The address of the Portal on the current chain.
     * @param remoteBridge_  The address of the Hyperlane Bridge on the remote chain.
     * @param remoteChainId_ The remote chain id.
    */
    constructor(address mailbox_, address portal_, address remoteBridge_, uint32 remoteChainId_) {
        if ((mailbox = mailbox_) == address(0)) revert ZeroMailbox();
        if ((portal = portal_) == address(0)) revert ZeroPortal();
        if ((remoteBridge = remoteBridge_.toBytes32()) == bytes32(0)) revert ZeroRemoteBridge();
        if ((remoteChainId = remoteChainId_) == uint32(0)) revert ZeroRemoteChain();
    }

    /// @inheritdoc IBridge
    function quote(uint256 gasLimit_, bytes memory payload_) external view returns (uint256 fee_) {
        bytes memory metadata_ = StandardHookMetadata.overrideGasLimit(gasLimit_);
        return IMailbox(mailbox).quoteDispatch(remoteChainId, remoteBridge, payload_, metadata_);
    }

    /// @inheritdoc IBridge
    function sendMessage(
        uint256 gasLimit_,
        address refundAddress_,
        bytes memory payload_
    ) external payable returns (bytes32 messageId_) {
        if (msg.sender != portal) revert NotPortal();

        IMailbox mailbox_ = IMailbox(mailbox);
        bytes memory metadata_ = StandardHookMetadata.formatMetadata(0, gasLimit_, refundAddress_, "");

        // NOTE: The transaction reverts if mgs.value isn't enough to cover the fee.
        // If msg.value is greater than the required fee, the excess is sent to the refund address.
        messageId_ = mailbox_.dispatch{ value: msg.value }(remoteChainId, remoteBridge, payload_, metadata_);
    }

    /// @inheritdoc IMessageRecipient
    function handle(uint32, bytes32 sender_, bytes calldata payload_) external payable {
        if (msg.sender != mailbox) revert NotMailbox();
        IPortal(portal).receiveMessage(sender_.toAddress(), payload_);
    }
}
