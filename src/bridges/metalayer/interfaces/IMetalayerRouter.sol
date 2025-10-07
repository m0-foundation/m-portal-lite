// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.26;

import { ReadOperation } from "./IMetalayerRecipient.sol";

/// @notice The finality state of the message.
/// @author Caldera
enum FinalityState {
    INSTANT,
    FINALIZED
}

/// @author Caldera
interface IMetalayerRouter {
    /**
     * @notice Dispatches a message to the destination domain & recipient with the given reads and write.
     * @dev Convenience function for EVM chains.
     * @param _destinationDomain Domain of destination chain
     * @param _recipientAddress Address of recipient on destination chain as bytes32
     * @param _reads Read operations
     * @param _writeCallData The raw bytes to be called on the recipient address.
     * @param _finalityState What sort of finality we should wait for before the message is valid. Currently only have 0 for instant, 1 for final.
     * @param _gasLimit The gas limit for the submission transaction on the destination chain
     */
    function dispatch(
        uint32 _destinationDomain,
        address _recipientAddress,
        ReadOperation[] memory _reads, // can be empty
        bytes memory _writeCallData,
        FinalityState _finalityState,
        uint256 _gasLimit
    ) external payable;

    /**
     * @notice Dispatches a message to the destination domain & recipient with the given reads and write.
     * @param _destinationDomain Domain of destination chain
     * @param _recipientAddress Address of recipient on destination chain as bytes32
     * @param _reads Read operations
     * @param _writeCallData The raw bytes to be called on the recipient address.
     * @param _finalityState What sort of finality we should wait for before the message is valid. Currently only have 0 for instant, 1 for final.
     * @param _gasLimit The gas limit for the submission transaction on the destination chain
     */
    function dispatch(
        uint32 _destinationDomain,
        bytes32 _recipientAddress,
        ReadOperation[] memory _reads, // can be empty
        bytes memory _writeCallData,
        FinalityState _finalityState,
        uint256 _gasLimit
    ) external payable;

    /**
     * @notice Quotes the Metalayer gas fee for a message to the destination domain & recipient with the given reads and write.
     * @param _destinationDomain Domain of destination chain
     * @param _recipientAddress Address of recipient on destination chain as bytes32
     * @param _reads Read operations
     * @param _writeCallData The raw bytes to be called on the recipient address.
     * @param _finalityState What sort of finality we should wait for before the message is valid. Currently only have 0 for instant, 1 for final.
     * @param _gasLimit The gas limit for the submission transaction on the destination chain
     */
    function quoteDispatch(
        uint32 _destinationDomain,
        bytes32 _recipientAddress,
        ReadOperation[] calldata _reads, // can be empty
        bytes calldata _writeCallData,
        FinalityState _finalityState,
        uint256 _gasLimit
    ) external view returns (uint256);

    /**
     * @notice Quotes the Metalayer gas fee for a message to the destination domain & recipient with the given reads and write.
     * @param _destinationDomain Domain of destination chain
     * @param _recipientAddress Address of recipient on destination chain as address
     * @param _reads Read operations
     * @param _writeCallData The raw bytes to be called on the recipient address.
     * @param _finalityState What sort of finality we should wait for before the message is valid. Currently only have 0 for instant, 1 for final.
     * @param _gasLimit The gas limit for the submission transaction on the destination chain
     */
    function quoteDispatch(
        uint32 _destinationDomain,
        address _recipientAddress,
        ReadOperation[] calldata _reads, // can be empty
        bytes calldata _writeCallData,
        FinalityState _finalityState,
        uint256 _gasLimit
    ) external view returns (uint256);

    /**
     * @notice Computes quote for dipatching a message to the destination domain & recipient
     * using the default hook and empty metadata.
     * @param destinationDomain Domain of destination chain
     * @param recipientAddress Address of recipient on destination chain as bytes32
     * @param messageBody Raw bytes content of message body
     * @return fee The payment required to dispatch the message
     */
    function quoteDispatch(
        uint32 destinationDomain,
        bytes32 recipientAddress,
        bytes calldata messageBody
    ) external view returns (uint256 fee);

    function routerAddresses(uint32 chainDomainId) external view returns (address routerAddress);
}
