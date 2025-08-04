// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {AggregatorV3Interface} from "../interfaces/AggregatorV3Interface.sol";

library OracleLib {
    uint256 private constant TIMEOUT = 3 hours;

    error OracleLib__StalePriceFeed();

    /// @notice Checks for stale price for the Chainlink price feed.
    /// @dev If stale price found, reverts. There is no fallback in case of stale price.
    /// @param _priceFeed Price feed to query for price.
    /// @return roundId The current round identifier.
    /// @return anwer The current price of the asset.
    /// @return startedAt The timestamp of when the round started.
    /// @return updatedAt The timestamp of when the round was updated.
    function getPriceFeedLatestRoundData(
        AggregatorV3Interface _priceFeed
    ) internal view returns (uint80, int256, uint256, uint256) {
        (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, ) = _priceFeed.latestRoundData();

        checkForStaleResponse(updatedAt);

        return (roundId, answer, startedAt, updatedAt);
    }

    function checkForStaleResponse(uint256 _updatedAt) internal view {
        if (_updatedAt == 0) {
            revert OracleLib__StalePriceFeed();
        }

        uint256 secondsPassed = block.timestamp - _updatedAt;

        if (secondsPassed > TIMEOUT) {
            revert OracleLib__StalePriceFeed();
        }
    }
}
