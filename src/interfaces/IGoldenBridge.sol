// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;
interface IGoldenBridge {
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
    ) external;


    /// @notice Sends ERC20 tokens to a receiver's address on the other chain. Note that if the
    ///         ERC20 token on the other chain does not recognize the local token as the correct
    ///         pair token, the ERC20 bridge will fail and the tokens will be returned to sender on
    ///         this chain.
    /// @param _local_token  Address of the ERC20 on this chain.
    /// @param _remote_token Address of the corresponding token on the remote chain.
    /// @param _amount      Amount of local tokens to deposit.
    /// @param minGasLimit Minimum amount of gas that the bridge can be relayed with.
    function RelayedToAnotherLayer(
        address _local_token,
        address _remote_token,
        // address _to, -> msg.sender
        uint256 _amount,
        uint32 minGasLimit
    ) external;

    function change_correspond_bridge_address (address payable _valid_address) external;
}
