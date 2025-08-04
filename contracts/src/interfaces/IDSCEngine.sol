// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

interface IDSCEngine {
    event Deposited(address indexed _user, uint256 _amount);
    event Minted(address indexed _user, uint256 _amount);
    event Redeemed(address indexed _user, address indexed _to, uint256 _amount);
    event Burned(address indexed _user, uint256 _amount);
    event Liquidated(
        address indexed _liquidator,
        address indexed _user,
        uint256 _repaidAmount,
        uint256 _collateralSold
    );

    function deposit() external payable returns (bool);
    function mint(uint256 _amount) external returns (bool);
    function depositAndMint(uint256 _amountToMint) external payable returns (bool);
    function redeem(uint256 _amount) external returns (bool);
    function burnAndRedeem(uint256 _amountToBurm, uint256 _amountToRedeem) external returns (bool);
    function burn(uint256 _amount) external returns (bool);
    function liquidate(address _from, uint256 _repayAmount) external returns (bool);
    function getPositionInfo(
        address _user
    ) external view returns (uint256 _collateralDeposited, uint256 _dscMinted, uint256 _healthFactor);
    function getPriceFeed() external view returns (address);
    function getTotalDepositedCollateral() external view returns (uint256);
    function getDSCSupply() external view returns (uint256);
}
