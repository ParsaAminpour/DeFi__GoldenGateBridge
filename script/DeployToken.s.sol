// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {Script} from "forge-std/Script.sol";
import {TokenL2} from "../src/TokenL2.sol";
import {TokenL1} from "../src/TokenL1.sol";
import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";
import {console} from "forge-std/console.sol";

// Deploy this one on the Optimism network
contract DeployTokenOnL2Script is Script {
    address public immutable bridge_address = 0x4200000000000000000000000000000000000007;
    uint256 public constant AMOUNT_TO_MINT = 100e18;
    uint256 public constant AMOUNT_TO_BRIDGE = 10e18;
    // DeployTokenOnL1Script public l1_token = new DeployTokenOnL1Script();
    // pre-deployed L1 token
    address public constant l1_token_address = 0x84D1B79c9002bC8231981a15b4087EeC8Ed90EF5;

    function run() external returns (TokenL2) {
        uint256 private_key = vm.envUint("PRIVATE_KEY");
        address owner = vm.addr(private_key);

        vm.startBroadcast(private_key);
        vm.chainId(11155420); // on OP sepolia
        TokenL2 l2_token = new TokenL2(bridge_address, l1_token_address, "L2Token", "L2");
        vm.stopBroadcast();

        vm.startPrank(bridge_address);
        l2_token.mint(owner, AMOUNT_TO_MINT);
        console.log("The owner l2 token balance: ", l2_token.balanceOf(owner));

        vm.stopPrank();

        return l2_token;
    }
}

// Deplot this on Ethereum network
contract DeployTokenOnL1Script is Script {
    uint256 public constant AMOUNT_TO_MINT = 100e18;
    function run() public returns (TokenL1) {
        uint256 private_key = vm.envUint("PRIVATE_KEY");
        address owner = vm.addr(private_key);
        
        vm.startBroadcast(private_key);
        vm.chainId(11155111);
        TokenL1 l1_token = new TokenL1();

        l1_token.mint(owner, AMOUNT_TO_MINT);
        console.log("The owner balance on L1: ", l1_token.balanceOf(owner));
        vm.stopBroadcast();

        return l1_token;
    }
}
