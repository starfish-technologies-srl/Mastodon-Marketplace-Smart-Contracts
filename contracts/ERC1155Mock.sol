// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";

contract ERC1155Mock is ERC1155 {
    constructor() ERC1155("//uri") {}

    enum NFTType {
        GOLD,
        SILVER,
        BRONZE
    }

    // Mint a specified amount of gold NFTs
    function mintGold(address recipient, uint256 amount) public {
        _mint(recipient, uint256(NFTType.GOLD), amount, "");
    }

    // Mint a specified amount of silver NFTs
    function mintSilver(address recipient, uint256 amount) public {
        _mint(recipient, uint256(NFTType.SILVER), amount, "");
    }

    // Mint a specified amount of bronze NFTs
    function mintBronze(address recipient, uint256 amount) public {
        _mint(recipient, uint256(NFTType.BRONZE), amount, "");
    }
}