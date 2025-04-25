// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.26;

contract MockMailbox {
    function quoteDispatch(
        uint32,
        bytes32,
        bytes calldata,
        bytes calldata
    ) external view returns (uint256) {
        return 0;
    }

    function dispatch(
        uint32,
        bytes32,
        bytes calldata,
        bytes calldata
    ) external payable returns (bytes32) {
        return bytes32(0);
    }
}
