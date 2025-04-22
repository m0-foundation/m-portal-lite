// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.26;

import { Ownable } from "../../lib/openzeppelin/contracts/access/Ownable.sol";
import { Pausable } from "../../lib/openzeppelin/contracts/utils/Pausable.sol";
import { IPausableOwnable } from "../interfaces/IPausableOwnable.sol";

abstract contract PausableOwnable is Ownable, Pausable, IPausableOwnable {
    address public pauser;

    constructor(address initialOwner_, address initialPauser_) Ownable(initialOwner_) {
        if (initialPauser_ == address(0)) revert ZeroPauser();

        pauser = initialPauser_;
    }

    /// @dev Modifier to allow only the pauser and the owner to access pausing functionality
    modifier onlyOwnerOrPauser() {
        if (pauser != msg.sender && owner() != msg.sender) revert Unauthorized(msg.sender);
        _;
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
        _pause();
    }

    /// @inheritdoc IPausableOwnable
    function unpause() external onlyOwnerOrPauser {
        _unpause();
    }
}
