// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {IDSC} from "./interfaces/IDSC.sol";
import {Ownable} from "./utils/Ownable.sol";
import {ERC20} from "@openzeppelin/token/ERC20/ERC20.sol";

/// @title DSC
/// @author Eugenio Pacelli Flores Voitier
/// @notice Minimal stablecoin contract inspired on the design of MakerDAO's DAI
/// @dev This contract contains the core logic for minting and burning
/// @dev This contract is owned by the DSCEngine contract
/// @dev Main properties of the stablecoin:
/// - Collateral: exogenous
/// - Stability Mechanism (Minting): algorithmic
/// - Relative Stability (Value): anchored to the United States Dollar (USD)
/// - Collateral Type: crypto
contract DSC is IDSC, Ownable, ERC20 {
    constructor() Ownable(msg.sender) ERC20("Decentralized Stablecoin", "DSC") {}

    function mint(address _to, uint256 _amount) external onlyOwner returns (bool) {
        _mint(_to, _amount);
        return true;
    }

    function burn(address _from, uint256 _amount) external onlyOwner returns (bool) {
        _burn(_from, _amount);
        return true;
    }
}
