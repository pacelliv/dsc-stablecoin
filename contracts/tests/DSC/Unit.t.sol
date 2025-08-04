// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {BaseTest} from "../BaseTest.t.sol";
import {IERC20Errors} from "@openzeppelin/interfaces/draft-IERC6093.sol";

contract UnitDSC is BaseTest {
    function setUp() public override {
        super.setUp();
    }

    /// @dev Assert user can transfer DSC.
    function test_transfer_succeeds() public {
        _donateNative(address(user1), 1 ether);
        user1.depositAndMint(1 ether, 1250 ether);
        _assertERC20Balance(address(user1), address(dsc), 1250 ether);
        _assertTokenSupply(address(dsc), 1250 ether);

        user1.transferDSC(address(user2), 625 ether);
        _assertERC20Balance(address(user1), address(dsc), 625 ether);
        _assertERC20Balance(address(user2), address(dsc), 625 ether);
        _assertTokenSupply(address(dsc), 1250 ether);
    }

    /// @dev Assert user cannot more than balance DSC.
    function test_user_cannot_transfer_more_than_balance() public {
        _donateNative(address(user1), 1 ether);
        user1.depositAndMint(1 ether, 1250 ether);
        _assertERC20Balance(address(user1), address(dsc), 1250 ether);
        _assertTokenSupply(address(dsc), 1250 ether);

        vm.expectRevert(
            abi.encodeWithSelector(
                IERC20Errors.ERC20InsufficientBalance.selector,
                address(user1),
                1250 ether,
                1250 ether + 1
            )
        );
        user1.transferDSC(address(user2), 1250 ether + 1);
        _assertERC20Balance(address(user1), address(dsc), 1250 ether);
        _assertERC20Balance(address(user2), address(dsc), 0);
        _assertTokenSupply(address(dsc), 1250 ether);
    }

    /// @dev Assert transfer emit `Transfer` event.
    function test_transfer_emit_event() public {
        _donateNative(address(user1), 1 ether);
        user1.depositAndMint(1 ether, 1250 ether);
        _assertERC20Balance(address(user1), address(dsc), 1250 ether);
        _assertTokenSupply(address(dsc), 1250 ether);

        vm.expectEmit(true, true, false, true, address(dsc));
        emit Transfer(address(user1), address(user2), 625 ether);
        user1.transferDSC(address(user2), 625 ether);
        _assertERC20Balance(address(user1), address(dsc), 625 ether);
        _assertERC20Balance(address(user2), address(dsc), 625 ether);
        _assertTokenSupply(address(dsc), 1250 ether);
    }
}
