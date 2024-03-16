// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import { Test } from "forge-std/Test.sol";
import { TokenL2 } from "../src/TokenL2.sol";
import { TokenL1 } from "../src/TokenL1.sol";
import { IERC20 } from "@openzeppelin/contracts/interfaces/IERC20.sol";
import { DeployTokenOnL1Script, DeployTokenOnL2Script } from "../script/DeployToken.s.sol";
import { console } from "forge-std/console.sol";
import { GoldenBridge } from "../src/GoldenBridge.sol";

contract GoldenBridgeTest is Test {
    address public caller = makeAddr("caller");
    address public immutable bridge_address = 0x4200000000000000000000000000000000000007;
    uint256 public constant AMOUNT_TO_BRIDGE = 10e18;

    TokenL1 public l1_token;
    TokenL2 public l2_token;
    GoldenBridge public l1_bridge;

    function setUp() public {
        
        DeployTokenOnL1Script l1_token_deployer = new DeployTokenOnL1Script();
        DeployTokenOnL2Script l2_token_deployer = new DeployTokenOnL2Script();
        l1_token = l1_token_deployer.run();
        l2_token = l2_token_deployer.run();

        console.log("L1 token address: ", address(l1_token));
        console.log("L2 token address: ", address(l2_token));
    }

    function testSetup() public {
        assertEq(uint256(1), uint256(1));
    }
}
