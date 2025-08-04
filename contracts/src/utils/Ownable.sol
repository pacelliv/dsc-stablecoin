// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {IERC165} from "../interfaces/IERC165.sol";
import {IERC173} from "../interfaces/IERC173.sol";

abstract contract Ownable is IERC165, IERC173 {
    error Ownable__UnauthorizedAccount();

    address private s_owner;

    modifier onlyOwner() {
        if (msg.sender != s_owner) {
            revert Ownable__UnauthorizedAccount();
        }
        _;
    }

    constructor(address initialOwner) {
        s_owner = initialOwner;
        emit OwnershipTransferred(address(0), initialOwner);
    }

    function transferOwnership(address _newOwner) external onlyOwner {
        address oldOwner = s_owner;
        s_owner = _newOwner;
        emit OwnershipTransferred(oldOwner, _newOwner);
    }

    function owner() external view returns (address) {
        return s_owner;
    }

    function supportsInterface(bytes4 _interfaceID) external pure returns (bool) {
        return _interfaceID == 0x7f5828d0 || _interfaceID == 0x01ffc9a7;
    }
}
