// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {  ILegacyMintableERC20, IOptimismMintableERC20 } from "./interfaces/IOptimismMintableERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { IERC20 } from "@openzeppelin/contracts/interfaces/IERC20.sol";
// contract source of code: https://github.com/ethereum-optimism/optimism/blob/65ec61dde94ffa93342728d324fecf474d228e1f/packages/contracts-bedrock/contracts/L1/L1StandardBridge.sol#L196
import { IL1StandardBridge } from "./interfaces/IStandardBridges.sol";
import { IL2StandardBridge } from "./interfaces/IStandardBridges.sol";
import { ERC165Checker } from "@openzeppelin/contracts/utils/introspection/ERC165Checker.sol";
import { Address } from "@openzeppelin/contracts/utils/Address.sol";
import { SafeCall } from "./SafeCall.sol";
// import { L1CrossDomainMessenger } from "@eth-optimism/contracts/L1/L1CrossDomainMessenger.sol";

/*
 * @author Parsa Aminpour
 * @notice use this contract when you want to transfer the ERC20 token over to the layer2.
 * @notice pair : TokenXonL1(deployed) / TokenXonL2(deployed) => The token will be deployed before this contract deployement.
 1 NOTE: Deploy this function on Ethereum network or any kind of networks that you want to consider that as the layer1 network.
*/
contract GoldenBridge {
    using SafeERC20 for IERC20;
    using Address for address;

    error GoldenBridge__OnlyTheMainMessageSenderCouldCallThisFunction(address prank);
    error GoldenBridge__InvalidRemoteToken(address remote_token);
    error GoldenBridge__OnlyAnotherBridgeAddressCouldCall();
    error GoldenBridge__NotZeroAddressAllowed();
    error GoldenBridge__NotZeroAmountAllowed();
    error GoldenBridge__AnotherBridgeAddressCouldChangeOnce();
    error GoldenBridge__CannotSendToInternalContracts();
    error GoldenBridge__NeedsSufficientETH();
    error GoldenBridge__BridgeFailed();

    mapping(address first_pair => mapping(address second_pair => uint256 amount)) private total_balance_per_pair;
    mapping(address bridge_token_owner => uint256 _balance) private map_amount_of_token_bridged_per_user;

    // These contract addresses have been deployed before.
    address private constant l1_standard_bridge = 0xFBb0621E0B23b5478B630BD55a5f21f67730B0F1;
    GoldenBridge private ANOTHER_LAYER_BRIDGE; // i.e pre-deployed bridge on OP
    ICrossDomainMessenger private immutable CROSS_DOMAIN_MESSENGER;
    bool private another_bridge_address_change_once;

    event GoldenBridge__TokenBridgedStarted(
        address indexed sender, address indexed token_address, uint256 indexed amount
    );
    event GoldenBridge__TokenBridgeEnd(address indexed sender, address indexed token_address, uint256 indexed amount);
    event GoldenBridge__ETHBridgeStarted(address indexed from, address indexed to, uint256 indexed amount);

    /// @param _messenger  Address of CrossDomainMessenger on this network.
    /// @param _ANOTHER_LAYER_BRIDGE Address of the other StandardBridge contract.
    constructor(address payable _messenger, address payable _ANOTHER_LAYER_BRIDGE) payable {
        ANOTHER_LAYER_BRIDGE = GoldenBridge(_ANOTHER_LAYER_BRIDGE);
        CROSS_DOMAIN_MESSENGER = ICrossDomainMessenger(_messenger);
        another_bridge_address_change_once = false;
    }

    modifier only_correspond_bridge() {
        if (msg.sender != address(ANOTHER_LAYER_BRIDGE)) revert GoldenBridge__OnlyAnotherBridgeAddressCouldCall();
        _;
    }

    modifier onlyTheMainMessageSenderForMessenger(address _sender_prank) {
        if (_sender_prank != ICrossDomainMessenger(CROSS_DOMAIN_MESSENGER).xDomainMessageSender()) {
            revert GoldenBridge__OnlyTheMainMessageSenderCouldCallThisFunction(_sender_prank);
        }
        _;
    }

    modifier only_change_once() {
        if (another_bridge_address_change_once) revert GoldenBridge__AnotherBridgeAddressCouldChangeOnce();
        _;
        another_bridge_address_change_once = true;
    }

    /*
     * @dev Another bridge will call this function to stablish the mint process from another layer.
     * @dev If the _local_token was the OptimismMintableERC20 token, then if the correspond bridge call this function, that amount will be minted in did.
        this means that we bridge an OP token to layer1 correspond token. (The process is vise versa than RelayedERC20ToAnotherLayer function)
        (_local_token -> OP token) => we want to bridge token from layer1 to layer2.
            |
            -> this will lock the layer1 ERC20 token to this contract and change the mapping state variable to manage the pair's funds.

        (_local_token -> simple ERC20 token) => we want to bridge token from layer2 to layer1.
            |
            -> This will burn the OptimismMintableERC20 token from the cycle to transfer the correspond layer1 ERC20 token to the owner via this function.

     * @dev If 
     * @param _local_token is the token on the L2 which basically mention to the remote token when we want to use this function.
     * @param _to is the owner of the token on the L1 or _remote_token in here.
     * @param _amount the amount of token on L2 to mint which is the same amount from the token's amount on the current layer.
    */
    function ERC20BridgeProcess(
        address _local_token, // will be remote token for L1
        address _remote_token, // will be local token for L1
        address _to,
        uint256 _amount
    ) external onlyTheMainMessageSenderForMessenger(_to) only_correspond_bridge {
        // mint and born process
        if (_isOpTokenAddressValidate(_local_token)) {
            // from layer1 to layer2
            // the _local_token is on the OP network (which basically is remote token on this layer)
            address correspond_token_address = _getCorrespondTokenAddress(_local_token);
            if (correspond_token_address == address(0) || correspond_token_address != _remote_token) {
                revert GoldenBridge__InvalidRemoteToken(_remote_token);
            }
            IOptimismMintableERC20(_local_token).mint(_to, _amount); // _to is RelayedERC20ToAnotherLayer caller's address
        } else {
            // from leyer2 to layer1
            // the _local_token is on the Ethereum network (which basically is remote token on this layer)
            total_balance_per_pair[_local_token][_remote_token] -= _amount;
            map_amount_of_token_bridged_per_user[_to] -= _amount;
            IERC20(_local_token).safeTransfer(_to, _amount); // transfer asset locked to the native owner.
        }
        emit GoldenBridge__TokenBridgeEnd(_to, _local_token, _amount);
    }

    /*
     * @dev To bridge the _local_token from a layer to another layer (not necessarily the ETH network).
     * @dev Ultimately the CROSS_DOMAIN_MESSENGER will mint the correspond layer's token.
     * @dev in sendMessage section the correspond layer _local_token is the _remote_token from this layer, we pass the _remote_token to that function as _local_token brcause of that.
     * @param _local_token is the token on the current layer that we want to relayed this over to layer2.
     * @param _amount the amount of token on L1 token that we want to relayed over to L2, this amount will be stored in the state variable (mappings).
     * @param minGasLimit arbitary gas limit for this transaction.
     * @param _extraData arbitary data for sending the message (could be blank as "" is).
    */
    function RelayedERC20ToAnotherLayer(
        address _local_token,
        address _remote_token,
        // address _to, -> msg.sender
        uint256 _amount,
        uint32 minGasLimit
        // bytes calldata _extraData
    ) external {
        // check the the _token_on_l1 status to see which chain it is blongs for.
        if (_isOpTokenAddressValidate(_local_token)) {
            // the _local_token is on the OP network
            address correspond_token_address = _getCorrespondTokenAddress(_local_token);
            if (correspond_token_address == address(0) || correspond_token_address != _remote_token) {
                revert GoldenBridge__InvalidRemoteToken(_remote_token);
            }

            IOptimismMintableERC20(_local_token).burn(msg.sender, _amount);
        } else {
            // the _local_token is on the Ethereum network (Simple ERC20 token)
            total_balance_per_pair[_local_token][_remote_token] += _amount;
            map_amount_of_token_bridged_per_user[msg.sender] += _amount;
            IERC20(_local_token).safeTransferFrom(msg.sender, address(this), _amount);
        }

        emit GoldenBridge__TokenBridgedStarted(msg.sender, _local_token, _amount);

        // transfer the L1 token to the corresponding layer vault.
        // sendMessage(address target, bytes calldata message, uint32 gasLimit);
        CROSS_DOMAIN_MESSENGER.sendMessage(
            address(ANOTHER_LAYER_BRIDGE),
            abi.encodeWithSelector(
                this.ERC20BridgeProcess.selector, // target, that only another bridge could call this.
                _remote_token,
                _local_token,
                msg.sender,
                _amount       
            ),
            minGasLimit
        );
    }

    /*
    * @notice this function only could be trigged by the correspond GoldenBridge contract on remote chain.
    * @param _to explained on RelayedETHtoAnotherLayer function.
    * @param _amount explained on RelayedETHtoAnotherLayer function.
    * NOTE: In this contract we don't consider the calldata message. keep it simple.
    */
    function ETHBridgeProcess(address _to, uint256 _amount, uint32 _minGasLimit) external payable only_correspond_bridge() {
        bool success = SafeCall.callWithMinGas(_to, _minGasLimit, _amount, bytes(""));
        if (!success) revert GoldenBridge__BridgeFailed();
    }

    /*
    * @notice this function bridge ETH available on this network to the another bridge network.
    * @param _to the address of receiver on correspond network.
    * @param _amount the amount that we want to send which should be as same as msg.value.
    * @param _minGasLimit the minimum gas that bridge could handle the transaction.
    */
    function RelayedETHtoAnotherLayer(address _to, uint256 _amount, uint32 _minGasLimit) external payable {
        if (_to == address(this) || _to == address(ANOTHER_LAYER_BRIDGE)) revert GoldenBridge__CannotSendToInternalContracts();
        if (_to == address(0)) revert GoldenBridge__NotZeroAddressAllowed();
        if (_amount != msg.value) revert GoldenBridge__NeedsSufficientETH();
        if (msg.value == 0) revert GoldenBridge__NotZeroAmountAllowed();

        emit GoldenBridge__ETHBridgeStarted(msg.sender, _to, _amount);

        // @audit-info if the second parameter's length  (bytes message) be too long, the gas will be on fire.
        CROSS_DOMAIN_MESSENGER.sendMessage{ value:msg.value }(
            address(ANOTHER_LAYER_BRIDGE),
            abi.encodeWithSelector(
                this.ETHBridgeProcess.selector,
                msg.sender,
                _to,
                msg.value,
            _minGasLimit),
            _minGasLimit);
    }


    /*
    * @notie this function will be called only once at the deployement section immediately after deployement.
    * @param _valid_address is the valid correspond bridge contract address. (determined in the deployement script)
    */
    function change_correspond_bridge_address(address payable _valid_address) external only_change_once {
        require(_valid_address != address(0), "Invalid Address");
        GoldenBridge another_bridge = GoldenBridge(_valid_address);
        ANOTHER_LAYER_BRIDGE = another_bridge;
    }


    /*.*.*.*.*.*.*.*.*.**.*.*.*.*.*.*.*.*.*
    /         Internal Functions          /
    *.*.*.*.*.*.*.*.*.**.*.*.*.*.*.*.*.*.*/
    function _isOpTokenAddressValidate(address op_address) internal view returns (bool) {
        if (
            ERC165Checker.supportsInterface(op_address, type(ILegacyMintableERC20).interfaceId)
                || ERC165Checker.supportsInterface(op_address, type(IOptimismMintableERC20).interfaceId)
        ) return true;

        return false;
    }

    function _getCorrespondTokenAddress(address _token_on_current_layer) internal view returns (address) {
        if (ERC165Checker.supportsInterface(_token_on_current_layer, type(IOptimismMintableERC20).interfaceId)) {
            return IOptimismMintableERC20(_token_on_current_layer).remoteToken();
        } else if (ERC165Checker.supportsInterface(_token_on_current_layer, type(ILegacyMintableERC20).interfaceId)) {
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
    function get_pair_balance(address _first_pair, address _second_pair) external view returns (uint256) {
        return total_balance_per_pair[_first_pair][_second_pair];
    }

    function get_owner_balance(address _owner) external view returns (uint256) {
        return map_amount_of_token_bridged_per_user[_owner];
    }

    function get_userTokenBridgedAmount(address _user) external view returns (uint256) {
        return map_amount_of_token_bridged_per_user[_user];
    }

    function get_correspond_v2_bridge_address() external view returns (address) {
        return address(ANOTHER_LAYER_BRIDGE);
    }

    function get_messenger_address() external view returns (address) {
        return address(CROSS_DOMAIN_MESSENGER);
    }
}

interface ICrossDomainMessenger {
    function xDomainMessageSender() external view returns (address);
    function sendMessage(address target, bytes calldata message, uint32 gasLimit) external payable;
}
