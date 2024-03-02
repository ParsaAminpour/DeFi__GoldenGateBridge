// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {IERC165} from "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import {IOptimismMintableERC20} from "./interfaces/IOptimismMintableERC20.sol";

contract BossBridgeL2Token is IOptimismMintableERC20, ERC20 {
    error BossBridgeL2Token__OnlyBridgeHasAccess();
    error BossBridgeL2Token__BossBridgeL2TokenCannotBeWithdrawn();

    /// @notice Address of the corresponding version of this token on the remote chain.
    address public immutable REMOTE_TOKEN;

    /// @notice Address of the StandardBridge on this network.
    address public immutable BRIDGE;

    event BossBridgeL2Token__TokenMinted(address indexed account, uint256 amount);
    event BossBridgeL2Token__TokenBurned(address indexed account, uint256 amount);

    /// @notice A modifier that only allows the bridge to call.
    modifier onlyBridge() {
        if (msg.sender != BRIDGE) revert BossBridgeL2Token__OnlyBridgeHasAccess();
        _;
    }

    /// @param _bridge      Address of the L2 standard bridge.
    //      0x4200000000000000000000000000000000000007
    /// @param _remoteToken Address of the corresponding L1 token.
    /// @param _name        ERC20 name.
    /// @param _symbol      ERC20 symbol.
    constructor(address _bridge, address _remoteToken, string memory _name, string memory _symbol)
        ERC20(_name, _symbol)
    {
        REMOTE_TOKEN = _remoteToken;
        BRIDGE = _bridge;
    }

    /// @notice ERC165 interface check function.
    /// @param _interfaceId Interface ID to check.
    /// @return Whether or not the interface is supported by this contract.
    function supportsInterface(bytes4 _interfaceId) external pure virtual returns (bool) {
        bytes4 iface1 = type(IERC165).interfaceId;
        // Interface corresponding to the updated OptimismMintableERC20 (this contract).
        bytes4 iface2 = type(IOptimismMintableERC20).interfaceId;
        return _interfaceId == iface1 || _interfaceId == iface2;
    }

    /// @notice Allows the StandardBridge on this network to mint tokens.
    /// @param _to     Address to mint tokens to.
    /// @param _amount Amount of tokens to mint.
    function mint(address _to, uint256 _amount) external virtual override(IOptimismMintableERC20) onlyBridge {
        _mint(_to, _amount);
        emit BossBridgeL2Token__TokenMinted(_to, _amount);
    }

    /// @notice Prevents tokens from being withdrawn to L1.
    function burn(address, uint256) external virtual override(IOptimismMintableERC20) onlyBridge {
        revert BossBridgeL2Token__BossBridgeL2TokenCannotBeWithdrawn();
    }

    /// @custom:legacy
    /// @notice Legacy getter for REMOTE_TOKEN.
    function remoteToken() public view returns (address) {
        return REMOTE_TOKEN;
    }

    /// @custom:legacy
    /// @notice Legacy getter for BRIDGE.
    function bridge() public view returns (address) {
        return BRIDGE;
    }
}
