/// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Script} from "forge-std/Script.sol";
import {DSC} from "../src/DSC.sol";
import {DSCEngine} from "../src/DSCEngine.sol";
import {HelperConfig} from "./HelperConfig.s.sol";

contract DeploySystem is Script {
    error Deploy__WrongOwner();
    error Deploy__WrongEthUsdPriceFeed();
    error Deploy__WrongDscAddress();

    function run() public returns (address, address, address) {
        return _deploy();
    }

    function _deploy() private returns (address, address, address) {
        HelperConfig helper = new HelperConfig();
        HelperConfig.NetworkConfig memory config = helper.getNetworkConfigByChainId(block.chainid);

        vm.startBroadcast();
        DSC dsc = new DSC();
        DSCEngine engine = new DSCEngine(address(dsc), address(config.ethUsdPriceFeed));
        dsc.transferOwnership(address(engine));
        vm.stopBroadcast();

        if (dsc.owner() != address(engine)) revert Deploy__WrongOwner();
        if (engine.getDSC() != address(dsc)) revert Deploy__WrongDscAddress();
        if (engine.getPriceFeed() != config.ethUsdPriceFeed) revert Deploy__WrongEthUsdPriceFeed();

        return (address(dsc), address(engine), config.ethUsdPriceFeed);
    }
}
