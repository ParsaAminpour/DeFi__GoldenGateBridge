// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/*
 * @author ParsaAminpour
 * @notice GoldenBridgeTokenL1 is just a simple ERC20 token contract
    that we want to bridge it over to L2.
 * @dev the Ownable won't deny the decentralization principles. Just for minting.
*/
contract TokenL1 is ERC20, Ownable {
    error GoldenBridgeTokenL1__amountShouldNotBeZero();
    error GoldenBridgeTokenL1__AddressCouldNotBeZero();
    error GoldenBridgeTokenL1__OnlyEquilibriumCoreCouldCall();

    // msg.sender is the EquilibriumCore contract address
    constructor() ERC20("GoldenBridgeToken", "GOLD") Ownable(msg.sender) {}

    // The onlyOwner don't break the decentralization principle.
    function mint(address _to, uint256 _amount) external onlyOwner returns (bool) {
        if (_amount == 0) revert GoldenBridgeTokenL1__amountShouldNotBeZero();

        super._mint(_to, _amount);
        return true;
    }

    function burn(address _fire_owner, uint256 _amount) external onlyOwner returns (bool) {
        if (_amount == 0) revert GoldenBridgeTokenL1__amountShouldNotBeZero();

        super._burn(_fire_owner, _amount);
        return true;
    }
}
