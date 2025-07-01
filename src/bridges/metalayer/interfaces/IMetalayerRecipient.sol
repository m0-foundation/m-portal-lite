// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity >=0.6.11;

/**
 * @title IMetalayerRecipient
 * @author Caldera
 * @notice Interface for contracts that can receive messages through the Metalayer protocol
 * @dev Implement this interface to receive cross-chain messages and read results from Metalayer
 */
interface IMetalayerRecipient {
    /**
     * @notice Handles an incoming message from another chain via Metalayer
     * @dev This function is called by the MetalayerRouter when a message is delivered
     * @param _origin The domain ID of the chain where the message originated
     * @param _sender The address of the contract that sent the message on the origin chain
     * @param _message The payload of the message to be handled
     * @param _reads Array of read operations that were requested in the original message
     * @param _readResults Array of results from the read operations, provided by the relayer
     * @custom:security The caller must be the MetalayerRouter contract
     */
    function handle(
        uint32 _origin,
        bytes32 _sender,
        bytes calldata _message,
        ReadOperation[] calldata _reads,
        bytes[] calldata _readResults
    ) external payable;
}

/**
 * @notice Represents a cross-chain read operation
 * @dev Used to specify what data should be read from other chains.
 * The read operations are only compatible with EVM chains, so the
 * target is packed as an address to save bytes.
 */
struct ReadOperation {
    /// @notice The domain ID of the chain to read from
    uint32 domain;
    /// @notice The address of the contract to read from
    address target;
    /// @notice The calldata to execute on the target contract
    bytes callData;
}