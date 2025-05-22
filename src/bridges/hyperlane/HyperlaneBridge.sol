// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.26;

import { Ownable } from "../../../lib/openzeppelin/contracts/access/Ownable.sol";
import { SafeCast } from "../../../lib/openzeppelin/contracts/utils/math/SafeCast.sol";

import { IBridge } from "../../interfaces/IBridge.sol";
import { IMailbox } from "./interfaces/IMailbox.sol";
import { IMessageRecipient } from "./interfaces/IMessageRecipient.sol";
import { IHyperlaneBridge } from "./interfaces/IHyperlaneBridge.sol";
import { StandardHookMetadata } from "./libs/StandardHookMetadata.sol";
import { IPortal } from "../../interfaces/IPortal.sol";
import { TypeConverter } from "../../libs/TypeConverter.sol";

/// @title  HyperLane Bridge
/// @notice Sends and receives messages to and from remote chains using Hyperlane protocol
contract HyperlaneBridge is Ownable, IHyperlaneBridge {
    using TypeConverter for *;
    using SafeCast for uint256;

    /// @inheritdoc IHyperlaneBridge
    address public immutable mailbox;

    /// @inheritdoc IBridge
    address public immutable portal;

    /// @inheritdoc IHyperlaneBridge
    mapping(uint256 destinationChainId => bytes32 destinationPeer) public peer;

    /**
     * @notice Constructs Hyperlane Bridge
     * @param mailbox_ The address of the Hyperlane Mailbox.
     * @param portal_  The address of the Portal on the current chain.
     */
    constructor(address mailbox_, address portal_, address initialOwner_) Ownable(initialOwner_) {
        if ((mailbox = mailbox_) == address(0)) revert ZeroMailbox();
        if ((portal = portal_) == address(0)) revert ZeroPortal();
    }

    /// @inheritdoc IBridge
    function quote(uint256 destinationChainId_, uint256 gasLimit_, bytes memory payload_) external view returns (uint256 fee_) {
        bytes memory metadata_ = StandardHookMetadata.overrideGasLimit(gasLimit_);
        bytes32 peer_ = _getPeer(destinationChainId_);
        uint32 destinationDomain_ = _getHyperlaneDomain(destinationChainId_);

        fee_ = IMailbox(mailbox).quoteDispatch(destinationDomain_, peer_, payload_, metadata_);
    }

    /// @dev Returns zero address, so Mailbox will use the default ISM
    function interchainSecurityModule() external pure returns (address) {
        return address(0);
    }

    /// @inheritdoc IBridge
    function sendMessage(
        uint256 destinationChainId_,
        uint256 gasLimit_,
        address refundAddress_,
        bytes memory payload_
    ) external payable returns (bytes32 messageId_) {
        if (msg.sender != portal) revert NotPortal();

        IMailbox mailbox_ = IMailbox(mailbox);
        bytes memory metadata_ = StandardHookMetadata.formatMetadata(0, gasLimit_, refundAddress_, "");
        bytes32 peer_ = _getPeer(destinationChainId_);
        uint32 destinationDomain_ = _getHyperlaneDomain(destinationChainId_);

        // NOTE: The transaction reverts if mgs.value isn't enough to cover the fee.
        //       If msg.value is greater than the required fee, the excess is sent to the refund address.
        messageId_ = mailbox_.dispatch{ value: msg.value }(destinationDomain_, peer_, payload_, metadata_);
    }

    /// @inheritdoc IMessageRecipient
    function handle(uint32 sourceChainId_, bytes32 sender_, bytes calldata payload_) external payable {
        if (msg.sender != mailbox) revert NotMailbox();
        if (sender_ != peer[sourceChainId_]) revert UnsupportedSender(sender_);
        IPortal(portal).receiveMessage(sourceChainId_, payload_);
    }

    /// @inheritdoc IHyperlaneBridge
    function setPeer(uint256 destinationChainId_, bytes32 peer_) external onlyOwner {
        if (destinationChainId_ == 0) revert ZeroDestinationChain();
        if (peer_ == bytes32(0)) revert ZeroPeer();

        peer[destinationChainId_] = peer_;
        emit PeerSet(destinationChainId_, peer_);
    }

    /**
     * @notice Returns the address of Hyperlane bridge on the destination chain.
     * @param  destinationChainId_ The EVM chain id of the destination chain.
     * @return peer_               The address of Hyperlane bridge on the destination chain.
     */
    function _getPeer(uint256 destinationChainId_) private view returns (bytes32 peer_) {
        peer_ = peer[destinationChainId_];
        if (peer_ == bytes32(0)) revert UnsupportedDestinationChain(destinationChainId_);
    }

    /**
     * @notice Returns Hyperlane domain by EVM chain Id
     * @dev    For EVM chains Hyperlane domain IDs match EVM chain IDs, but uses `uint32` type
     *         https://docs.hyperlane.xyz/docs/reference/domains
     * @param  evmChainId_ The EVM chain Id.
     * @return domain_     The Hyperlane domain.
     */
    function _getHyperlaneDomain(uint256 evmChainId_) private pure returns (uint32 domain_) {
        return evmChainId_.toUint32();
    }
}
