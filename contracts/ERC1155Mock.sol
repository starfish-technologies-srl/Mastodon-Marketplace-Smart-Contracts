// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";

contract ERC1155Mock is ERC1155 {
    constructor() ERC1155("//uri") {}

    // Mint a specified amount of gold NFTs
    function mint(address recipient, uint256 id,  uint256 value) public {
        _mint(recipient, id, value, "");
    }

}