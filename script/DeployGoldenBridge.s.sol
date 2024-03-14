// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import { Script } from "forge-std/Script.sol";
import { TokenL2 } from "../src/TokenL2.sol";
import { TokenL1 } from "../src/TokenL1.sol";
import { IERC20 } from "@openzeppelin/contracts/interfaces/IERC20.sol";
import { GoldenBridge } from "../src/GoldenBridge.sol";
import { console } from "forge-std/console.sol";
import { IGoldenBridge } from "../src/interfaces/IGoldenBridge.sol";

// On Sepolia test network (first deploy this contract)
contract DeployGoldenBridgeOnL1 is Script {
    address private constant messenger_address_on_l1 = 0x4200000000000000000000000000000000000007;
    address private constant messenger_address_on_l2 = 0x4200000000000000000000000000000000000008;

    address private constant l1_token_address = 0x84D1B79c9002bC8231981a15b4087EeC8Ed90EF5;
    address private constant l2_token_address = 0x9D9f6a14C6A3a1991FEdbF98F93c4980CB079fed;

    GoldenBridge public l1_bridge;

    // The L1 bridge will be deployed with another_layer_bridge of this address, and then this address will change the another_bridge_address to a valid_address immediately.
    address _tmp_correpond_layer = makeAddr("tmp_correspond");

    function run() external returns (GoldenBridge _l1_bridge) {
        uint256 private_key = vm.envUint("PRIVATE_KEY");
        // l2_correspond_bridge = new GoldenBridge(payable(messenger_address_on_l2), payable(address(this)));
 
        vm.startBroadcast(private_key);
        vm.chainId(11155111);
        l1_bridge = new GoldenBridge(
            payable(messenger_address_on_l1), payable(_tmp_correpond_layer));
        
        console.log("L1 bridge address: ", address(l1_bridge));
        vm.stopBroadcast();

        _l1_bridge = l1_bridge;
    }
}

// Deploy DeployGoldenBridgeOnL2 on OP sepolia network after deploying DeployGoldenBridgeOnL1 script.
contract DeployGoldenBridgeOnL2 is Script {
    address public constant messenger_address_on_l1 = 0x4200000000000000000000000000000000000007;
    address public constant messenger_address_on_l2 = 0x4200000000000000000000000000000000000008;

    address public constant l1_token_address = 0x84D1B79c9002bC8231981a15b4087EeC8Ed90EF5;
    address public constant l2_token_address = 0x9D9f6a14C6A3a1991FEdbF98F93c4980CB079fed;

    address public l1_bridge_address = 0x0a1724Ed3A2664BB561fc32F508442BCCCE29f22; // from pre-deployed contract
    GoldenBridge public l2_bridge;

    function run() external returns(GoldenBridge _l2_bridge) {
        uint256 private_key = vm.envUint("PRIVATE_KEY");
        address owner = vm.addr(private_key);

        vm.startBroadcast(private_key);
        vm.chainId(11155420);
        l2_bridge = new GoldenBridge(
            payable(messenger_address_on_l2), payable(l1_bridge_address));
        vm.stopBroadcast();
            
        address l2_bridge_address = address(l2_bridge);
        
        vm.startPrank(owner);
        (bool success, ) = l1_bridge_address.call(
            abi.encodeWithSignature("change_correspond_bridge_address(address)",
                payable(l2_bridge_address)
            ));
        require(success, "call failed");
        vm.stopPrank();

        _l2_bridge = l2_bridge;
    }
}