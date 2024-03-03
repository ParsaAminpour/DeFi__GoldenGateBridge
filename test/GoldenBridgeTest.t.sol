// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import { Test } from "forge-std/Test.sol";
import { GoldenBridgeTokenL2 } from "../src/GoldenBridgeTokenL2.sol";
import { GoldenBridgeTokenL1 } from "../src/GoldenBridgeTokenL1.sol";
import { IERC20 } from "@openzeppelin/contracts/interfaces/IERC20.sol";
import { DeployTokenOnL2Script } from "../script/DeployTokenOnL2.s.sol";
import { IGoldenBridgeTokenL2 } from "../src/interfaces/IGoldenBridgeTokenL2.sol";
import { console } from "forge-std/console.sol";
import { GoldenBridgeL1 } from "../src/GoldenBridge.sol";

contract GoldenBridgeTest is Test {
    address public caller = makeAddr("caller");
    address public immutable bridge_address = 0x4200000000000000000000000000000000000007;
    uint256 public constant AMOUNT_TO_BRIDGE = 10e18;

    GoldenBridgeTokenL1 public l1_token;
    address public constant l2_token = 0x26f76e57B14D591F8b6d0Bb9b00C0c125b487D25;
    DeployTokenOnL2Script public deployer;

    function setUp() public {
        l1_token = new GoldenBridgeTokenL1();

        console.log(address(l1_token));
        console.log(address(l2_token));
    }

    function testSetup() public {

        assertEq(uint(1), uint(1));
    }
}