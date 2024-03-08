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
    address l1_token_address = 0x26f76e57B14D591F8b6d0Bb9b00C0c125b487D25;

    function run() external returns (TokenL2) {
        uint256 private_key = vm.envUint("PRIVATE_KEY");
        address owner = vm.addr(private_key);

        vm.startBroadcast(private_key);
        vm.chainId(11155420); // on OP sepolia
        TokenL2 l2_token = new TokenL2(bridge_address, l1_token_address, "L2Token", "L2");
        console.log("The L2 Token address is: ", address(l2_token));
        vm.stopBroadcast();

        vm.startPrank(bridge_address);
        l2_token.mint(owner, AMOUNT_TO_MINT);
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
        console.log(address(l1_token));

        l1_token.mint(owner, AMOUNT_TO_MINT);
        vm.stopBroadcast();

        return l1_token;
    }
}