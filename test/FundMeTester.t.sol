//SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.16;

import {Script} from "forge-std/Script.sol";
import {FundMe} from "../src/FundMe.sol";
import {FundMeDeployer} from "../script/FundMeDeployer.s.sol";
import {Test, console} from "forge-std/Test.sol";
import {HelperConfig} from "../script/HelperConfig.s.sol";
import {StdCheats} from "forge-std/StdCheats.sol";

contract FundMeTester is StdCheats, Test {
    FundMe fundMe;
    HelperConfig public helperConfig;
    uint256 public constant STARTING_USER_BALANCE = 10 ether;
    address public constant USERALICE = address(1);
    uint256 public constant SEND_VALUE = 0.1 ether;
    uint256 public constant GAS_PRICE = 1;

    function setUp() public {
        FundMeDeployer deployer = new FundMeDeployer();
        (fundMe, helperConfig) = deployer.run();
        vm.deal(USERALICE, STARTING_USER_BALANCE);
    }

    function testPriceFeedSetCorrectly() public {
        address retreivePriceFeed = address(fundMe.getPriceFeed());
        address expectedPriceFeed = helperConfig.activeNetworkConfig();
        assertEq(retreivePriceFeed, expectedPriceFeed);
    }

    function testFundFailsWithoutEnoughETH() public {
        vm.expectRevert();
        fundMe.fund();
    }

    function testFundUpdatesFundedDataStructrue() public {
        vm.prank(USERALICE);
        fundMe.fund{value: SEND_VALUE}();

        uint256 amountFunded = fundMe.getAddressToAmountFunded(USERALICE);
        assertEq(amountFunded, SEND_VALUE);
    }

    //move fund operation to modifier to save codes
    modifier funded() {
        vm.prank(USERALICE);
        fundMe.fund{value: SEND_VALUE}();
        assert(address(fundMe).balance > 0);
        _;
    }

    function testAddsFunderToArrayOfFunders() public funded {
        address funder = fundMe.getFunder(0);
        assertEq(funder, USERALICE);
    }

    function testOnlyOwnerCanWithdraw() public funded {
        vm.expectRevert();
        fundMe.withdraw();
    }

    function testWithdrawFromASingleFunderWithZeroGas() public funded {
        // Arrange
        uint256 startingFundMeBalance = address(fundMe).balance;
        uint256 startingOwnerBalance = fundMe.getOwner().balance;

        // vm.txGasPrice(GAS_PRICE);
        // uint256 gasStart = gasleft();
        // // Act
        vm.startPrank(fundMe.getOwner());
        fundMe.withdraw();
        vm.stopPrank();

        // uint256 gasEnd = gasleft();
        // uint256 gasUsed = (gasStart - gasEnd) * tx.gasprice;

        // Assert
        uint256 endingFundMeBalance = address(fundMe).balance;
        uint256 endingOwnerBalance = fundMe.getOwner().balance;
        assertEq(endingFundMeBalance, 0);
        assertEq(
            startingFundMeBalance + startingOwnerBalance,
            endingOwnerBalance // + gasUsed
        );
    }

    function testWithdrawFromASingleFunderWithGas() public funded {
        // Arrange
        uint256 startingFundMeBalance = address(fundMe).balance;
        uint256 startingOwnerBalance = fundMe.getOwner().balance;
        console.log(startingFundMeBalance);
        console.log(startingOwnerBalance);

        uint256 gasStart = gasleft();
        // Act
        address owner = fundMe.getOwner();
        vm.txGasPrice(GAS_PRICE);
        vm.startPrank(owner);
        fundMe.withdraw();
        vm.stopPrank();

        uint256 gasEnd = gasleft();
        uint256 gasUsed = (gasStart - gasEnd) * tx.gasprice;
        console.log(gasUsed);

        // Assert
        uint256 endingFundMeBalance = address(fundMe).balance;
        uint256 endingOwnerBalance = fundMe.getOwner().balance;
        console.log(endingOwnerBalance);
        assertEq(endingFundMeBalance, 0);
        assertEq(
            startingFundMeBalance + startingOwnerBalance,
            endingOwnerBalance + gasUsed
        );
    }

    function testWithDrawFromMultipleFunders() public funded {
        uint160 numberOfFunders = 10;
        uint160 startingFunderIndex = 2;
        for (
            uint160 i = startingFunderIndex;
            i < numberOfFunders + startingFunderIndex;
            i++
        ) {
            // we get hoax from stdcheats
            // prank + deal
            hoax(address(i), STARTING_USER_BALANCE);
            fundMe.fund{value: SEND_VALUE}();
        }

        uint256 startingFundMeBalance = address(fundMe).balance;
        uint256 startingOwnerBalance = fundMe.getOwner().balance;

        vm.startPrank(fundMe.getOwner());
        fundMe.withdraw();
        vm.stopPrank();

        assert(address(fundMe).balance == 0);
        assert(
            startingFundMeBalance + startingOwnerBalance ==
                fundMe.getOwner().balance
        );
        assert(
            (numberOfFunders + 1) * SEND_VALUE ==
                fundMe.getOwner().balance - startingOwnerBalance
        );
    }

    function testgetVersion() public view {
        console.log("FundMe version: %d", fundMe.getVersion());
        assert(fundMe.getVersion() == 4);
    }
}
