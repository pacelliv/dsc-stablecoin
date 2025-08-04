// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {BaseTest} from "../BaseTest.t.sol";
import {OracleLib} from "../../src/libraries/OracleLib.sol";

contract OracleLibUnit is BaseTest {
    function setUp() public override {
        super.setUp();
    }

    /// @dev Gets data if the data is updated before reaching the timeout.
    function test_succeeds_if_price_is_updated_before_timeout() public {
        _warp(TIMEOUT);
        mockOracleLib.getLatestRoundData();
    }

    /// @dev Cannot get data is timeout is reached.
    function test_revert_if_last_update_exceed_timeout() public {
        _warp(TIMEOUT + 1);

        vm.expectRevert(OracleLib.OracleLib__StalePriceFeed.selector);
        mockOracleLib.getLatestRoundData();
    }

    /// @dev Cannot get data is the round is not updated.
    function test_revert_if_updated_at_is_zero() public {
        ethUsdPriceFeed.updateRoundData(0, 1, 0, 0);

        vm.expectRevert(OracleLib.OracleLib__StalePriceFeed.selector);
        mockOracleLib.getLatestRoundData();
    }
}
