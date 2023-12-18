// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import {IERC721} from '@openzeppelin/contracts/interfaces/IERC721.sol';
import {IERC1155} from '@openzeppelin/contracts/interfaces/IERC1155.sol';

/**
 * @title MastodonMarketplace
 * @dev A decentralized marketplace for buying and selling NFTs (Non-Fungible Tokens) using Ethereum.
 * @notice This contract allows users to list NFTs for sale, buy NFTs from other users, and delist NFTs.
 */
interface IMastodonMarketplace {

    /**
     * @dev Enumeration of possible payout tokens for an NFT sale.
     */
    enum PayoutToken {
        NativeToken, // Ether 
        Xen,         // ERC20 token (Xen)
        Dxn          // ERC20 token (Dxn)
    }

    /**
     * @dev Struct representing the details of an NFT listing.
     */
    struct InputOrder {
        address nftContract;  // The address of the NFT contract.
        uint256 tokenId;      // The ID of the NFT or batch of NFTs.
        uint256 supply;       // The supply of NFTs for ERC1155 tokens, set to 0 for ERC721.
        PayoutToken payoutToken;  // The desired token to receive as payment.
        uint256 price;        // The price at which the NFT is listed for sale.
    }

    /**
     * @dev Struct representing an active order on the marketplace.
     */
    struct Order {
        address nftContract;  // The address of the NFT contract.
        address seller;       // The address of the seller.
        uint256 tokenId;      // The ID of the NFT or batch of NFTs.
        uint256 supply;       // The supply of NFTs for ERC1155 tokens, set to 0 for ERC721.
        PayoutToken payoutToken;  // The desired token to receive as payment.
        uint256 price;        // The price at which the NFT is listed for sale.
    }

    /**
     * @dev Event emitted when a new NFT is listed on the marketplace.
     * @param orderIndex The index of the order in the marketplace.
     * @param order The details of the listed NFT order.
     */
    event List(uint256 orderIndex, Order order);

    /**
     * @dev Event emitted when an existing NFT listing is delisted from the marketplace.
     * @param orderIndex The index of the order in the marketplace.
     * @param order The details of the delisted NFT order.
     */
    event Delist(uint256 orderIndex, Order order);

    /**
     * @dev Event emitted when a user successfully purchases an NFT from the marketplace.
     * @param orderIndex The index of the order in the marketplace.
     * @param order The details of the purchased NFT order.
     */
    event Buy(uint256 orderIndex, Order order);

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

    //TODO changePrice function

    function changePrice(uint256[] calldata listIndexes) external;
}
