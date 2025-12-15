// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.26;

import { IERC20 } from "../lib/common/src/interfaces/IERC20.sol";
import { Migratable } from "../lib/common/src/Migratable.sol";

import { IPortal } from "./interfaces/IPortal.sol";
import { IRegistrarLike } from "./interfaces/IRegistrarLike.sol";
import { ISpokeVault } from "./interfaces/ISpokeVault.sol";
import { ISwapFacilityLike } from "./interfaces/ISwapFacilityLike.sol";

/**
 * @title  SpokeVault
 * @author M^0 Labs
 * @notice Vault on Spoke chains L2s and receiving excess $M from Wrapped $M.
 */
contract SpokeVault is ISpokeVault, Migratable {
    /// @inheritdoc ISpokeVault
    address public immutable migrationAdmin;

    /// @inheritdoc ISpokeVault
    uint256 public immutable hubChainId;

    /// @inheritdoc ISpokeVault
    address public immutable mToken;

    /// @inheritdoc ISpokeVault
    address public immutable wrappedMToken;

    /// @inheritdoc ISpokeVault
    address public immutable hubVault;

    /// @inheritdoc ISpokeVault
    address public immutable spokePortal;

    /// @inheritdoc ISpokeVault
    address public immutable swapFacility;

    /**
     * @notice Constructs SpokeVault Implementation contract.
     * @param  spokePortal_    The address of the SpokePortal contract.
     * @param  hubVault_       The address of the Vault contract on the hub chain.
     * @param  hubChainId_     The EVM chain Id of the Hub chain.
     * @param  migrationAdmin_ The address of a migration admin.
     * @param  wrappedMToken_  The address of the Wrapped M token.
     */
    constructor(
        address spokePortal_,
        address hubVault_,
        uint256 hubChainId_,
        address migrationAdmin_,
        address wrappedMToken_
    ) {
        if ((spokePortal = spokePortal_) == address(0)) revert ZeroSpokePortal();
        if ((hubVault = hubVault_) == address(0)) revert ZeroHubVault();
        if ((hubChainId = hubChainId_) == 0) revert ZeroHubChain();
        if ((migrationAdmin = migrationAdmin_) == address(0)) revert ZeroMigrationAdmin();
        if ((wrappedMToken = wrappedMToken_) == address(0)) revert ZeroWrappedMToken();

        mToken = IPortal(spokePortal_).mToken();
        swapFacility = IPortal(spokePortal_).swapFacility();
    }

    ///////////////////////////////////////////////////////////////////////////
    //                     EXTERNAL INTERACTIVE FUNCTIONS                    //
    ///////////////////////////////////////////////////////////////////////////

    /// @inheritdoc ISpokeVault
    function transferExcessM(address refundAddress_) external payable returns (bytes32 messageId_) {
        // Unwrap any wM to M
        uint256 wrappedMBalance_ = IERC20(wrappedMToken).balanceOf(address(this));

        if (wrappedMBalance_ > 0) {
            IERC20(wrappedMToken).approve(swapFacility, wrappedMBalance_);
            ISwapFacilityLike(swapFacility).swapOutM(wrappedMToken, wrappedMBalance_, address(this));
        }

        // Transfer all M (including unwrapped wM) to HubVault
        uint256 amount_ = IERC20(mToken).balanceOf(address(this));

        if (amount_ == 0) return messageId_;

        address spokePortal_ = spokePortal;

        IERC20(mToken).approve(spokePortal_, amount_);
        messageId_ = IPortal(spokePortal_).transfer{ value: msg.value }(amount_, hubChainId, hubVault, refundAddress_);

        emit ExcessMTokenSent(amount_, messageId_);
    }

    /// @inheritdoc ISpokeVault
    function migrate(address migrator_) external {
        if (msg.sender != migrationAdmin) revert UnauthorizedMigration();

        _migrate(migrator_);
    }

    /// @dev Fallback function to receive ETH.
    receive() external payable { }

    ///////////////////////////////////////////////////////////////////////////
    //                INTERNAL/PRIVATE INTERACTIVE FUNCTIONS                 //
    ///////////////////////////////////////////////////////////////////////////

    /// @inheritdoc Migratable
    function _getMigrator() internal pure override returns (address migrator_) {
        // NOTE: in this version only the owner-controlled migration via `migrate()` function is supported
        return address(0);
    }
}
