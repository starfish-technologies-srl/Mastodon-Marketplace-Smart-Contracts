// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import {IERC721} from "@openzeppelin/contracts/interfaces/IERC721.sol";
import {IERC1155} from "@openzeppelin/contracts/interfaces/IERC1155.sol";

/**
 * @dev A decentralized marketplace for buying and selling NFTs (Non-Fungible Tokens) using Ethereum.
 * @notice This contract allows users to list NFTs for sale, buy NFTs from other users, and delist NFTs.
 */
interface IMastodonMarketplace {
    /**
     * @dev Enumeration of possible payout tokens for an NFT sale.
     */
    enum PayoutToken {
        NativeToken, // Ether
        Xen, // ERC20 token (Xen)
        Dxn // ERC20 token (Dxn)
    }

    enum AssetClass {
        ERC721, // Represents a single ERC721 token.
        ERC1155, // Represents an ERC1155 token.
        BothClass_ERC721,
        BothClass_ERC1155
    }

    /**
     * @dev Struct representing the details of an NFT listing.
     */
    struct InputOrder {
        address nftContract; // The address of the NFT contract.
        uint256 tokenId; // The ID of the NFT or batch of NFTs.
        uint256 supply; // The supply of NFTs for ERC1155 tokens, set to 0 for ERC721.
        PayoutToken payoutToken; // The desired token to receive as payment.
        uint256 price; // The price at which the NFT is listed for sale.
    }

    /**
     * @dev Struct representing an active order on the marketplace.
     */
    struct Order {
        address nftContract; // The address of the NFT contract.
        address seller; // The address of the seller.
        uint256 tokenId; // The ID of the NFT or batch of NFTs.
        uint256 supply; // The supply of NFTs for ERC1155 tokens, set to 0 for ERC721.
        PayoutToken payoutToken; // The desired token to receive as payment.
        uint256 price; // The price at which the NFT is listed for sale.
        AssetClass assetClass; // The type of NFT collection
    }

    /**
     * @dev Struct representing the details necessary to change the price.
     */
    struct Price {
        PayoutToken payoutToken; // The desired token to receive as payment.
        uint256 newPrice; // The new price for Order
    }

    /**
     * @dev Event emitted when a new NFT is listed on the marketplace.
     * @param orderIndex The index of the order in the marketplace.
     * @param order The details of the listed NFT order.
     */
    event List(uint256 indexed orderIndex, Order order);

    /**
     * @dev Event emitted when an existing NFT listing is delisted from the marketplace.
     * @param orderIndex The index of the order in the marketplace.
     * @param order The details of the delisted NFT order.
     */
    event Delist(uint256 indexed orderIndex, Order order);

    /**
     * @dev Event emitted when a user successfully purchases an NFT from the marketplace.
     * @param orderIndex The index of the order in the marketplace.
     * @param order The details of the purchased NFT order.
     */
    event Buy(uint256 indexed orderIndex, Order order);

    /**
     * @dev This event provides information about the updated price and payout token for a specific NFT listing.
     * @param orderIndex The index of the NFT listing for which the price has been changed.
     * @param newPrice A Price structure representing the new price and payout token for the NFT.
     */
    event NewPrice(uint256 indexed orderIndex, Price newPrice);

    /**
     * @dev Lists multiple NFTs on the marketplace.
     * @param inputOrders An array of InputOrder structures representing the NFTs to be listed.
     */
    function batchList(InputOrder[] calldata inputOrders) external;

    /**
     * @dev Delists multiple NFTs from the marketplace.
     * @param listIndexes An array of indexes representing the NFT orders to be delisted.
     */
    function batchDelist(uint256[] calldata listIndexes) external;

    /**
     * @dev Allows users to purchase multiple NFTs from the marketplace.
     * @param listIndexes An array of indexes representing the NFT orders to be purchased.
     */
    function batchBuy(uint256[] calldata listIndexes) external payable;

    /**
     * @notice Allows the order owner to change the prices of listed NFTs and the payout token.
     * @param listIndexes An array of list indexes representing the NFTs for which the prices will be changed.
     * @param newPrices An array of Price structures representing the new payout tokens & prices corresponding to the NFTs.
     */
    function batchChangePrice(uint256[] calldata listIndexes, Price[] calldata newPrices ) external;
}
