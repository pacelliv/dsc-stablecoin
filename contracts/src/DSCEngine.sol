// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {IDSC} from "./interfaces/IDSC.sol";
import {IDSCEngine} from "./interfaces/IDSCEngine.sol";
import {AggregatorV3Interface} from "./interfaces/AggregatorV3Interface.sol";
import {OracleLib} from "./libraries/OracleLib.sol";

contract DSCEngine is IDSCEngine {
    struct UserInfo {
        uint256 collateralDeposited;
        uint256 dscMinted;
    }

    using OracleLib for AggregatorV3Interface;

    // Protocol settings.
    uint256 public constant PRECISION = 1 ether;
    uint256 public constant PRICE_FEED_PRECISION = 1e10;
    uint256 public constant MINIMUM_HEALTH_FACTOR = 1 ether;
    uint256 public constant LIQUIDATION_BONUS = 5;
    uint256 public constant LIQUIDATION_THRESHOLD = 50;
    uint256 public constant LIQUIDATION_PRECISION = 100;
    // Addresses and state variables.
    IDSC private immutable i_dsc;
    AggregatorV3Interface private immutable i_ethUsdPriceFeed;
    uint256 private s_totalDepositedCollateral;
    mapping(address => UserInfo) private s_usersInfo;

    error DSCEngine__ZeroAmount();
    error DSCEngine__BrokenHealthFactor();
    error DSCEngine__InsufficientBalance();
    error DSCEngine__RedeemFailed();
    error DSCEngine__UserCannotBeLiquidated();
    error DSCEngine__InsufficientDebt();
    error DSCEngine__TransferFromFailed();

    constructor(address _dsc, address _ethUsdPriceFeed) {
        i_dsc = IDSC(_dsc);
        i_ethUsdPriceFeed = AggregatorV3Interface(_ethUsdPriceFeed);
    }

    /*//////////////////////////////////////////////////////////////
                          EXTERNAL CORE LOGIC
    //////////////////////////////////////////////////////////////*/

    function deposit() external payable returns (bool) {
        _deposit(msg.sender, msg.value);
        return true;
    }

    function mint(uint256 _amount) external returns (bool) {
        _mint(msg.sender, _amount);
        return true;
    }

    function depositAndMint(uint256 _amountToMint) external payable returns (bool) {
        _deposit(msg.sender, msg.value);
        _mint(msg.sender, _amountToMint);
        return true;
    }

    function burn(uint256 _amount) external returns (bool) {
        _burn(msg.sender, msg.sender, _amount);
        return true;
    }

    function redeem(uint256 _amount) external returns (bool) {
        _redeem(msg.sender, msg.sender, _amount);
        return true;
    }

    function burnAndRedeem(uint256 _amountToBurn, uint256 _amountToRedeem) external returns (bool) {
        _burn(msg.sender, msg.sender, _amountToBurn);
        _redeem(msg.sender, msg.sender, _amountToRedeem);
        return true;
    }

    function liquidate(address _user, uint256 _debtToCover) external returns (bool) {
        if (_debtToCover == 0) revert DSCEngine__ZeroAmount();
        uint256 userHealthFactor = _calculateUserHealthFactor(_user);
        // Users with healthy health factor cannot be liquidated
        if (userHealthFactor >= MINIMUM_HEALTH_FACTOR) revert DSCEngine__UserCannotBeLiquidated();
        UserInfo memory userInfo = s_usersInfo[_user];
        // Assert the liquidator cannot cover more than the debt of the user.
        if (_debtToCover > userInfo.dscMinted) revert DSCEngine__InsufficientDebt();

        uint256 collateralToLiquidate = _calculateEthAmount(_debtToCover);
        uint256 bonus = (collateralToLiquidate * LIQUIDATION_BONUS) / LIQUIDATION_PRECISION;

        if (collateralToLiquidate + bonus <= userInfo.collateralDeposited) {
            collateralToLiquidate += bonus;
        }

        _burn(_user, msg.sender, _debtToCover);
        _redeem(_user, msg.sender, collateralToLiquidate);
        emit Liquidated(msg.sender, _user, _debtToCover, collateralToLiquidate);
        return true;
    }

    /*//////////////////////////////////////////////////////////////
                           PRIVATE CORE LOGIC
    //////////////////////////////////////////////////////////////*/

    function _deposit(address _user, uint256 _amount) private {
        if (_amount == 0) revert DSCEngine__ZeroAmount();
        UserInfo storage userInfo = s_usersInfo[_user];

        // Unchecked because it's improbable for overflows.
        unchecked {
            userInfo.collateralDeposited += _amount;
            s_totalDepositedCollateral += _amount;
        }

        emit Deposited(_user, _amount);
    }

    function _mint(address _user, uint256 _amount) private {
        if (_amount == 0) revert DSCEngine__ZeroAmount();
        UserInfo storage userInfo = s_usersInfo[_user];
        userInfo.dscMinted += _amount;
        _revertIfHealthFactorIsBroken(_user);
        emit Minted(_user, _amount);
        i_dsc.mint(_user, _amount);
    }

    function _burn(address _onBehalfOf, address _from, uint256 _amount) private {
        if (_amount == 0) revert DSCEngine__ZeroAmount();
        UserInfo storage userInfo = s_usersInfo[_onBehalfOf];
        if (userInfo.dscMinted < _amount) revert DSCEngine__InsufficientBalance();

        (bool success) = i_dsc.transferFrom(msg.sender, address(this), _amount);

        if (!success) {
            revert DSCEngine__TransferFromFailed();
        }

        unchecked {
            userInfo.dscMinted -= _amount;
            i_dsc.burn(address(this), _amount);
        }

        emit Burned(_from, _amount);
    }

    function _redeem(address _from, address _to, uint256 _amount) private {
        if (_amount == 0) revert DSCEngine__ZeroAmount();
        UserInfo storage userInfo = s_usersInfo[_from];
        if (userInfo.collateralDeposited < _amount) revert DSCEngine__InsufficientBalance();

        unchecked {
            userInfo.collateralDeposited -= _amount;
            s_totalDepositedCollateral -= _amount;
        }

        _revertIfHealthFactorIsBroken(_from);
        emit Redeemed(_from, _to, _amount);
        _tryCall(_to, _amount);
    }

    /*//////////////////////////////////////////////////////////////
                         EXTERNAL VIEW METHODS
    //////////////////////////////////////////////////////////////*/

    function getPositionInfo(
        address _user
    ) external view returns (uint256 _collateralDeposited, uint256 _dscMinted, uint256 _healthFactor) {
        UserInfo memory userInfo = s_usersInfo[_user];
        _collateralDeposited = userInfo.collateralDeposited;
        _dscMinted = userInfo.dscMinted;
        _healthFactor = _calculateUserHealthFactor(_user);
    }

    function getPriceFeed() external view returns (address) {
        return address(i_ethUsdPriceFeed);
    }

    function getDSC() external view returns (address) {
        return address(i_dsc);
    }

    function getTotalDepositedCollateral() external view returns (uint256) {
        return s_totalDepositedCollateral;
    }

    function getDSCSupply() external view returns (uint256) {
        return i_dsc.totalSupply();
    }

    /*//////////////////////////////////////////////////////////////
                            PRIVATE HELPERS
    //////////////////////////////////////////////////////////////*/

    function _tryCall(address _to, uint256 _value) private {
        (bool success, bytes memory reason) = payable(_to).call{value: _value}(hex"");

        if (!success) {
            if (reason.length == 0) {
                revert DSCEngine__RedeemFailed();
            }

            assembly {
                revert(add(0x20, reason), mload(reason))
            }
        }
    }

    function _calculateUserHealthFactor(address _user) private view returns (uint256) {
        UserInfo memory userInfo = s_usersInfo[_user];

        if (userInfo.dscMinted == 0) {
            return type(uint256).max;
        }

        uint256 collateralUsdValue = _calculateUsdValue(userInfo.collateralDeposited);
        // Calculates the 50% of the current USD value of the collateral
        uint256 collateralValueAdjustedForThreshold = (collateralUsdValue * LIQUIDATION_THRESHOLD) /
            LIQUIDATION_PRECISION;
        return (collateralValueAdjustedForThreshold * PRECISION) / userInfo.dscMinted;
    }

    function _calculateUsdValue(uint256 collateralDeposited) private view returns (uint256) {
        (, int256 answer, , ) = i_ethUsdPriceFeed.getPriceFeedLatestRoundData();
        return (uint256(answer) * PRICE_FEED_PRECISION * collateralDeposited) / PRECISION;
    }

    function _calculateEthAmount(uint256 stablecoin) private view returns (uint256) {
        (, int256 answer, , ) = i_ethUsdPriceFeed.getPriceFeedLatestRoundData();
        return (stablecoin * PRECISION) / (uint256(answer) * PRICE_FEED_PRECISION);
    }

    function _revertIfHealthFactorIsBroken(address _user) private view {
        uint256 healthFactor = _calculateUserHealthFactor(_user);

        if (healthFactor < MINIMUM_HEALTH_FACTOR) {
            revert DSCEngine__BrokenHealthFactor();
        }
    }
}
