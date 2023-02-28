// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity 0.8.12;

import "../common/SelfAuthorized.sol";

/// @title Fallback Manager - A contract that manages fallback calls made to this contract
contract FallbackManager is SelfAuthorized {
    // keccak-256 hash of "fallback_manager.handler.address" subtracted by 1
    bytes32 internal constant FALLBACK_HANDLER_STORAGE_SLOT = 0x6c9a6c4a39284e37ed1cf53d337577d14212a4870fb976a4366c693b939918d4;

    event ChangedFallbackHandler(address previousHandler, address handler);

    // solhint-disable-next-line payable-fallback,no-complex-fallback
    fallback() external {
        bytes32 slot = FALLBACK_HANDLER_STORAGE_SLOT;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            let handler := sload(slot)
            if iszero(handler) {
                return(0, 0)
            }
            calldatacopy(0, 0, calldatasize())
            // The msg.sender address is shifted to the left by 12 bytes to remove the padding
            // Then the address without padding is stored right after the calldata
            mstore(calldatasize(), shl(96, caller()))
            // Add 20 bytes for the address appended add the end
            let success := call(gas(), handler, 0, 0, add(calldatasize(), 20), 0, 0)
            returndatacopy(0, 0, returndatasize())
            if iszero(success) {
                revert(0, returndatasize())
            }
            return(0, returndatasize())
        }
    }

    /// @dev Allows to add a contract to handle fallback calls.
    ///      Only fallback calls without value and with data will be forwarded.
    ///      This can only be done via a Safe transaction.
    /// @param handler contract to handle fallback calls.
    function setFallbackHandler(address handler) public authorized {
        // review - check if this is loading the correct slot, for previousHandler indexing
        address previousHandler;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            previousHandler := sload(FALLBACK_HANDLER_STORAGE_SLOT)
        }
        _setFallbackHandler(handler);
        emit ChangedFallbackHandler(previousHandler, handler);
    }

    function _setFallbackHandler(address handler) internal {
        require(handler != address(0), "Invalid Fallback Handler");
        bytes32 slot = FALLBACK_HANDLER_STORAGE_SLOT;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            sstore(slot, handler)
        }
    }

    uint256[24] private __gap;
}
