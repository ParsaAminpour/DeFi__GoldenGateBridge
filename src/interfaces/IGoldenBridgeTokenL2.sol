// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IGoldenBridgeTokenL2 {

    event TokenMinted(address indexed account, uint256 amount);

    event TokenBurned(address indexed account, uint256 amount);

    function REMOTE_TOKEN() external view returns (address);

    function BRIDGE() external view returns (address);

    function mint(address to, uint256 amount) external;

    function burn(address from, uint256 amount) external; 

}