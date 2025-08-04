// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {IERC20} from "@openzeppelin/token/ERC20/IERC20.sol";
import {Test} from "forge-std/Test.sol";
import {DSC} from "../src/DSC.sol";
import {DSCEngine} from "../src/DSCEngine.sol";
import {MockV3Aggregator} from "./mocks/MockV3Aggregator.sol";
import {User} from "./utils/User.sol";
import {UIntTypeMaxValues} from "./utils/UIntTypeMaxValues.sol";
import {InvalidNativeRecipient} from "./mocks/InvalidNativeRecipient.sol";
import {DeploySystem} from "../scripts/DeploySystem.s.sol";
import {MockOracleLib} from "./mocks/MockOracleLib.sol";

abstract contract BaseTest is Test, UIntTypeMaxValues {
    // Constants
    uint256 public constant TIMEOUT = 3 hours;
    uint256 public constant ETH_SUPPLY = 120_000_000 ether;
    uint8 public constant ETH_USD_PRICE_FEED_DECIMALS = 8;
    int256 public constant ETH_USD_PRICE_FEED_INITIAL_PRICE = 2_500e8;
    bytes32 public constant DEPOSITED_EVENT_SIGNATURE = keccak256("Deposited(address,uint256)");
    bytes32 public constant MINTED_EVENT_SIGNATURE = keccak256("Minted(address,uint256)");
    bytes32 public constant REDEEMED_EVENT_SIGNATURE = keccak256("Redeemed(address,address,uint256)");
    bytes32 public constant BURNED_EVENT_SIGNATURE = keccak256("Burned(address,uint256)");
    bytes32 public constant LIQUIDATED_EVENT_SIGNATURE = keccak256("Liquidated(address,address,uint256,uint256)");
    bytes32 public constant ERC20_TRANSFER_EVENT_SIGNATURE = keccak256("Transfer(address,address,uint256)");
    bytes32 public constant ERC20_APPROVE_EVENT_SIGNATURE = keccak256("Approval(address,address,uint256)");

    // Mocks
    InvalidNativeRecipient public invalidNativeRecipient;
    MockV3Aggregator public ethUsdPriceFeed;
    MockOracleLib public mockOracleLib;

    // Target contracts
    DSC public dsc;
    DSCEngine public engine;

    // Accounts
    address public NATIVE_WHALE = makeAddr("NATIVE_WHALE");
    User public user1;
    User public user2;

    // DSCEngine events
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

    // ERC20 Token Standard events
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    error BaseTest__NativeDonationFailed(address _to);

    function setUp() public virtual {
        _warpAndRoll(12, 1);

        DeploySystem deployer = new DeploySystem();

        (address _dsc, address _engine, address _ethUsdPriceFeed) = deployer.run();
        dsc = DSC(_dsc);
        engine = DSCEngine(_engine);
        ethUsdPriceFeed = MockV3Aggregator(_ethUsdPriceFeed);

        user1 = new User(dsc, engine);
        user2 = new User(dsc, engine);
        invalidNativeRecipient = new InvalidNativeRecipient();
        mockOracleLib = new MockOracleLib(_ethUsdPriceFeed);

        vm.deal(NATIVE_WHALE, ETH_SUPPLY);
    }

    /*//////////////////////////////////////////////////////////////
                               ASSERTIONS
    //////////////////////////////////////////////////////////////*/

    function _assertNativeBalance(address _account, uint256 _expectedBalance) internal view {
        uint256 actualBalance = address(_account).balance;
        assertEq(_expectedBalance, actualBalance, "Incorrect native balance");
    }

    function _assertERC20Balance(address _account, address _token, uint256 _expectedBalance) internal view {
        uint256 actualBalance = IERC20(_token).balanceOf(_account);
        assertEq(_expectedBalance, actualBalance, "Incorrect token balance");
    }

    function _assertTokenSupply(address _token, uint256 _expectedSupply) internal view {
        uint256 actualSupply = IERC20(_token).totalSupply();
        assertEq(_expectedSupply, actualSupply, "Incorrect DSC supply");
    }

    function _assertPositionDepositedCollateral(address _user, uint256 _expectedAmount) internal view {
        (uint256 collateralDeposited, , ) = engine.getPositionInfo(_user);
        assertEq(_expectedAmount, collateralDeposited, "Incorrect position collateral deposited.");
    }

    function _assertPositionDSCMinted(address _user, uint256 _expectedAmount) internal view {
        (, uint256 dscMinted, ) = engine.getPositionInfo(_user);
        assertEq(_expectedAmount, dscMinted, "Incorrect position DSC minted.");
    }

    function _assertPositionHealthFactor(address _user, uint256 _expectedHeathFactor) internal view {
        (, , uint256 actualHealthFactor) = engine.getPositionInfo(_user);
        assertEq(_expectedHeathFactor, actualHealthFactor, "Incorrect position's health factor.");
    }

    function _assertTotalDepositedCollateral(uint256 _expectedAmount) internal view {
        uint256 actualAmount = engine.getTotalDepositedCollateral();
        assertEq(_expectedAmount, actualAmount, "Incorrect total collateral deposited.");
    }

    function _assertDSCOwner(address _expectedOwner) internal view {
        address owner = dsc.owner();
        assertEq(_expectedOwner, owner, "Incorrect DSC token owner.");
    }

    function _assertNotDSCOwner(address _account) internal view {
        address owner = dsc.owner();
        assertNotEq(_account, owner, "Random account is owner.");
    }

    /*//////////////////////////////////////////////////////////////
                                HELPERS
    //////////////////////////////////////////////////////////////*/

    function _updatePrice(MockV3Aggregator _priceFeed, int256 _newPrice) internal {
        _priceFeed.updateAnswer(_newPrice);
    }

    function _donateNative(address _to, uint256 _amount) internal {
        vm.prank(NATIVE_WHALE, NATIVE_WHALE);
        (bool success, bytes memory reason) = payable(_to).call{value: _amount}(hex"");

        if (!success) {
            if (reason.length == 0) {
                revert BaseTest__NativeDonationFailed(_to);
            }

            assembly {
                revert(add(0x20, reason), mload(reason))
            }
        }
    }

    function _warp(uint256 _seconds) internal {
        vm.warp(vm.getBlockTimestamp() + _seconds);
    }

    function _roll(uint256 _blocks) internal {
        vm.roll(vm.getBlockNumber() + _blocks);
    }

    function _warpAndRoll(uint256 _seconds, uint256 _blocks) internal {
        vm.warp(vm.getBlockTimestamp() + _seconds);
        vm.roll(vm.getBlockNumber() + _blocks);
    }
}
