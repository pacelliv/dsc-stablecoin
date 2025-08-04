// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

/// @dev Contract with no explicit mechanisms to receive native token.
contract InvalidNativeRecipient {
    error InvalidNativeRecipient__CallFailed();

    function call(address _to, uint256 _value, bytes memory _calldata) external payable {
        (bool success, bytes memory reason) = payable(_to).call{value: _value}(_calldata);

        if (!success) {
            if (reason.length == 0) {
                revert InvalidNativeRecipient__CallFailed();
            }

            assembly {
                revert(add(0x20, reason), mload(reason))
            }
        }
    }
}
