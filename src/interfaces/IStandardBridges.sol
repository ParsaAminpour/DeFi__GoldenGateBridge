// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

interface IL1StandardBridge {
    // Calls same internal function as bridgeERC20To
    function depositERC20To(
        address l1_token,
        address l2_token,
        address to,
        uint256 amount,
        uint32 min_gas_limit,
        bytes calldata data
    ) external;

    function bridgeERC20To(
        address local_token,
        address remote_token,
        address to,
        uint256 amount,
        uint32 min_gas_limit,
        bytes calldata data
    ) external;
}

interface IL2StandardBridge {
    // Calls same internal function as bridgeERC20To
    function withdrawTo(address l2_token, address to, uint256 amount, uint32 min_gas_limit, bytes calldata data)
        external;

    function bridgeERC20To(
        address local_token,
        address remote_token,
        address to,
        uint256 amount,
        uint32 min_gas_limit,
        bytes calldata data
    ) external;
}

// L1    | L2
// ERC20 | OPERC20 (OptimismMintableERC20)

// Send ERC20 from L1 to L2
// Lock ERC20 on L1StandardBrige
// -> CrossDomainMessenger (L1)
// -> L2StandardBrige (L2)
// -> Mint OPERC20 (L2)

// Send ERC20 from L2 to L1
// Burn OPERC20 by L2StandardBrige
// -> CrossDomainMessenger (L2)
// -> Unlock ERC20 on L1StandardBridge

// 1. Deploy ERC20 on L1
// 2. Deploy OPERC20 on L2
// 3. Deploy L1Bridge on L1
// 4. Deploy L2Bridge on L2
// 5. Mint ERC20 and approve L1Bridge
// 6. Send ERC20 to L2
// 7. Check OPERC20 balance of L2Bridge
// 8. Withdraw OPERC20 on L2
// 9. Approve OPERC20 for L2Bridge and send ERC20 to L1
// 10. Check ERC20 balance of L1Bridge
// 11. Withdraw ERC20 on L1
// 12. Check finalize tx and token transfer