// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

interface IBossBridge {
    /// @notice Sends ERC20 tokens to a receiver's address on the other chain. Note that if the
    ///         ERC20 token on the other chain does not recognize the local token as the correct
    ///         pair token, the ERC20 bridge will fail and the tokens will be returned to sender on
    ///         this chain.
    /// @param _local_token  Address of the ERC20 on this chain.
    /// @param _remote_token Address of the corresponding token on the remote chain.
    /// @param _amount      Amount of local tokens to deposit.
    /// @param minGasLimit Minimum amount of gas that the bridge can be relayed with.
    /// @param _extraData   Extra data to be sent with the transaction. Note that the recipient will
    ///                     not be triggered with this data, but it will be emitted and can be used
    ///                     to identify the transaction.
    function RelayedToAnotherLayer(
        address _local_token,
        address _remote_token,
        // address _to, -> msg.sender
        uint256 _amount,
        uint32 minGasLimit,
        bytes calldata _extraData
    ) external;
}