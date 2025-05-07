// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.26;

import { OwnableUpgradeable } from "../../lib/openzeppelin-contracts-upgradeable/contracts/access/OwnableUpgradeable.sol";
import { PausableUpgradeable } from "../../lib/openzeppelin-contracts-upgradeable/contracts/utils/PausableUpgradeable.sol";
import { IPausableOwnable } from "../interfaces/IPausableOwnable.sol";

abstract contract PausableOwnableUpgradeable is OwnableUpgradeable, PausableUpgradeable, IPausableOwnable {
    /// @custom:storage-location erc7201:m0.storage.PausableOwnable
    struct PausableOwnableStorage {
        address _pauser;
    }

    /// @dev keccak256(abi.encode(uint256(keccak256("m0.storage.PausableOwnable")) - 1)) & ~bytes32(uint256(0xff))
    bytes32 private constant _PAUSER_SLOT = 0x9ab2df69adadda616016eab34dbdcdbe8b11549e0ceb446652474b2cb1ced800;

    /// @dev Modifier to allow only the pauser and the owner to access pausing functionality
    modifier onlyOwnerOrPauser() {
        if (pauser() != _msgSender() && owner() != _msgSender()) revert Unauthorized(_msgSender());
        _;
    }

    ///////////////////////////////////////////////////////////////////////////
    //                       EXTERNAL VIEW FUNCTIONS                         //
    ///////////////////////////////////////////////////////////////////////////

    /// @dev Returns the address of the current pauser.
    function pauser() public view virtual returns (address) {
        PausableOwnableStorage storage $ = _getPausableOwnableStorage();
        return $._pauser;
    }

    ///////////////////////////////////////////////////////////////////////////
    //                     EXTERNAL INTERACTIVE FUNCTIONS                    //
    ///////////////////////////////////////////////////////////////////////////

    /// @inheritdoc IPausableOwnable
    function transferPauserRole(address newPauser_) external onlyOwner {
        if (newPauser_ == address(0)) revert ZeroPauser();
        _transferPauserRole(newPauser_);
    }

    /// @inheritdoc IPausableOwnable
    function pause() external onlyOwnerOrPauser {
        _pause();
    }

    /// @inheritdoc IPausableOwnable
    function unpause() external onlyOwnerOrPauser {
        _unpause();
    }

    ///////////////////////////////////////////////////////////////////////////
    //                        PRIVATE PURE FUNCTIONS                         //
    ///////////////////////////////////////////////////////////////////////////

    function _getPausableOwnableStorage() private pure returns (PausableOwnableStorage storage $) {
        assembly {
            $.slot := _PAUSER_SLOT
        }
    }

    ///////////////////////////////////////////////////////////////////////////
    //                              INITIALIZERS                             //
    ///////////////////////////////////////////////////////////////////////////

    /**
     * @dev Initializes itself and the parent contracts.
     * @param initialOwner_  The address of initial owner.
     * @param initialPauser_ The address of initial pauser.
     */
    function __PausableOwnable_init(address initialOwner_, address initialPauser_) internal onlyInitializing {
        __Ownable_init_unchained(initialOwner_);
        __Pausable_init_unchained();
        __PausableOwnable_init_unchained(initialPauser_);
    }

    /**
     * @dev Initializes the contract.
     * @param initialPauser_ The address of initial pauser.
     */
    function __PausableOwnable_init_unchained(address initialPauser_) internal onlyInitializing {
        if (initialPauser_ == address(0)) revert ZeroPauser();
        _transferPauserRole(initialPauser_);
    }

    ///////////////////////////////////////////////////////////////////////////
    //                     INTERNAL INTERACTIVE FUNCTIONS                    //
    ///////////////////////////////////////////////////////////////////////////

    function _transferPauserRole(address newPauser_) internal {
        PausableOwnableStorage storage $ = _getPausableOwnableStorage();
        address previousPauser_ = $._pauser;
        $._pauser = newPauser_;
        emit PauserTransferred(previousPauser_, newPauser_);
    }
}
