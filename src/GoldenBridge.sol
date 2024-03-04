// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import { ILegacyMintableERC20, IOptimismMintableERC20 } from "./interfaces/IOptimismMintableERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { IERC20 } from "@openzeppelin/contracts/interfaces/IERC20.sol";
// contract source of code: https://github.com/ethereum-optimism/optimism/blob/65ec61dde94ffa93342728d324fecf474d228e1f/packages/contracts-bedrock/contracts/L1/L1StandardBridge.sol#L196
import { IL1StandardBridge } from "./interfaces/IStandardBridges.sol";
import { IL2StandardBridge } from "./interfaces/IStandardBridges.sol";
import { ERC165Checker } from "@openzeppelin/contracts/utils/introspection/ERC165Checker.sol";

/*
 * @author ParsaAminpour
 * @notice use this contract when you want to transfer the ERC20 token over to the layer2.
 * @notice pair : TokenXonL1(deployed) / TokenXonL2(deployed) => The token will be deployed before this contract deployement.
 1 NOTE: Deploy this function on Ethereum network or any kind of networks that you want to consider that as the layer1 network.
*/
contract GoldenBridgeL1 {
    using SafeERC20 for IERC20;

    error GoldenBridge__NotZeroAddressAllowed();
    error GoldenBridge__NotZeroAmountAllowed();

    mapping(address bridged_token_owner => uint256 bridged_amount) private map_amount_of_token_bridged_per_user;

    address private immutable op_bridge_address;
    address private immutable l2_treasure_address;
    address private immutable l1Token;
    address private immutable l2Token;

    event GoldenBridgeL1__TokenBridgedToL2(
        address indexed sender, address indexed token_address, uint256 indexed amount
    );
    event GoldenBridgeL1__TokenTransferedToL2(
        address indexed sender, address indexed token_address, uint256 indexed amount
    );

    constructor(address _bridge, address _l2_treasure_address, address _l1_token, address _l2_token) payable {
        op_bridge_address = _bridge;
        l2_treasure_address = _l2_treasure_address;
        l1Token = _l1_token;
        l2Token = _l2_token;
    }

    function RelayedToAnotherLayer(uint256 _amount, uint32 _gas_limit) external returns (bool) {
        // if (_l2_bridge_address == address(0)) revert GoldenBridge__NotZeroAddressAllowed();
        if (_amount == 0) revert GoldenBridge__NotZeroAmountAllowed();

        IL1StandardBridge(op_bridge_address).bridgeERC20To({
            _localToken: l1Token,
            _remoteToken: l2Token,
            _to: l2_treasure_address, // will be stored in the L2 Token treasury.
            _amount: _amount,
            _minGasLimit: _gas_limit,
            _extraData: ""
        });
        emit GoldenBridgeL1__TokenBridgedToL2(msg.sender, l1Token, _amount);

        IERC20(l1Token).transferFrom(msg.sender, l2_treasure_address, _amount);
        emit GoldenBridgeL1__TokenTransferedToL2(msg.sender, l1Token, _amount);

        return true;
    }

    function _isOpAddressValidate(address op_address) internal view returns(bool) {
        if(ERC165Checker.supportsInterface(op_address, type(ILegacyMintableERC20).interfaceId) ||
        ERC165Checker.supportsInterface(op_address, type(IOptimismMintableERC20).interfaceId)) {
            return true;
        }
        return false;
    }

    /// @notice Checks if the "other token" is the correct pair token for the OptimismMintableERC20.
    ///         Calls can be saved in the future by combining this logic with
    ///         `_isOptimismMintableERC20`.
    /// @param _mintableToken OptimismMintableERC20 to check against.
    /// @param _otherToken    Pair token to check.
    /// @return True if the other token is the correct pair token for the OptimismMintableERC20.
    function _isCorrectTokenPair(address _mintableToken, address _otherToken) internal view returns (bool) {
        if (ERC165Checker.supportsInterface(_mintableToken, type(ILegacyMintableERC20).interfaceId)) {
            return _otherToken == ILegacyMintableERC20(_mintableToken).l1Token();
        } else {
            return _otherToken == IOptimismMintableERC20(_mintableToken).remoteToken();
        }
    }

    /*.*.*.*.*.*.*.*.*.**.*.*.*.*.*.*.*.*.*
    /     External and View Functions     /
    *.*.*.*.*.*.*.*.*.**.*.*.*.*.*.*.*.*.*/
    function get_userTokenBridgedAmount(address _user) external view returns (uint256) {
        return map_amount_of_token_bridged_per_user[_user];
    }

    function get_correspond_v2_bridge_address() external view returns (address) {
        return op_bridge_address;
    }

    function get_l1_token_address() external view returns (address) {
        return l1Token;
    }

    function get_l2_token_address() external view returns (address) {
        return l2Token;
    }

    function get_l2_treasure_address() external view returns (address) {
        return l2_treasure_address;
    }
}
