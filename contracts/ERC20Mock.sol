// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract ERC20Mock is ERC20 {
    constructor() ERC20("MockToken", "MTK") {
        // Mint some tokens to the contract deployer
        _mint(msg.sender, 1000000 * 10**18);
    }
}