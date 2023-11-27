// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract ERC721Mock is ERC721 {
    constructor() ERC721("MockNFT", "MNFT") {}

    uint256 private tokenIdCounter = 1;

    // Override the mint function to allow anyone to mint tokens
    function mint(address recipient) public {
        _mint(recipient, tokenIdCounter);
        tokenIdCounter++;
    }

}