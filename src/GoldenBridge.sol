// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {IL1StandardBridge} from "./interfaces/IStandardBridges.sol";
import {IL2StandardBridge} from "./interfaces/IStandardBridges.sol";

contract GoldenBridgeL1 {
    error GoldenBridge__NotZeroAddressAllowed();
    error GoldenBridge__NotZeroAmountAllowed();


    address private immutable correspond_bridge_address;
    address private immutable l1Token;
    address private immutable l2Token;

    constructor(address _bridge, address _l1_token, address _l2_token) payable {
        correspond_bridge_address = _bridge;
        l1Token = _l1_token;
        l2Token = _l2_token;
    }

    function RelayedToAnotherLayer(address _l2_bridge_address, uint256 _amount, uint32 _gas_limit) external returns(bool) {
        if (_l2_bridge_address == address(0)) revert GoldenBridge__NotZeroAddressAllowed();
        if (_amount == 0) revert GoldenBridge__NotZeroAmountAllowed();

        IL1StandardBridge(correspond_bridge_address).bridgeERC20To({
            local_token: l1Token,
            remote_token: l2Token,
            to: _l2_bridge_address,
            amount: _amount,
            min_gas_limit: _gas_limit,
            data: ""
        });
    }
}