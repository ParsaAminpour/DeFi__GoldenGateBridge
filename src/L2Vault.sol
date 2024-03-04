// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";
// contract source of code: https://github.com/ethereum-optimism/optimism/blob/65ec61dde94ffa93342728d324fecf474d228e1f/packages/contracts-bedrock/contracts/L1/L1StandardBridge.sol#L196
import {IL1StandardBridge} from "./interfaces/IStandardBridges.sol";
import {IL2StandardBridge} from "./interfaces/IStandardBridges.sol";


// This contract will deploy on OP layer2
contract L2Vault {
    address private immutable L1BridgeAddress;

    constructor(address _l1BridgeAddress) {
        L1BridgeAddress = _l1BridgeAddress;
    }
}
