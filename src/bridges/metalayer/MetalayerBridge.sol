// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.26;

import { Ownable } from "../../../lib/openzeppelin/contracts/access/Ownable.sol";
import { SafeCast } from "../../../lib/openzeppelin/contracts/utils/math/SafeCast.sol";

import { IBridge } from "../../interfaces/IBridge.sol";
import { IMetalayerBridge } from "./interfaces/IMetalayerBridge.sol";
import { ReadOperation, IMetalayerRecipient } from "./interfaces/IMetalayerRecipient.sol";
import { IMetalayerRouter } from "./interfaces/IMetalayerRouter.sol";
import { IPortal } from "../../interfaces/IPortal.sol";
import { TypeConverter } from "../../libs/TypeConverter.sol";
import { FinalityState } from "./interfaces/IMetalayerRouter.sol";

/// @title  Metalayer Bridge
/// @notice Sends and receives messages to and from remote chains using Metalayer protocol
contract MetalayerBridge is Ownable, IMetalayerBridge {
    using TypeConverter for *;
    using SafeCast for uint256;

    /// @inheritdoc IMetalayerBridge
    address public immutable router;

    /// @inheritdoc IBridge
    address public immutable portal;

    /// @inheritdoc IMetalayerBridge
    mapping(uint256 destinationChainId => bytes32 destinationPeer) public peer;

    /// @notice Override mapping for custom domain IDs by chain ID
    mapping(uint256 chainId => uint32 domain) public domainOverride;

    /**
     * @notice Constructs Metalayer Bridge
     * @param router_ The address of the Metalayer Router.
     * @param portal_  The address of the Portal on the current chain.
     */
    constructor(address router_, address portal_, address initialOwner_) Ownable(initialOwner_) {
        if ((router = router_) == address(0)) revert ZeroRouter();
        if ((portal = portal_) == address(0)) revert ZeroPortal();
    }

    /// @inheritdoc IBridge
    function quote(uint256 destinationChainId_, uint256 gasLimit_, bytes memory payload_) external view returns (uint256 fee_) {
        bytes32 peer_ = _getPeer(destinationChainId_);
        uint32 destinationDomain_ = _getMetalayerDomain(destinationChainId_);

        fee_ = IMetalayerRouter(router).quoteDispatch(
            destinationDomain_, peer_, new ReadOperation[](0), payload_, FinalityState.INSTANT, gasLimit_
        );
    }

    /// @inheritdoc IBridge
    function sendMessage(
        uint256 destinationChainId_,
        uint256 gasLimit_,
        address refundAddress_,
        bytes memory payload_
    ) external payable returns (bytes32 messageId_) {
        if (msg.sender != portal) revert NotPortal();

        bytes32 peer_ = _getPeer(destinationChainId_);
        uint32 destinationDomain_ = _getMetalayerDomain(destinationChainId_);
        ReadOperation[] memory emptyReads_ = new ReadOperation[](0);

        // NOTE: The transaction reverts if msg.value isn't enough to cover the fee.
        //       If msg.value is greater than the required fee, the excess is sent to the refund address.
        IMetalayerRouter(router).dispatch{ value: msg.value }(
            destinationDomain_, peer_, emptyReads_, payload_, FinalityState.INSTANT, gasLimit_
        );

        // Metalayer doesn't return a messageId, so we generate one from the transaction hash
        messageId_ = keccak256(abi.encodePacked(block.timestamp, destinationChainId_, peer_, payload_));
    }

    /// @inheritdoc IMetalayerRecipient
    function handle(
        uint32 sourceChainId_,
        bytes32 sender_,
        bytes calldata payload_,
        ReadOperation[] calldata reads_,
        bytes[] calldata readResults_
    ) external payable {
        if (msg.sender != router) revert NotRouter();
        if (sender_ != peer[sourceChainId_]) revert UnsupportedSender(sender_);
        IPortal(portal).receiveMessage(sourceChainId_, payload_);
    }

    /// @inheritdoc IMetalayerBridge
    function setPeer(uint256 destinationChainId_, bytes32 peer_) external onlyOwner {
        if (destinationChainId_ == 0) revert ZeroDestinationChain();
        if (peer_ == bytes32(0)) revert ZeroPeer();

        peer[destinationChainId_] = peer_;
        emit PeerSet(destinationChainId_, peer_);
    }

    /**
     * @notice Sets a custom domain override for a specific chain ID.
     * @param  chainId_ The EVM chain ID to set an override for.
     * @param  domain_  The custom domain ID to use for this chain.
     */
    function setDomainOverride(uint256 chainId_, uint32 domain_) external onlyOwner {
        if (chainId_ == 0) revert ZeroDestinationChain();
        if (domain_ == 0) revert ZeroDomain();

        domainOverride[chainId_] = domain_;
        emit DomainOverrideSet(chainId_, domain_);
    }

    /**
     * @notice Returns the address of Metalayer bridge on the destination chain.
     * @param  destinationChainId_ The EVM chain id of the destination chain.
     * @return peer_               The address of Metalayer bridge on the destination chain.
     */
    function _getPeer(uint256 destinationChainId_) private view returns (bytes32 peer_) {
        peer_ = peer[destinationChainId_];
        if (peer_ == bytes32(0)) revert UnsupportedDestinationChain(destinationChainId_);
    }

    /**
     * @notice Returns Metalayer domain by EVM chain Id
     * @dev    Checks for domain override first, then falls back to chain ID conversion
     * @param  evmChainId_ The EVM chain Id.
     * @return domain_     The Metalayer domain.
     */
    function _getMetalayerDomain(uint256 evmChainId_) private view returns (uint32 domain_) {
        domain_ = domainOverride[evmChainId_];
        if (domain_ == 0) {
            domain_ = evmChainId_.toUint32();
        }
    }
}
