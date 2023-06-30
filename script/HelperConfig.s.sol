//SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.16;

import {Script} from "forge-std/Script.sol";
import {MockV3Aggregator} from "../test/mock/MockV3Aggregator.sol";

contract HelperConfig is Script {
    NetworkConfig public activeNetworkConfig;
    address constant SEPOLIA_PEICEFEED =
        0x694AA1769357215DE4FAC081bf1f309aDC325306;
    uint8 public constant DECIMALS = 8;
    int256 public constant INITIAL_PRICE = 2000e8;
    struct NetworkConfig {
        address priceFeed;
    }

    constructor() {
        //如果是Sepolia测试链，就使用测试链的aggregator
        if (block.chainid == 11155111) {
            activeNetworkConfig = getSepoliaEthConfig();
        }
        //如果是本地anvil网络就部署一个mock
        else {
            activeNetworkConfig = getOrCreateAnvilNetConfig();
        }
    }

    function getSepoliaEthConfig()
        public
        pure
        returns (NetworkConfig memory sepoliaNetworkConfig)
    {
        sepoliaNetworkConfig = NetworkConfig({
            priceFeed: SEPOLIA_PEICEFEED // ETH / USD
        });
    }

    function getOrCreateAnvilNetConfig()
        public
        returns (NetworkConfig memory anvilNetworkConfig)
    {
        if (activeNetworkConfig.priceFeed != address(0)) {
            return activeNetworkConfig;
        }
        vm.startBroadcast();
        MockV3Aggregator mockPriceFeed = new MockV3Aggregator(
            DECIMALS,
            INITIAL_PRICE
        );
        vm.stopBroadcast();
        anvilNetworkConfig = NetworkConfig({priceFeed: address(mockPriceFeed)});
        return anvilNetworkConfig;
    }
}
