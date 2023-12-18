// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract BurnerMock {
    IERC20 public xen;

    receive() external payable {
        // This function is executed when a contract receives plain Ether (without data)
    }

    // Constructor to set the address of the ERC20 token
    constructor(IERC20 _erc20TokenAddress) {
        xen = _erc20TokenAddress;
    }

    // Function to get the balance of native token held by the contract
    function getNativeTokenBalance() public view returns (uint256) {
        return address(this).balance;
    }

    // Function to get the balance of ERC20 token held by the contract
    function getERC20TokenBalance(
        address tokenAddress
    ) public view returns (uint256) {
        return IERC20(tokenAddress).balanceOf(address(this));
    }
}
