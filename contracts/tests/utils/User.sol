// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {DSC} from "../../src/DSC.sol";
import {DSCEngine} from "../../src/DSCEngine.sol";

contract User {
    error User__OperationFaield();
    error User__CallFailed();
    error User__InsufficientBalanceForOperation();

    DSC public immutable i_dsc;
    DSCEngine public immutable i_engine;

    constructor(DSC dsc, DSCEngine engine) {
        i_engine = engine;
        i_dsc = dsc;
    }

    receive() external payable {}

    function depositCollateral(uint256 _amount) external returns (bool) {
        _checkHasEnoughBalance(_amount);
        return i_engine.deposit{value: _amount}();
    }

    function mintStablecoin(uint256 _amount) external returns (bool) {
        return i_engine.mint(_amount);
    }

    function depositAndMint(uint256 _collateralToDeposit, uint256 _stablecoinToMint) external returns (bool) {
        _checkHasEnoughBalance(_collateralToDeposit);
        return i_engine.depositAndMint{value: _collateralToDeposit}(_stablecoinToMint);
    }

    function burnStablecoin(uint256 _amount) external returns (bool) {
        i_dsc.approve(address(i_engine), _amount);
        return i_engine.burn(_amount);
    }

    function redeemCollateral(uint256 _amount) external returns (bool) {
        return i_engine.redeem(_amount);
    }

    function burnAndRedeem(uint256 _amountToBurn, uint256 _amountToRedeem) external returns (bool) {
        i_dsc.approve(address(i_engine), _amountToBurn);
        return i_engine.burnAndRedeem(_amountToBurn, _amountToRedeem);
    }

    function liquidatePosition(address _user, uint256 _debtToCover) external returns (bool) {
        i_dsc.approve(address(i_engine), _debtToCover);
        return i_engine.liquidate(_user, _debtToCover);
    }

    function transferDSC(address _recipient, uint256 _amount) external returns (bool) {
        return i_dsc.transfer(_recipient, _amount);
    }

    function transferFromDSC(address _from, address _to, uint256 _amount) external returns (bool) {
        return i_dsc.transferFrom(_from, _to, _amount);
    }

    function approveDSC(address _spender, uint256 _allowance) external returns (bool) {
        return i_dsc.approve(_spender, _allowance);
    }

    function tryCall(address _to, uint256 _value, bytes memory _calldata) external payable {
        _checkHasEnoughBalance(_value);

        (bool success, bytes memory reason) = payable(_to).call{value: _value}(_calldata);

        if (!success) {
            if (reason.length == 0) {
                revert User__CallFailed();
            }

            assembly {
                revert(add(0x20, reason), mload(reason))
            }
        }
    }

    function _checkHasEnoughBalance(uint256 _amount) private view {
        if (_amount > address(this).balance) {
            revert User__InsufficientBalanceForOperation();
        }
    }
}
