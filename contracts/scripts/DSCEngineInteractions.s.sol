// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {IERC20} from "@openzeppelin/token/ERC20/IERC20.sol";
import {DevOpsTools} from "foundry-devops/DevOpsTools.sol";
import {console2} from "forge-std/console2.sol";
import {Script} from "forge-std/Script.sol";
import {DSC} from "../src/DSC.sol";
import {DSCEngine} from "../src/DSCEngine.sol";

contract Deposit is Script {
    error Deposit__InsufficientNativeBalance(uint256 _balance, uint256 _requested);
    error Deposit__OperationFailed();

    function run() public {
        uint256 amount = vm.envUint("AMOUNT");
        _deposit(amount);
    }

    function _deposit(uint256 _amount) private {
        _checkNativeBalance(msg.sender, _amount);
        DSCEngine engine = DSCEngine(DevOpsTools.get_most_recent_deployment("DSCEngine", block.chainid));

        vm.broadcast();
        _checkOperationSuccess(engine.deposit{value: _amount}());

        (uint256 collateralDeposited, uint256 dscMinted, uint256 healthFactor) = engine.getPositionInfo(msg.sender);

        console2.log("Collateral deposited: %e", collateralDeposited);
        console2.log("DSC minted: %e", dscMinted);
        console2.log("Health factor: %e", healthFactor, "\n");
    }

    function _checkNativeBalance(address _account, uint256 _requested) private view {
        uint256 balance = _account.balance;

        if (_requested > balance) {
            revert Deposit__InsufficientNativeBalance(balance, _requested);
        }
    }

    function _checkOperationSuccess(bool _success) private pure {
        if (!_success) {
            revert Deposit__OperationFailed();
        }
    }
}

contract Mint is Script {
    error Mint__OperationFailed();

    function run() public {
        uint256 amount = vm.envUint("AMOUNT");
        _mint(amount);
    }

    function _mint(uint256 _amount) private {
        DSCEngine engine = DSCEngine(DevOpsTools.get_most_recent_deployment("DSCEngine", block.chainid));

        vm.broadcast();
        _checkOperationSuccess(engine.mint(_amount));

        (uint256 collateralDeposited, uint256 dscMinted, uint256 healthFactor) = engine.getPositionInfo(msg.sender);

        console2.log("Collateral deposited: %e", collateralDeposited);
        console2.log("DSC minted: %e", dscMinted);
        console2.log("Health factor: %e", healthFactor, "\n");
    }

    function _checkOperationSuccess(bool _success) private pure {
        if (!_success) {
            revert Mint__OperationFailed();
        }
    }
}

contract DepositAndMint is Script {
    error DepositAndMint__InsufficientNativeBalance(uint256 _balance, uint256 _requested);
    error DepositAndMint__OperationFailed();

    function run() public {
        uint256 value = vm.envUint("VALUE");
        uint256 amount = vm.envUint("AMOUNT");
        _depositAndMint(value, amount);
    }

    function _depositAndMint(uint256 _amountToDeposit, uint256 _amountToMint) private {
        _checkNativeBalance(msg.sender, _amountToDeposit);
        DSCEngine engine = DSCEngine(DevOpsTools.get_most_recent_deployment("DSCEngine", block.chainid));

        vm.broadcast();
        _checkOperationSuccess(engine.depositAndMint{value: _amountToDeposit}(_amountToMint));

        (uint256 collateralDeposited, uint256 dscMinted, uint256 healthFactor) = engine.getPositionInfo(msg.sender);

        console2.log("Collateral deposited: %e", collateralDeposited);
        console2.log("DSC minted: %e", dscMinted);
        console2.log("Health factor: %e", healthFactor, "\n");
    }

    function _checkNativeBalance(address _account, uint256 _requested) private view {
        uint256 balance = _account.balance;

        if (_requested > balance) {
            revert DepositAndMint__InsufficientNativeBalance(balance, _requested);
        }
    }

    function _checkOperationSuccess(bool _success) private pure {
        if (!_success) {
            revert DepositAndMint__OperationFailed();
        }
    }
}

contract Redeem is Script {
    error Redeem__OperationFailed();

    function run() public {
        uint256 amount = vm.envUint("AMOUNT");
        _redeem(amount);
    }

    function _redeem(uint256 _amount) private {
        DSCEngine engine = DSCEngine(DevOpsTools.get_most_recent_deployment("DSCEngine", block.chainid));

        vm.broadcast();
        _checkOperationSuccess(engine.redeem(_amount));

        (uint256 collateralDeposited, uint256 dscMinted, uint256 healthFactor) = engine.getPositionInfo(msg.sender);

        console2.log("Collateral deposited: %e", collateralDeposited);
        console2.log("DSC minted: %e", dscMinted);
        console2.log("Health factor: %e", healthFactor, "\n");
    }

    function _checkOperationSuccess(bool _success) private pure {
        if (!_success) {
            revert Redeem__OperationFailed();
        }
    }
}

contract Burn is Script {
    error Burn__InsufficientTokenBalance(uint256 _balance, uint256 _requested);
    error Burn__OperationFailed();

    function run() public {
        uint256 amount = vm.envUint("AMOUNT");
        _burn(amount);
    }

    function _burn(uint256 _amount) private {
        DSCEngine engine = DSCEngine(DevOpsTools.get_most_recent_deployment("DSCEngine", block.chainid));
        IERC20 dsc = IERC20(DevOpsTools.get_most_recent_deployment("DSC", block.chainid));

        _checkTokenBalance(dsc, msg.sender, _amount);

        vm.startBroadcast();
        _checkOperationSuccess(dsc.approve(address(engine), _amount));
        _checkOperationSuccess(engine.burn(_amount));
        vm.stopBroadcast();

        (uint256 collateralDeposited, uint256 dscMinted, uint256 healthFactor) = engine.getPositionInfo(msg.sender);

        console2.log("Collateral deposited: %e", collateralDeposited);
        console2.log("DSC minted: %e", dscMinted);
        console2.log("Health factor: %e", healthFactor, "\n");
    }

    function _checkTokenBalance(IERC20 _token, address _account, uint256 _requested) private view {
        uint256 balance = _token.balanceOf(_account);

        if (_requested > balance) {
            revert Burn__InsufficientTokenBalance(balance, _requested);
        }
    }

    function _checkOperationSuccess(bool _success) private pure {
        if (!_success) {
            revert Burn__OperationFailed();
        }
    }
}

contract BurnAndRedeem is Script {
    error BurnAndRedeem__InsufficientTokenBalance(uint256 _balance, uint256 _requested);
    error BurnAndRedeem__OperationFailed();

    function run() public {
        uint256 amount = vm.envUint("AMOUNT");
        uint256 value = vm.envUint("VALUE");
        _burnAndRedeem(amount, value);
    }

    function _burnAndRedeem(uint256 _amountToBurn, uint256 _amountToRedeem) private {
        DSCEngine engine = DSCEngine(DevOpsTools.get_most_recent_deployment("DSCEngine", block.chainid));
        IERC20 dsc = IERC20(DevOpsTools.get_most_recent_deployment("DSC", block.chainid));

        _checkTokenBalance(dsc, msg.sender, _amountToBurn);

        vm.startBroadcast();
        _checkOperationSuccess(dsc.approve(address(engine), _amountToBurn));
        _checkOperationSuccess(engine.burnAndRedeem(_amountToBurn, _amountToRedeem));
        vm.stopBroadcast();

        (uint256 collateralDeposited, uint256 dscMinted, uint256 healthFactor) = engine.getPositionInfo(msg.sender);

        console2.log("Collateral deposited: %e", collateralDeposited);
        console2.log("DSC minted: %e", dscMinted);
        console2.log("Health factor: %e", healthFactor, "\n");
    }

    function _checkTokenBalance(IERC20 _token, address _account, uint256 _requested) private view {
        uint256 balance = _token.balanceOf(_account);

        if (_requested > balance) {
            revert BurnAndRedeem__InsufficientTokenBalance(balance, _requested);
        }
    }

    function _checkOperationSuccess(bool _success) private pure {
        if (!_success) {
            revert BurnAndRedeem__OperationFailed();
        }
    }
}

contract Liquidate is Script {
    error Liquidate__InsufficientTokenBalance(uint256 _balance, uint256 _requested);
    error Liquidate__OperationFailed();

    function run() public {
        address user = vm.envAddress("USER");
        uint256 debtToCover = vm.envUint("DEBT_TO_COVER");
        _liquidate(user, debtToCover);
    }

    function _liquidate(address _user, uint256 _debtToCover) private {
        DSCEngine engine = DSCEngine(DevOpsTools.get_most_recent_deployment("DSCEngine", block.chainid));
        IERC20 dsc = IERC20(DevOpsTools.get_most_recent_deployment("DSC", block.chainid));

        _checkTokenBalance(dsc, msg.sender, _debtToCover);

        vm.startBroadcast();
        _checkOperationSuccess(dsc.approve(address(engine), _debtToCover));
        _checkOperationSuccess(engine.liquidate(_user, _debtToCover));
        vm.stopBroadcast();

        (uint256 collateralDeposited, uint256 dscMinted, uint256 healthFactor) = engine.getPositionInfo(msg.sender);

        console2.log("Collateral deposited: %e", collateralDeposited);
        console2.log("DSC minted: %e", dscMinted);
        console2.log("Health factor: %e", healthFactor, "\n");
    }

    function _checkTokenBalance(IERC20 _token, address _account, uint256 _requested) private view {
        uint256 balance = _token.balanceOf(_account);

        if (_requested > balance) {
            revert Liquidate__InsufficientTokenBalance(balance, _requested);
        }
    }

    function _checkOperationSuccess(bool _success) private pure {
        if (!_success) {
            revert Liquidate__OperationFailed();
        }
    }
}

contract GetPositionInfo is Script {
    function run() public view {
        address user = vm.envAddress("USER");
        _getPositionInfo(user);
    }

    function _getPositionInfo(address _user) private view {
        DSCEngine engine = DSCEngine(DevOpsTools.get_most_recent_deployment("DSCEngine", block.chainid));

        (uint256 collateralDeposited, uint256 dscMinted, uint256 healthFactor) = engine.getPositionInfo(_user);

        console2.log("Collateral deposited: %e", collateralDeposited);
        console2.log("DSC minted: %e", dscMinted);
        console2.log("Health factor: %e", healthFactor, "\n");
    }
}

contract GetPriceFeed is Script {
    function run() public view {
        _getPriceFeed();
    }

    function _getPriceFeed() private view {
        DSCEngine engine = DSCEngine(DevOpsTools.get_most_recent_deployment("DSCEngine", block.chainid));

        console2.log("Chainlink ETH/USD price feed: %s", engine.getPriceFeed(), "\n");
    }
}

contract GetDSC is Script {
    function run() public view {
        _getDSC();
    }

    function _getDSC() private view {
        DSCEngine engine = DSCEngine(DevOpsTools.get_most_recent_deployment("DSCEngine", block.chainid));

        console2.log("DSC token: %s", engine.getDSC(), "\n");
    }
}

contract GetTotalDepositedCollateral is Script {
    function run() public view {
        _getTotalDepositedCollateral();
    }

    function _getTotalDepositedCollateral() private view {
        DSCEngine engine = DSCEngine(DevOpsTools.get_most_recent_deployment("DSCEngine", block.chainid));

        console2.log("Total ETH deposited: %e", engine.getTotalDepositedCollateral(), "\n");
    }
}

contract GetDSCSupply is Script {
    function run() public view {
        _getDSCSupply();
    }

    function _getDSCSupply() private view {
        DSCEngine engine = DSCEngine(DevOpsTools.get_most_recent_deployment("DSCEngine", block.chainid));

        console2.log("DSC total supply: %e", engine.getDSCSupply(), "\n");
    }
}
