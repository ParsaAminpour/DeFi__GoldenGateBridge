// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { IERC20 } from "@openzeppelin/contracts/interfaces/IERC20.sol";
// contract source of code: https://github.com/ethereum-optimism/optimism/blob/65ec61dde94ffa93342728d324fecf474d228e1f/packages/contracts-bedrock/contracts/L1/L1StandardBridge.sol#L196
import { IL1StandardBridge } from "./interfaces/IStandardBridges.sol";
import { IL2StandardBridge } from "./interfaces/IStandardBridges.sol";

/*
 * @author ParsaAminpour
 * @notice use this contract when you want to transfer the ERC20 token over to the layer2.
 * pair : TokenXonL1(deployed) / TokenXonL2(deployed) => The token will be deployed before this contract deployement. 
*/
contract GoldenBridgeL1 {
    using SafeERC20 for IERC20;

    error GoldenBridge__NotZeroAddressAllowed();
    error GoldenBridge__NotZeroAmountAllowed();

    mapping(address bridged_token_owner => uint256 bridged_amount) private map_amount_of_token_bridged_per_user;

    address private immutable correspond_bridge_address;
    address private immutable l2_treasure_address;
    address private immutable l1Token;
    address private immutable l2Token;

    event GoldenBridgeL1__TokenBridgedToL2(address indexed sender, address indexed token_address, uint256 indexed amount);
    event GoldenBridgeL1__TokenTransferedToL2(address indexed sender, address indexed token_address, uint256 indexed amount);

    constructor(address _bridge, address _l2_treasure_address, address _l1_token, address _l2_token) payable {
        correspond_bridge_address = _bridge;
        l2_treasure_address = _l2_treasure_address;
        l1Token = _l1_token;
        l2Token = _l2_token;
    }

    function RelayedToAnotherLayer(address _l2_bridge_address, uint256 _amount, uint32 _gas_limit) external returns(bool) {
        if (_l2_bridge_address == address(0)) revert GoldenBridge__NotZeroAddressAllowed();
        if (_amount == 0) revert GoldenBridge__NotZeroAmountAllowed();

        IL1StandardBridge(correspond_bridge_address).depositERC20To({
            _l1Token: l1Token,
            _l2Token: l2Token,
            _to: _l2_bridge_address, // will be stored in the L2 Token treasury.
            _amount: _amount,
            _minGasLimit: _gas_limit,
            _extraData: ""
        });
        emit GoldenBridgeL1__TokenBridgedToL2(msg.sender, l1Token, _amount);

        IERC20(l1Token).transferFrom(msg.sender, correspond_bridge_address, _amount);
        emit GoldenBridgeL1__TokenTransferedToL2(msg.sender, l1Token, _amount);
        
        return true;
    }

    
    /*.*.*.*.*.*.*.*.*.**.*.*.*.*.*.*.*.*.*
    /     External and View Functions     /
    *.*.*.*.*.*.*.*.*.**.*.*.*.*.*.*.*.*.*/
    function get_userTokenBridgedAmount(address _user) external view returns(uint256) {
        return map_amount_of_token_bridged_per_user[_user];
    }

    function get_correspond_v2_bridge_address() external view returns(address) {
        return correspond_bridge_address;
    }

    function get_l1_token_address() external view returns(address) {
        return l1Token;
    }

    function get_l2_token_address() external view returns(address) {
        return l2Token;
    }

    function get_l2_treasure_address() external view returns(address) {
        return l2_treasure_address;
    }
}

contract L2Treasury {
    address private immutable L1BridgeAddress;
    constructor(address _l1BridgeAddress) {
        L1BridgeAddress = _l1BridgeAddress;
    }

    
}