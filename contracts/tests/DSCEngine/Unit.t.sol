// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {Vm} from "forge-std/Vm.sol";
import {console2} from "forge-std/console2.sol";
import {BaseTest} from "../BaseTest.t.sol";
import {DSCEngine} from "../../src/DSCEngine.sol";

contract DSCEngineUnit is BaseTest {
    function setUp() public override {
        super.setUp();
    }

    /*//////////////////////////////////////////////////////////////
                             DEPOSIT TESTS
    //////////////////////////////////////////////////////////////*/

    /// @dev After deployment the DSC owner should be the engine.
    function test_dsc_owner() public view {
        address expectedOwner = address(engine);
        _assertDSCOwner(address(expectedOwner));
    }

    /// @dev After deployment the DSC owner should be the engine.
    function test_not_owner(address _account) public view {
        vm.assume(_account != address(engine));
        _assertNotDSCOwner(_account);
    }

    /// @dev Assert is not possible to deposit zero collateral.
    function test_user_cannot_deposit_zero_collateral() public {
        _donateNative(address(user1), 1 ether);
        _assertPositionHealthFactor(address(user1), MAX_UINT256);

        vm.expectRevert(DSCEngine.DSCEngine__ZeroAmount.selector);
        bool success = user1.depositCollateral(0);
        assertFalse(success, "Deposits should have failed.");
        _assertPositionDepositedCollateral(address(user1), 0);
        _assertTotalDepositedCollateral(0);
        _assertPositionHealthFactor(address(user1), MAX_UINT256);
        _assertTokenSupply(address(dsc), 0);
    }

    /// @dev Assert deposit workflow works as expected.
    function test_user_deposit_collateral() public {
        _donateNative(address(user1), 1 ether);
        _assertPositionHealthFactor(address(user1), MAX_UINT256);

        bool success = user1.depositCollateral(1 ether);
        assertTrue(success, "Deposit failed.");
        _assertPositionDepositedCollateral(address(user1), 1 ether);
        _assertTotalDepositedCollateral(1 ether);
        _assertPositionHealthFactor(address(user1), MAX_UINT256);
        _assertTokenSupply(address(dsc), 0);
    }

    /// @dev Assert `deposit` emits `Deposited` event with the correct parameters.
    function test_deposit_function_emit_event() public {
        _donateNative(address(user1), 1 ether);
        _assertPositionHealthFactor(address(user1), MAX_UINT256);

        vm.expectEmit(true, false, false, true, address(engine));

        emit Deposited(address(user1), 1 ether);
        bool success = user1.depositCollateral(1 ether);

        assertTrue(success, "Deposit failed.");
        _assertPositionDepositedCollateral(address(user1), 1 ether);
        _assertTotalDepositedCollateral(1 ether);
        _assertPositionHealthFactor(address(user1), MAX_UINT256);
        _assertTokenSupply(address(dsc), 0);
    }

    /*//////////////////////////////////////////////////////////////
                               MINT TESTS
    //////////////////////////////////////////////////////////////*/

    /// @dev Assert is not possible to mint zero stablecoin.
    function test_cannot_mint_zero_stablecoin() public {
        _assertPositionHealthFactor(address(user1), MAX_UINT256);
        vm.expectRevert(DSCEngine.DSCEngine__ZeroAmount.selector);
        user1.mintStablecoin(0);
        _assertPositionHealthFactor(address(user1), MAX_UINT256);
        _assertTokenSupply(address(dsc), 0);
    }

    /// @dev Assert mint workflow works as expected.
    function test_user_mint_stablecoin() public {
        _donateNative(address(user1), 1 ether);
        _assertPositionHealthFactor(address(user1), MAX_UINT256);

        user1.depositCollateral(1 ether);
        bool success = user1.mintStablecoin(1250 ether);

        assertTrue(success, "Mint failed.");
        _assertERC20Balance(address(user1), address(dsc), 1250 ether);
        _assertTokenSupply(address(dsc), 1250 ether);
        _assertPositionDepositedCollateral(address(user1), 1 ether);
        _assertPositionDSCMinted(address(user1), 1250 ether);
        _assertPositionHealthFactor(address(user1), 1 ether);
    }

    /// @dev Assert user cannot mint with a broken health factor.
    function test_user_cannot_mint_with_broken_health_factor() public {
        _donateNative(address(user1), 1 ether);
        _assertPositionHealthFactor(address(user1), MAX_UINT256);

        user1.depositCollateral(1 ether);
        // first mint
        bool success = user1.mintStablecoin(1250 ether);

        assertTrue(success, "Mint failed.");
        _assertERC20Balance(address(user1), address(dsc), 1250 ether);
        _assertTokenSupply(address(dsc), 1250 ether);
        _assertPositionDepositedCollateral(address(user1), 1 ether);
        _assertPositionDSCMinted(address(user1), 1250 ether);
        _assertPositionHealthFactor(address(user1), 1 ether);

        // second mint
        vm.expectRevert(DSCEngine.DSCEngine__BrokenHealthFactor.selector);
        success = user1.mintStablecoin(1);

        assertFalse(success, "Mint should have failed.");
        _assertERC20Balance(address(user1), address(dsc), 1250 ether);
        _assertTokenSupply(address(dsc), 1250 ether);
        _assertPositionDepositedCollateral(address(user1), 1 ether);
        _assertPositionDSCMinted(address(user1), 1250 ether);
        _assertPositionHealthFactor(address(user1), 1 ether);
    }

    /// @dev Assert `mint` emits `Minted` event with the correct parameters.
    function test_mint_function_emit_event() public {
        _donateNative(address(user1), 1 ether);
        _assertPositionHealthFactor(address(user1), MAX_UINT256);

        user1.depositCollateral(1 ether);
        vm.expectEmit(true, false, false, true, address(engine));
        emit Minted(address(user1), 1250 ether);
        bool success = user1.mintStablecoin(1250 ether);

        assertTrue(success, "Mint failed.");
        _assertERC20Balance(address(user1), address(dsc), 1250 ether);
        _assertTokenSupply(address(dsc), 1250 ether);
        _assertPositionDepositedCollateral(address(user1), 1 ether);
        _assertPositionDSCMinted(address(user1), 1250 ether);
        _assertPositionHealthFactor(address(user1), 1 ether);
    }

    /*//////////////////////////////////////////////////////////////
                         DEPOSIT AND MINT TESTS
    //////////////////////////////////////////////////////////////*/

    /// @dev Assert `depositAndMint` workflow works as expected.
    function test_user_deposit_and_mint_in_one_transaction() public {
        _donateNative(address(user1), 1 ether);
        _assertPositionDepositedCollateral(address(user1), 0);
        _assertTotalDepositedCollateral(0);
        _assertPositionHealthFactor(address(user1), MAX_UINT256);

        bool success = user1.depositAndMint(1 ether, 1250 ether);
        assertTrue(success, "Deposit and mint failed.");
        _assertPositionDepositedCollateral(address(user1), 1 ether);
        _assertTotalDepositedCollateral(1 ether);
        _assertPositionHealthFactor(address(user1), 1 ether);
        _assertERC20Balance(address(user1), address(dsc), 1250 ether);
        _assertTokenSupply(address(dsc), 1250 ether);
    }

    /// @dev Assert `depositAndMint` reverts if amount to deposit is zero.
    function test_deposit_and_mint_fail_if_deposit_amount_is_zero() public {
        _donateNative(address(user1), 1 ether);
        _assertPositionDepositedCollateral(address(user1), 0);
        _assertTotalDepositedCollateral(0);
        _assertPositionHealthFactor(address(user1), MAX_UINT256);

        vm.expectRevert(DSCEngine.DSCEngine__ZeroAmount.selector);
        bool success = user1.depositAndMint(0, 1250 ether);
        assertFalse(success, "Deposit and mint not failed.");
        _assertPositionDepositedCollateral(address(user1), 0);
        _assertTotalDepositedCollateral(0);
        _assertPositionHealthFactor(address(user1), MAX_UINT256);
        _assertERC20Balance(address(user1), address(dsc), 0);
        _assertTokenSupply(address(dsc), 0);
    }

    /// @dev Assert `depositAndMint` reverts if the user try to mint with a broken health factor.
    function test_deposit_and_mint_fail_if_user_has_broken_health_factor() public {
        _donateNative(address(user1), 1 ether);
        _assertPositionDepositedCollateral(address(user1), 0);
        _assertTotalDepositedCollateral(0);
        _assertPositionHealthFactor(address(user1), MAX_UINT256);

        vm.expectRevert(DSCEngine.DSCEngine__BrokenHealthFactor.selector);
        bool success = user1.depositAndMint(1 ether, 1250 ether + 1);
        assertFalse(success, "Deposit and mint not failed.");
        _assertPositionDepositedCollateral(address(user1), 0);
        _assertTotalDepositedCollateral(0);
        _assertPositionHealthFactor(address(user1), MAX_UINT256);
        _assertERC20Balance(address(user1), address(dsc), 0);
        _assertTokenSupply(address(dsc), 0);
    }

    /// @dev Assert `depositAndMint` emit `Deposited`, `Minted` and `Transfer` events.
    function test_deposit_and_mint_emit_events() public {
        _donateNative(address(user1), 1 ether);

        vm.recordLogs();
        user1.depositAndMint(1 ether, 1250 ether);

        Vm.Log[] memory logs = vm.getRecordedLogs();

        assertEq(logs.length, 3, "Incorrect number of recorded events.");

        // assertions for the `Deposited` event
        assertEq(logs[0].topics[0], DEPOSITED_EVENT_SIGNATURE, "Incorrect Deposited event sig.");
        assertEq(logs[0].topics[1], bytes32(uint256(uint160(address(user1)))), "Incorrect user address.");
        assertEq(abi.decode(logs[0].data, (uint256)), 1 ether, "Incorrect decoded deposited amount.");

        // assertions for the `Minted` event
        assertEq(logs[1].topics[0], MINTED_EVENT_SIGNATURE, "Incorrect Minted event sig.");
        assertEq(logs[1].topics[1], bytes32(uint256(uint160(address(user1)))), "Incorrect user address.");
        assertEq(abi.decode(logs[1].data, (uint256)), 1250 ether, "Incorrect decoded minted amount.");

        // assertions for the `Transfer` event
        assertEq(logs[2].topics[0], ERC20_TRANSFER_EVENT_SIGNATURE, "Incorrect Transfer event sig.");
        assertEq(logs[2].topics[1], bytes32(uint256(uint160(address(address(0))))), "Incorrect sender address.");
        assertEq(logs[2].topics[2], bytes32(uint256(uint160(address(address(user1))))), "Incorrect recipient address.");
        assertEq(abi.decode(logs[2].data, (uint256)), 1250 ether, "Incorrect decoded transferred amount.");
    }

    /*//////////////////////////////////////////////////////////////
                               BURN TESTS
    //////////////////////////////////////////////////////////////*/

    /// @dev Assert burn workflow works as expected.
    function test_user_can_burn_stablecoin() public {
        _donateNative(address(user1), 1 ether);

        bool success = user1.depositAndMint(1 ether, 1250 ether);
        assertTrue(success, "Deposit and mint failed.");
        _assertPositionDepositedCollateral(address(user1), 1 ether);
        _assertTotalDepositedCollateral(1 ether);
        _assertPositionHealthFactor(address(user1), 1 ether);
        _assertERC20Balance(address(user1), address(dsc), 1250 ether);
        _assertTokenSupply(address(dsc), 1250 ether);

        success = user1.burnStablecoin(1250 ether);
        assertTrue(success, "Burn failed.");
        _assertPositionDepositedCollateral(address(user1), 1 ether);
        _assertTotalDepositedCollateral(1 ether);
        _assertPositionHealthFactor(address(user1), MAX_UINT256);
        _assertERC20Balance(address(user1), address(dsc), 0);
        _assertTokenSupply(address(dsc), 0);
    }

    /// @dev Assert user cannot burn zero stablecoin.
    function test_user_cannot_burn_zero_amount() public {
        _donateNative(address(user1), 1 ether);

        bool success = user1.depositAndMint(1 ether, 1250 ether);
        assertTrue(success, "Deposit and mint failed.");
        _assertPositionDepositedCollateral(address(user1), 1 ether);
        _assertTotalDepositedCollateral(1 ether);
        _assertPositionHealthFactor(address(user1), 1 ether);
        _assertERC20Balance(address(user1), address(dsc), 1250 ether);
        _assertTokenSupply(address(dsc), 1250 ether);

        vm.expectRevert(DSCEngine.DSCEngine__ZeroAmount.selector);
        success = user1.burnStablecoin(0);
        assertFalse(success, "Burn did not failed.");
        _assertPositionDepositedCollateral(address(user1), 1 ether);
        _assertTotalDepositedCollateral(1 ether);
        _assertPositionHealthFactor(address(user1), 1 ether);
        _assertERC20Balance(address(user1), address(dsc), 1250 ether);
        _assertTokenSupply(address(dsc), 1250 ether);
    }

    /// @dev Assert user cannot burn zero stablecoin.
    function test_user_cannot_burn_beyond_balance() public {
        _donateNative(address(user1), 1 ether);

        bool success = user1.depositAndMint(1 ether, 1250 ether);
        assertTrue(success, "Deposit and mint failed.");
        _assertPositionDepositedCollateral(address(user1), 1 ether);
        _assertTotalDepositedCollateral(1 ether);
        _assertPositionHealthFactor(address(user1), 1 ether);
        _assertERC20Balance(address(user1), address(dsc), 1250 ether);
        _assertTokenSupply(address(dsc), 1250 ether);

        vm.expectRevert(DSCEngine.DSCEngine__InsufficientBalance.selector);
        success = user1.burnStablecoin(1250 ether + 1);
        assertFalse(success, "Burn did not failed.");
        _assertPositionDepositedCollateral(address(user1), 1 ether);
        _assertTotalDepositedCollateral(1 ether);
        _assertPositionHealthFactor(address(user1), 1 ether);
        _assertERC20Balance(address(user1), address(dsc), 1250 ether);
        _assertTokenSupply(address(dsc), 1250 ether);
    }

    /*//////////////////////////////////////////////////////////////
                             REDEEEM TESTS
    //////////////////////////////////////////////////////////////*/

    /// @dev Assert redeem workflow works as expected.
    function test_user_can_redeem() public {
        _donateNative(address(user1), 1 ether);

        bool success = user1.depositAndMint(1 ether, 1250 ether);
        assertTrue(success, "Deposit and mint failed.");
        _assertPositionDepositedCollateral(address(user1), 1 ether);
        _assertTotalDepositedCollateral(1 ether);
        _assertPositionHealthFactor(address(user1), 1 ether);
        _assertERC20Balance(address(user1), address(dsc), 1250 ether);
        _assertTokenSupply(address(dsc), 1250 ether);
        _assertNativeBalance(address(user1), 0);

        success = user1.burnStablecoin(1250 ether);
        assertTrue(success, "Burn failed");
        _assertPositionDepositedCollateral(address(user1), 1 ether);
        _assertTotalDepositedCollateral(1 ether);
        _assertPositionHealthFactor(address(user1), MAX_UINT256);
        _assertERC20Balance(address(user1), address(dsc), 0);
        _assertTokenSupply(address(dsc), 0);
        _assertNativeBalance(address(user1), 0);

        success = user1.redeemCollateral(1 ether);
        assertTrue(success, "Redeem failed");
        _assertPositionDepositedCollateral(address(user1), 0);
        _assertTotalDepositedCollateral(0);
        _assertPositionHealthFactor(address(user1), MAX_UINT256);
        _assertERC20Balance(address(user1), address(dsc), 0);
        _assertTokenSupply(address(dsc), 0);
        _assertNativeBalance(address(user1), 1 ether);
    }

    /// @dev Assert user cannot redeem zero collateral.
    function test_user_cannot_redeem_zero_collateral() public {
        _donateNative(address(user1), 1 ether);

        bool success = user1.depositAndMint(1 ether, 1250 ether);
        assertTrue(success, "Deposit and mint failed.");
        _assertPositionDepositedCollateral(address(user1), 1 ether);
        _assertTotalDepositedCollateral(1 ether);
        _assertPositionHealthFactor(address(user1), 1 ether);
        _assertERC20Balance(address(user1), address(dsc), 1250 ether);
        _assertTokenSupply(address(dsc), 1250 ether);
        _assertNativeBalance(address(user1), 0);

        vm.expectRevert(DSCEngine.DSCEngine__ZeroAmount.selector);
        success = user1.redeemCollateral(0);
        assertFalse(success, "Redeem did not failed");
        _assertPositionDepositedCollateral(address(user1), 1 ether);
        _assertTotalDepositedCollateral(1 ether);
        _assertPositionHealthFactor(address(user1), 1 ether);
        _assertERC20Balance(address(user1), address(dsc), 1250 ether);
        _assertTokenSupply(address(dsc), 1250 ether);
        _assertNativeBalance(address(user1), 0);
    }

    /// @dev Assert user cannot redeem if it breaks the health factor.
    /// @dev Position has 1 ETH at $2500, the current borrowed amount is $1250 worth of stablecoin,
    /// setting a health factor of 1, if the user tries to withdraw, just even, 1 wei of collateral,
    /// the operation must revert.
    function test_user_cannot_redeem_with_broken_health_factor() public {
        _donateNative(address(user1), 1 ether);

        bool success = user1.depositAndMint(1 ether, 1250 ether);
        assertTrue(success, "Deposit and mint failed.");
        _assertPositionDepositedCollateral(address(user1), 1 ether);
        _assertTotalDepositedCollateral(1 ether);
        _assertPositionHealthFactor(address(user1), 1 ether);
        _assertERC20Balance(address(user1), address(dsc), 1250 ether);
        _assertTokenSupply(address(dsc), 1250 ether);
        _assertNativeBalance(address(user1), 0);

        vm.expectRevert(DSCEngine.DSCEngine__BrokenHealthFactor.selector);
        success = user1.redeemCollateral(1);
        assertFalse(success, "Redeem did not failed");
        _assertPositionDepositedCollateral(address(user1), 1 ether);
        _assertTotalDepositedCollateral(1 ether);
        _assertPositionHealthFactor(address(user1), 1 ether);
        _assertERC20Balance(address(user1), address(dsc), 1250 ether);
        _assertTokenSupply(address(dsc), 1250 ether);
        _assertNativeBalance(address(user1), 0);
    }

    /// @dev Assert redeem emits event.
    function test_redeem_emits_event() public {
        _donateNative(address(user1), 1 ether);

        user1.depositAndMint(1 ether, 1250 ether);
        user1.burnStablecoin(1250 ether);

        vm.expectEmit(true, true, false, true, address(engine));
        emit Redeemed(address(user1), address(user1), 1 ether);
        user1.redeemCollateral(1 ether);
    }

    /*//////////////////////////////////////////////////////////////
                         BURN AND REDEEM TESTS
    //////////////////////////////////////////////////////////////*/

    /// @dev Assert user can redeem and burn in a single transaction.
    function test_redeem_and_burn_in_one_transaction() public {
        _donateNative(address(user1), 1 ether);

        bool success = user1.depositAndMint(1 ether, 1250 ether);
        assertTrue(success, "Deposit and mint failed.");
        _assertPositionDepositedCollateral(address(user1), 1 ether);
        _assertTotalDepositedCollateral(1 ether);
        _assertPositionHealthFactor(address(user1), 1 ether);
        _assertERC20Balance(address(user1), address(dsc), 1250 ether);
        _assertTokenSupply(address(dsc), 1250 ether);
        _assertNativeBalance(address(user1), 0);

        success = user1.burnAndRedeem(1250 ether, 1 ether);
        assertTrue(success, "Burn and redeeem failed");
        _assertPositionDepositedCollateral(address(user1), 0);
        _assertTotalDepositedCollateral(0);
        _assertPositionHealthFactor(address(user1), MAX_UINT256);
        _assertERC20Balance(address(user1), address(dsc), 0);
        _assertTokenSupply(address(dsc), 0);
        _assertNativeBalance(address(user1), 1 ether);
    }

    /// @dev Assert `burnAndRedeem` emit `Transfer`, `Burned`  and `Redeemed` events.
    function test_redeem_and_burn_emit_events() public {
        _donateNative(address(user1), 1 ether);

        user1.depositAndMint(1 ether, 1250 ether);

        vm.recordLogs();

        user1.burnAndRedeem(1250 ether, 1 ether);
        Vm.Log[] memory logs = vm.getRecordedLogs();

        assertEq(logs.length, 5, "Incorrect number of recorded events.");

        // assertions for the `Approve` event
        assertEq(logs[0].topics[0], ERC20_APPROVE_EVENT_SIGNATURE, "Incorrect Approve event sig.");
        assertEq(logs[0].topics[1], bytes32(uint256(uint160(address(user1)))), "Incorrect owner address.");
        assertEq(logs[0].topics[2], bytes32(uint256(uint160(address(engine)))), "Incorrect spender address.");
        assertEq(abi.decode(logs[0].data, (uint256)), 1250 ether, "Incorrect decoded approved amount.");

        // assertions for the `Transfer` event emitted by `transferFrom`
        assertEq(logs[1].topics[0], ERC20_TRANSFER_EVENT_SIGNATURE, "Incorrect Transfer event sig.");
        assertEq(logs[1].topics[1], bytes32(uint256(uint160(address(user1)))), "Incorrect sender address.");
        assertEq(logs[1].topics[2], bytes32(uint256(uint160(address(engine)))), "Incorrect recipient address.");
        assertEq(abi.decode(logs[0].data, (uint256)), 1250 ether, "Incorrect decoded transferred amount.");

        // assertions for the `Transfer` event emitted by `burn`
        assertEq(logs[2].topics[0], ERC20_TRANSFER_EVENT_SIGNATURE, "Incorrect Transfer event sig.");
        assertEq(logs[2].topics[1], bytes32(uint256(uint160(address(engine)))), "Incorrect sender address.");
        assertEq(logs[2].topics[2], bytes32(uint256(uint160(address(0)))), "Incorrect recipient address.");
        assertEq(abi.decode(logs[0].data, (uint256)), 1250 ether, "Incorrect decoded transferred amount.");

        // assertions for the `Burned` event
        assertEq(logs[3].topics[0], BURNED_EVENT_SIGNATURE, "Incorrect Burned event sig.");
        assertEq(logs[3].topics[1], bytes32(uint256(uint160(address(user1)))), "Incorrect user address.");
        assertEq(abi.decode(logs[1].data, (uint256)), 1250 ether, "Incorrect decoded burned amount.");

        // assertions for the `Redeemed` event
        assertEq(logs[4].topics[0], REDEEMED_EVENT_SIGNATURE, "Incorrect Redeemed event sig.");
        assertEq(logs[4].topics[1], bytes32(uint256(uint160(address(address(user1))))), "Incorrect user address.");
        assertEq(logs[4].topics[2], bytes32(uint256(uint160(address(address(user1))))), "Incorrect user address.");
        assertEq(abi.decode(logs[4].data, (uint256)), 1 ether, "Incorrect decoded redemeeded amount.");
    }

    /*//////////////////////////////////////////////////////////////
                            LIQUIDATE TESTS
    //////////////////////////////////////////////////////////////*/

    /// @dev Assert users with good health factor cannot be liquidated.
    function test_cannot_liquidate_a_user_with_health_health_factor() public {
        _donateNative(address(user1), 1 ether);
        _donateNative(address(user2), 1 ether);
        // Both users has a HF of 1.
        user1.depositAndMint(1 ether, 1250 ether);
        user2.depositAndMint(1 ether, 1250 ether);

        vm.expectRevert(DSCEngine.DSCEngine__UserCannotBeLiquidated.selector);
        bool success = user2.liquidatePosition(address(user1), 1250 ether);
        assertFalse(success, "Liquidation did not reverted.");
    }

    /// @dev Assert users with good health factor cannot be liquidated.
    function test_cannot_liquidate_a_beyond_user_debt() public {
        _donateNative(address(user1), 1 ether);
        _donateNative(address(user2), 10 ether);
        // ETH price @2500 => user1 hf = 2500 / 1100 = ~2.273
        user1.depositAndMint(1 ether, 1100 ether);
        user2.depositAndMint(10 ether, 1250 ether);

        // ETH price @2199 => user1 hf = 2199 / 1100 = ~1.999
        _updatePrice(ethUsdPriceFeed, 2199e8);

        vm.expectRevert(DSCEngine.DSCEngine__InsufficientDebt.selector);
        bool success = user2.liquidatePosition(address(user1), 1250 ether);
        assertFalse(success, "Liquidation did not reverted.");
    }

    /// @dev Assert cannot repay zero debt.
    function test_cannot_repay_zero_debt() public {
        _donateNative(address(user1), 1 ether);
        _donateNative(address(user2), 10 ether);
        // ETH price @2500 => user1 hf = 2500 / 1100 = ~2.273
        user1.depositAndMint(1 ether, 1100 ether);
        user2.depositAndMint(10 ether, 1250 ether);

        // ETH price @2199 => user1 hf = 2199 / 1100 = ~1.999
        _updatePrice(ethUsdPriceFeed, 2199e8);

        vm.expectRevert(DSCEngine.DSCEngine__ZeroAmount.selector);
        bool success = user2.liquidatePosition(address(user1), 0);
        assertFalse(success, "Liquidation did not reverted.");
    }

    /// @dev Assert liquidator can partially cover the debt.
    /// @dev Liquidator gets a 5% bonus of collateral from the user for liquidating.
    function test_user_can_partially_liquidate_position() public {
        _donateNative(address(user1), 1 ether);
        _donateNative(address(user2), 10 ether);

        // user deposits 1 ether worth $2500 and mints $1250 DSC
        user1.depositAndMint(1 ether, 1250 ether);
        _assertNativeBalance(address(user1), 0);
        _assertPositionDSCMinted(address(user1), 1250 ether);
        _assertPositionHealthFactor(address(user1), 1 ether);
        _assertPositionDepositedCollateral(address(user1), 1 ether);

        // user deposits 10 ether worth $25000 and mints $1000 DSC
        user2.depositAndMint(10 ether, 1000 ether);
        _assertNativeBalance(address(user2), 0);
        _assertPositionDSCMinted(address(user2), 1000 ether);
        _assertPositionHealthFactor(address(user2), 12.5 ether);
        _assertPositionDepositedCollateral(address(user2), 10 ether);

        // lower price from $2500 to $2499
        _updatePrice(ethUsdPriceFeed, 2499e8);
        _assertPositionHealthFactor(address(user1), 0.9996 ether);
        _assertPositionHealthFactor(address(user2), 12.495 ether);

        // The debt is 1250 DSC
        // User decides to liquidate 625 DSC (50% of debt)
        // ethAmount = 625e18 * 1e18 / 2499e18 = 0.250100040016006402 ether
        // bonus = ethAmount * 5 / 100 = 0.012505002000800320 ether
        // collateralLiquidated = ethAmount + bonus = 0.262605042016806722 ether
        bool success = user2.liquidatePosition(address(user1), 625 ether);
        assertTrue(success, "Liquidation failed.");

        // Assertion for user1
        _assertNativeBalance(address(user1), 0);
        _assertPositionDSCMinted(address(user1), 625 ether);
        // collateralUsdValue = (1e18 - 0.262605042016806722e18) * 2499e18 / 1e18 = 1842.750000000000001722 ether
        // collateralValueAdjustedForThreshold = collateralValueUsd * 50 / 100 = 921.375000000000000861 ether
        // hf = collateralValueAdjustedForThreshold * 1e18 / 625e18 = 1.474200000000000001 ether
        _assertPositionHealthFactor(address(user1), 1.474200000000000001 ether);
        _assertPositionDepositedCollateral(address(user1), 1 ether - 0.262605042016806722 ether);

        // Assertions for user2
        _assertNativeBalance(address(user2), 0.262605042016806722e18);
        _assertPositionDSCMinted(address(user2), 1000 ether);
        _assertPositionHealthFactor(address(user2), 12.495 ether);
        _assertPositionDepositedCollateral(address(user2), 10 ether);
    }

    /// @dev Assert liquidator can repay the entire debt.
    /// @dev Liquidator gets a 5% bonus of collateral from the user for liquidating.
    function test_user_can_liquidate_the_entire_position() public {
        _donateNative(address(user1), 1 ether);
        _donateNative(address(user2), 10 ether);

        // user deposits 1 ether worth $2500 and mints $1250 DSC
        user1.depositAndMint(1 ether, 1250 ether);
        _assertNativeBalance(address(user1), 0);
        _assertPositionDSCMinted(address(user1), 1250 ether);
        _assertPositionHealthFactor(address(user1), 1 ether);
        _assertPositionDepositedCollateral(address(user1), 1 ether);

        // user deposits 10 ether worth $25000 and mints $1250 DSC
        user2.depositAndMint(10 ether, 1250 ether);
        _assertNativeBalance(address(user2), 0);
        _assertPositionDSCMinted(address(user2), 1250 ether);
        _assertPositionHealthFactor(address(user2), 10 ether);
        _assertPositionDepositedCollateral(address(user2), 10 ether);

        // lower price from $2500 to $2499
        _updatePrice(ethUsdPriceFeed, 2499e8);
        _assertPositionHealthFactor(address(user1), 0.9996 ether);
        _assertPositionHealthFactor(address(user2), 9.996 ether);

        // The debt is 1250 DSC
        // User decides to liquidate 1250 DSC (100% of debt)
        // ethAmount = 1250e18 * 1e18 / 2499e18 = 0.500200080032012805 ether
        // bonus = ethAmount * 5 / 100 = 0.025010004001600640 ether
        // collateralLiquidated = ethAmount + bonus = 0.525210084033613445 ether
        bool success = user2.liquidatePosition(address(user1), 1250 ether);
        assertTrue(success, "Liquidation failed.");

        // Assertion for user1
        _assertNativeBalance(address(user1), 0);
        _assertPositionDSCMinted(address(user1), 0 ether);
        // collateralUsdValue = (1e18 - 0.525210084033613445e18) * 2499e18 / 1e18 = 1186.500000000000000945 ether
        // collateralValueAdjustedForThreshold = collateralValueUsd * 50 / 100 = 593.250000000000000472 ether
        // hf = collateralValueAdjustedForThreshold * 1e18 / 0 = MAX_UINT256
        _assertPositionHealthFactor(address(user1), MAX_UINT256);
        _assertPositionDepositedCollateral(address(user1), 1 ether - 0.525210084033613445 ether);

        // Assertions for user2
        _assertNativeBalance(address(user2), 0.525210084033613445e18);
        _assertPositionDSCMinted(address(user2), 1250 ether);
        _assertPositionHealthFactor(address(user2), 9.996 ether);
        _assertPositionDepositedCollateral(address(user2), 10 ether);
    }

    /*//////////////////////////////////////////////////////////////
                           VIEW METHODS TESTS
    //////////////////////////////////////////////////////////////*/

    /// @dev Assert `PRECISION` value
    function test_get_precision() public view {
        uint256 actualValue = 1 ether;
        assertEq(engine.PRECISION(), actualValue, "Incorrect precision.");
    }

    /// @dev Assert `PRICE_FEED_PRECISION` value
    function test_get_price_feed_precision() public view {
        uint256 actualValue = 1e10;
        assertEq(engine.PRICE_FEED_PRECISION(), actualValue, "Incorrect price feed precision.");
    }

    /// @dev Assert `MINIMUM_HEALTH_FACTOR` value
    function test_get_minimum_health_factor() public view {
        uint256 actualValue = 1 ether;
        assertEq(engine.MINIMUM_HEALTH_FACTOR(), actualValue, "Incorrect minimum health factor.");
    }

    /// @dev Assert `LIQUIDATION_THRESHOLD` value
    function test_get_liquidation_threshold() public view {
        uint256 actualValue = 50;
        assertEq(engine.LIQUIDATION_THRESHOLD(), actualValue, "Incorrect liquidation threshold.");
    }

    /// @dev Assert `LIQUIDATION_PRECISION` value
    function test_get_liquidation_precision() public view {
        uint256 actualValue = 100;
        assertEq(engine.LIQUIDATION_PRECISION(), actualValue, "Incorrect liquidation precision.");
    }

    /// @dev Assert `LIQUIDATION_BONUS` value
    function test_get_liquidation_bonus() public view {
        uint256 actualValue = 5;
        assertEq(engine.LIQUIDATION_BONUS(), actualValue, "Incorrect liquidation bonus.");
    }
}
