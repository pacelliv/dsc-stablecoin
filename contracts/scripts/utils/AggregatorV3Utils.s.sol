// SPDX-License-Identifier: MIT
pragma solidity 0.8.30;

import {DevOpsTools} from "foundry-devops/DevOpsTools.sol";
import {console2} from "forge-std/console2.sol";
import {Script} from "forge-std/Script.sol";
import {MockV3Aggregator} from "../../tests/mocks/MockV3Aggregator.sol";

contract UpdatePrice is Script {
    function run() public {
        int256 newPrice = vm.envInt("NEW_PRICE");
        _updatePrice(newPrice);
    }

    function _updatePrice(int256 _newPrice) private {
        address mock = DevOpsTools.get_most_recent_deployment("MockV3Aggregator", block.chainid);
        vm.broadcast();
        MockV3Aggregator(mock).updateAnswer(_newPrice);
    }
}

contract UpdateRoundData is Script {
    function run() public {
        int256 newPrice = vm.envInt("NEW_PRICE");
        _updateRoundData(newPrice);
    }

    function _updateRoundData(int256 _newPrice) private {
        address mock = DevOpsTools.get_most_recent_deployment("MockV3Aggregator", block.chainid);
        uint256 latestRound = MockV3Aggregator(mock).latestRound();
        vm.broadcast();
        MockV3Aggregator(mock).updateRoundData(uint80(latestRound + 1), _newPrice, block.timestamp, block.timestamp);
    }
}

contract GetLatestPrice is Script {
    function run() public view {
        _getLatestPrice();
    }

    function _getLatestPrice() private view {
        address mock = DevOpsTools.get_most_recent_deployment("MockV3Aggregator", block.chainid);
        int256 latestPrice = MockV3Aggregator(mock).latestAnswer();
        console2.log("Latest price: %e", uint256(latestPrice));
    }
}

contract GetLatestRoundData is Script {
    function run() public view {
        _getLatestRoundData();
    }

    function _getLatestRoundData() private view {
        address mock = DevOpsTools.get_most_recent_deployment("MockV3Aggregator", block.chainid);
        (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, ) = MockV3Aggregator(mock)
            .latestRoundData();
        console2.log("Latest round id: %s", uint256(roundId));
        console2.log("Latest price: %e", uint256(answer));
        console2.log("Latest round started at: %s", startedAt);
        console2.log("Latest round updated at: %s", updatedAt);
    }
}

contract GetRoundData is Script {
    function run() public view {
        uint256 roundId = vm.envUint("ROUND_ID");
        _getRoundData(uint80(roundId));
    }

    function _getRoundData(uint80 _roundId) private view {
        address mock = DevOpsTools.get_most_recent_deployment("MockV3Aggregator", block.chainid);
        (uint80 roundId, int256 answer, uint256 startedAt, uint256 updatedAt, ) = MockV3Aggregator(mock).getRoundData(
            _roundId
        );
        console2.log("Latest round id: %s", uint256(roundId));
        console2.log("Latest price: %e", uint256(answer));
        console2.log("Latest round started at: %s", startedAt);
        console2.log("Latest round updated at: %s", updatedAt);
    }
}
