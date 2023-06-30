//SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.16;

import {Script} from "forge-std/Script.sol";
import {FundMe} from "../src/FundMe.sol";

//import {DevOpsTools} from "foundry-devops/src/DevOpsTool.sol";

contract FundMeCaller is Script {
    FundMe public fundMe;
   // DevOpsTool public devOpsTool;

    constructor() {}

    // function run() public returns (FundMe, DevOpsTool) {
    //     //  devOpsTool = new DevOpsTool();
    //     vm.startBroadcast();
    //     fundMe = new FundMe(address(devOpsTool));
    //     vm.stopBroadcast();
    //     return (fundMe, devOpsTool);
    // }
}
