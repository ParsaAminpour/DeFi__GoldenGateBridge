// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {Test} from "forge-std/Test.sol";
import {TokenL2} from "../src/TokenL2.sol";
import {TokenL1} from "../src/TokenL1.sol";
import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";
import {DeployTokenOnL2Script} from "../script/DeployToken.s.sol";
import {console} from "forge-std/console.sol";
import {GoldenBridge} from "../src/GoldenBridge.sol";

contract GoldenBridgeTest is Test {
    address public caller = makeAddr("caller");
    address public immutable bridge_address = 0x4200000000000000000000000000000000000007;
    uint256 public constant AMOUNT_TO_BRIDGE = 10e18;

    TokenL1 public l1_token;
    address public constant l2_token = 0x26f76e57B14D591F8b6d0Bb9b00C0c125b487D25;
    DeployTokenOnL2Script public deployer;
    GoldenBridge public l1_bridge;

    function setUp() public {
        l1_token = new TokenL1();
        // l1_bridge = new GoldenBridge(bridge_address);

        console.log(address(l1_token));
        // console.log(address(l2_token));
    }

    function testSetup() public {
        assertEq(uint256(1), uint256(1));
    }
}
