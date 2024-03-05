// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import { ILegacyMintableERC20, IOptimismMintableERC20 } from "./interfaces/IOptimismMintableERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { IERC20 } from "@openzeppelin/contracts/interfaces/IERC20.sol";
// contract source of code: https://github.com/ethereum-optimism/optimism/blob/65ec61dde94ffa93342728d324fecf474d228e1f/packages/contracts-bedrock/contracts/L1/L1StandardBridge.sol#L196
import { IL1StandardBridge } from "./interfaces/IStandardBridges.sol";
import { IL2StandardBridge } from "./interfaces/IStandardBridges.sol";
import { ERC165Checker } from "@openzeppelin/contracts/utils/introspection/ERC165Checker.sol";
import { Address } from "@openzeppelin/contracts/utils/Address.sol";

/*
 * @author ParsaAminpour
 * @notice use this contract when you want to transfer the ERC20 token over to the layer2.
 * @notice pair : TokenXonL1(deployed) / TokenXonL2(deployed) => The token will be deployed before this contract deployement.
 1 NOTE: Deploy this function on Ethereum network or any kind of networks that you want to consider that as the layer1 network.
*/
contract GoldenBridge {
    using SafeERC20 for IERC20;
    using Address for address;

    error GoldenBridge__InvalidRemoteToken(address remote_token);
    error GoldenBridge__OnlyAnotherBridgeAddressCouldCall();
    error GoldenBridge__NotZeroAddressAllowed();
    error GoldenBridge__NotZeroAmountAllowed();

    mapping(address first_pair => mapping(address second_pair => uint256 amount)) private total_balance_per_pair;
    mapping(address bridge_token_owner => uint256 _balance) private map_amount_of_token_bridged_per_user;

    // These contract addresses have been deployed before.
    address private constant l1_standard_bridge = 0xFBb0621E0B23b5478B630BD55a5f21f67730B0F1;
    GoldenBridge private immutable bridge_from_another_layer; // i.e pre-deployed bridge on OP
    ICrossDomainMessenger private immutable CROSS_DOMAIN_MESSENGER;
    address private immutable l2_treasure_address;

    event GoldenBridge__TokenBridgedStarted(
        address indexed sender, address indexed token_address, uint256 indexed amount
    );
    event GoldenBridge__TokenBridgeEnd(
        address indexed sender, address indexed token_address, uint256 indexed amount
    );

    /// @param _messenger   Address of CrossDomainMessenger on this network.
    /// @param _bridge_from_another_layer Address of the other StandardBridge contract.
    constructor(address payable _messenger, address _l2_treasure_address, address payable _bridge_from_another_layer) payable {
        bridge_from_another_layer = GoldenBridge(_bridge_from_another_layer);
        CROSS_DOMAIN_MESSENGER = ICrossDomainMessenger(_messenger);
        l2_treasure_address = _l2_treasure_address;
    }

    modifier only_correspond_bridge() {
        if (msg.sender != address(bridge_from_another_layer)) {
            revert GoldenBridge__OnlyAnotherBridgeAddressCouldCall();
        }
        _;
    }

    function ERC20BridgeProcess(
        address _local_token, // will be remote token for L1
        address _remote_token, // will be local token for L1
        address _to,
        uint256 _amount) external only_correspond_bridge{
            // mint and born process
            if (_isOpTokenAddressValidate(_local_token)) {
                // the _local_token is on the OP network (which basically is remote token on this layer)
                address correspond_token_address = _getCorrespondTokenAddress(_local_token);
                if (correspond_token_address == address(0) || correspond_token_address != _remote_token) {
                    revert GoldenBridge__InvalidRemoteToken(_remote_token);
                }
                IOptimismMintableERC20(_local_token).mint(_to, _amount);
            } else {
                // the _local_token is on the Ethereum network (which basically is remote token on this layer)
                IERC20(_local_token).safeTransfer(_to, _amount);
                total_balance_per_pair[_local_token][_remote_token] -= _amount;
                map_amount_of_token_bridged_per_user[_to] -= _amount;
            }
        emit GoldenBridge__TokenBridgeEnd(_to, _local_token, _amount);
    }

    function RelayedToAnotherLayer(        
        address _local_token,
        address _remote_token,
        // address _to, -> msg.sender
        uint256 _amount,
        uint32 minGasLimit,
        bytes calldata _extraData) external {
        // check the the _token_on_l1 status to see which chain it is blongs for.
        if (_isOpTokenAddressValidate(_local_token)) {
            // the _local_token is on the OP network
            address correspond_token_address = _getCorrespondTokenAddress(_local_token);
            if (correspond_token_address == address(0) || correspond_token_address != _remote_token) {
                revert GoldenBridge__InvalidRemoteToken(_remote_token);
            }

            IOptimismMintableERC20(_local_token).burn(msg.sender, _amount);
        } else {
            // the _local_token is on the Ethereum network
            IERC20(_local_token).safeTransferFrom(msg.sender, address(this), _amount);
            total_balance_per_pair[_local_token][_remote_token] += _amount;
            map_amount_of_token_bridged_per_user[msg.sender] += _amount;
        }
        
        emit GoldenBridge__TokenBridgedStarted(msg.sender, _local_token, _amount);

        // transfer the L1 token to the corresponding layer vault.
        CROSS_DOMAIN_MESSENGER.sendMessage(
            address(bridge_from_another_layer), 
            abi.encodeWithSelector(
            this.ERC20BridgeProcess.selector, // target, that only another bridge could call this.
            _remote_token, 
            _local_token, 
            msg.sender,
            _amount, 
            _extraData),
            minGasLimit
        );
    }


    function _isOpTokenAddressValidate(address op_address) internal view returns(bool) {
        if(ERC165Checker.supportsInterface(op_address, type(ILegacyMintableERC20).interfaceId) ||
        ERC165Checker.supportsInterface(op_address, type(IOptimismMintableERC20).interfaceId)) {
            return true;
        }
        return false;
    }

    function _getCorrespondTokenAddress(address _token_on_current_layer) internal view returns(address) {
        if (ERC165Checker.supportsInterface(_token_on_current_layer, type(IOptimismMintableERC20).interfaceId)) {
            return IOptimismMintableERC20(_token_on_current_layer).remoteToken();

        } else if(ERC165Checker.supportsInterface(_token_on_current_layer, type(ILegacyMintableERC20).interfaceId)) {
            return ILegacyMintableERC20(_token_on_current_layer).l1Token();
        }
        return address(0);
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
        return address(bridge_from_another_layer);
    }

    function get_l2_treasure_address() external view returns (address) {
        return l2_treasure_address;
    }
}


interface ICrossDomainMessenger {
    function xDomainMessageSender() external view returns (address);
    function sendMessage(address target, bytes calldata message, uint32 gasLimit) external;
}