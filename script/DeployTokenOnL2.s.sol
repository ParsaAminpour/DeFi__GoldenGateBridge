// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import { Script } from "forge-std/Script.sol";
import { GoldenBridgeTokenL2 } from "../src/GoldenBridgeTokenL2.sol";
import { GoldenBridgeTokenL1 } from "../src/GoldenBridgeTokenL1.sol";
import { IERC20 } from "@openzeppelin/contracts/interfaces/IERC20.sol";
import { console } from "forge-std/console.sol";

contract DeployTokenOnL2Script is Script {
    address public immutable bridge_address = 0x4200000000000000000000000000000000000007;
    uint256 public constant AMOUNT_TO_BRIDGE = 10e18;

    function run() external returns(GoldenBridgeTokenL2){
        uint256 private_key = vm.envUint("PRIVATE_KEY");
        address test_token = makeAddr("test_token");

        vm.startBroadcast(private_key);
        vm.chainId(11155420); // on OP sepolia
        GoldenBridgeTokenL2 l2_token = new GoldenBridgeTokenL2(bridge_address, test_token, "L2Token", "L2");
        console.log("The L2 Token address is: ", address(l2_token));
        vm.stopBroadcast();

        return l2_token;
    }
}