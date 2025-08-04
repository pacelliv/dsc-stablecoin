// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Script} from "forge-std/Script.sol";
import {MockV3Aggregator} from "../tests/mocks/MockV3Aggregator.sol";

abstract contract AccountSettings {
    // senders
    address constant TESTNET_DEFAULT_SENDER = 0xCc8188e984b4C392091043CAa73D227Ef5e0d0a7;
    address constant ANVIL_DEFAULT_SENDER = 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266;
}

abstract contract NetworkSettings {
    // chain ids
    uint256 constant ETHEREUM_MAINNET_CHAIN_ID = 1;
    uint256 constant ETHEREUM_SEPOLIA_CHAIN_ID = 11_155_111;
    uint256 constant ETHEREUM_ANVIL_CHAIN_ID = 31_337;
    uint256 constant ARBITRUM_MAINNET_CHAIN_ID = 42_161;
    uint256 constant ARBITRUM_SEPOLIA_CHAIN_ID = 421_614;
    uint256 constant ZKSYNC_MAINNET_CHAIN_ID = 324;
    uint256 constant ZKSYNC_SEPOLIA_CHAIN_ID = 300;
}

abstract contract ChainlinkServicesSettings {
    // Ethereum Sepolia settings
    address constant ETHEREUM_SEPOLIA_ETH_USD_PRICE_FEED = 0x694AA1769357215DE4FAC081bf1f309aDC325306;

    // Ethereum Anvil settings
    uint8 constant PRICE_FEED_DECIMALS = 8;
    int256 constant ETH_USD_PRICE_FEED_INITIAL_PRICE = 2500e8;
}

contract HelperConfig is Script, AccountSettings, NetworkSettings, ChainlinkServicesSettings {
    struct NetworkConfig {
        address account;
        address ethUsdPriceFeed;
    }

    error HelperConfig__NetworkNotSupported(uint256 _chainId);

    function getNetworkConfigByChainId(uint256 _chainId) external returns (NetworkConfig memory) {
        if (_chainId == ETHEREUM_SEPOLIA_CHAIN_ID) {
            return _createEthSepoliaConfig();
        } else if (_chainId == ETHEREUM_ANVIL_CHAIN_ID) {
            return _createEthAnvilConfig();
        }

        revert HelperConfig__NetworkNotSupported(_chainId);
    }

    function _createEthAnvilConfig() internal returns (NetworkConfig memory) {
        vm.broadcast();
        MockV3Aggregator ethUsdPriceFeed = new MockV3Aggregator(PRICE_FEED_DECIMALS, ETH_USD_PRICE_FEED_INITIAL_PRICE);
        return NetworkConfig({account: ANVIL_DEFAULT_SENDER, ethUsdPriceFeed: address(ethUsdPriceFeed)});
    }

    function _createEthSepoliaConfig() internal pure returns (NetworkConfig memory) {
        return NetworkConfig({account: TESTNET_DEFAULT_SENDER, ethUsdPriceFeed: ETHEREUM_SEPOLIA_ETH_USD_PRICE_FEED});
    }
}
