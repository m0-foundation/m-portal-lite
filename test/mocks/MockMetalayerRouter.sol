// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.26;

import { ReadOperation } from "../../src/bridges/metalayer/interfaces/IMetalayerRecipient.sol";
import { FinalityState } from "../../src/bridges/metalayer/interfaces/IMetalayerRouter.sol";

contract MockMetalayerRouter {
    function quoteDispatch(
        uint32,
        bytes32,
        ReadOperation[] calldata,
        bytes calldata,
        FinalityState,
        uint256
    ) external pure returns (uint256) {
        return 0;
    }

    function dispatch(uint32, bytes32, ReadOperation[] calldata, bytes calldata, FinalityState, uint256) external payable {
        // Mock dispatch function - does nothing but consumes gas
    }
}
