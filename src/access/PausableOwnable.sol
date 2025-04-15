// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.26;

import { IPausableOwnable } from "../interfaces/IPausableOwnable.sol";

abstract contract PausableOwnable is IPausableOwnable {
    // NOTE: Use uint256 instead of booleans to avoid extra SLOAD
    uint256 private constant _NOT_PAUSED = 0;
    uint256 private constant _PAUSED = 1;

    address public owner;
    address public pauser;
    uint256 private _paused;

    constructor(address initialOwner_, address initialPauser_) {
        if (initialOwner_ == address(0)) revert ZeroOwner();
        if (initialPauser_ == address(0)) revert ZeroPauser();

        owner = initialOwner_;
        pauser = initialPauser_;
    }

    /// @dev Modifier to make a function callable only by the owner
    modifier onlyOwner() {
        if (owner != msg.sender) revert Unauthorized(msg.sender);
        _;
    }

    /// @dev Modifier to allow only the pauser and the owner to access pausing functionality
    modifier onlyOwnerOrPauser() {
        if (pauser != msg.sender && owner != msg.sender) revert Unauthorized(msg.sender);
        _;
    }

    /// @dev Modifier to make a function callable only when the contract is not paused.
    modifier whenNotPaused() {
        if (paused()) revert OperationPaused();
        _;
    }

    /// @inheritdoc IPausableOwnable
    function paused() public view returns (bool paused_) {
        paused_ = _paused == _PAUSED;
    }

    /// @inheritdoc IPausableOwnable
    function transferOwnership(address newOwner_) external onlyOwner {
        if (newOwner_ == address(0)) revert ZeroOwner();
        address previousOwner_ = owner;
        owner = newOwner_;
        emit OwnershipTransferred(previousOwner_, newOwner_);
    }

    /// @inheritdoc IPausableOwnable
    function transferPauserRole(address newPauser_) external onlyOwner {
        if (newPauser_ == address(0)) revert ZeroPauser();
        address previousPauser_ = pauser;
        pauser = newPauser_;
        emit PauserTransferred(previousPauser_, newPauser_);
    }

    /// @inheritdoc IPausableOwnable
    function pause() external onlyOwnerOrPauser {
        if (paused()) revert AlreadyPaused();
        _paused = _PAUSED;
        emit Paused();
    }

    /// @inheritdoc IPausableOwnable
    function unpause() external onlyOwnerOrPauser {
        if (!paused()) revert NotPaused();
        _paused = _NOT_PAUSED;
        emit Unpaused();
    }
}
