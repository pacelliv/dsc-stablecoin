// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {OracleLib} from "../../src/libraries/OracleLib.sol";
import {AggregatorV3Interface} from "../../src/interfaces/AggregatorV3Interface.sol";

contract MockOracleLib {
    using OracleLib for AggregatorV3Interface;

    AggregatorV3Interface private immutable i_priceFeed;

    constructor(address _priceFeed) {
        i_priceFeed = AggregatorV3Interface(_priceFeed);
    }

    function getLatestRoundData() external view returns (uint80, int256, uint256, uint256) {
        return i_priceFeed.getPriceFeedLatestRoundData();
    }

    function getPriceFeed() external view returns (address) {
        return address(i_priceFeed);
    }
}
