// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import {ERC165Checker} from "@openzeppelin/contracts/utils/introspection/ERC165Checker.sol";
import {IMastodonMarketplace} from "./IMastodonMarketplace.sol";
import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";
import {IERC721} from "@openzeppelin/contracts/interfaces/IERC721.sol";
import {IERC1155} from "@openzeppelin/contracts/interfaces/IERC1155.sol";
import {IERC721Receiver} from "@openzeppelin/contracts/interfaces/IERC721Receiver.sol";
import {IERC1155Receiver} from "@openzeppelin/contracts/interfaces/IERC1155Receiver.sol";

/**
 * @title MastodonMarketplace
 * @dev A decentralized marketplace contract for trading ERC721 and ERC1155 NFTs.
 * Users can list, delist, and buy NFTs using native tokens or specified ERC20 tokens.
 */
contract MastodonMarketplace is
    IMastodonMarketplace,
    IERC721Receiver,
    IERC1155Receiver
{
    /**
     * @notice The global index representing the unique identifier for NFT listings on the marketplace.
     * @dev It increments with each new listing, providing a unique identifier for tracking and referencing listings.
     */
    uint256 public globalIndex;

    // Constants for fee calculations
    uint8 private constant DEV_FEE_BPS = 150;
    uint8 private constant BURN_FEE_BPS = 250;
    uint16 private constant MAX_BPS = 10000;

    //The address of the contract developer.
    address public immutable dev;

    //The ERC20 token contract address for the $XEN token.
    IERC20 public immutable xen;

    //The ERC20 token contract address for the $DXN token.
    IERC20 public immutable dxn;

    //The address of smart contract designated for burning DXN tokens.
    address public immutable dxnBuyBurn;

    // Mapping to store NFT orders
    mapping(uint256 listIndex => Order order) public orders;

    /**
     * @dev Constructor to initialize the MastodonMarketplace contract.
     * @param _xen The address of the $XEN token contract.
     * @param _dxn The address of the $DXN token contract.
     * @param _dxnBuyBurn The address of smart contract for burning DXN tokens.
     */
    constructor(IERC20 _xen, IERC20 _dxn, address _dxnBuyBurn) {
        xen = _xen;
        dxn = _dxn;
        dxnBuyBurn = _dxnBuyBurn;
        dev = msg.sender;
    }

    /**
     * @dev Batch lists multiple NFTs for sale on the marketplace.
     * @param inputOrders An array of InputOrder structures representing the NFTs to be listed.
     */
    function batchList(InputOrder[] calldata inputOrders) external {
        uint256 arrayLength = inputOrders.length;
        for (uint256 i = 0; i < arrayLength; i++) {
            _list(inputOrders[i]);
        }
    }

    /**
     * @dev Batch delists multiple NFTs from the marketplace.
     * @param listIndexes An array of list indexes representing the NFTs to be delisted.
     */
    function batchDelist(uint256[] calldata listIndexes) external {
        uint256 arrayLength = listIndexes.length;
        for (uint256 i = 0; i < arrayLength; i++) {
            _delist(listIndexes[i]);
        }
    }

    /**
     * @dev Batch buys multiple NFTs from the marketplace.
     * @param listIndexes An array of list indexes representing the NFTs to be bought.
     */
    function batchBuy(uint256[] calldata listIndexes) external payable {
        uint256 arrayLength = listIndexes.length;
        for (uint256 i = 0; i < arrayLength; i++) {
            _buy(listIndexes[i]);
        }
    }

    /**
     * @dev Lists a single NFT for sale on the marketplace.
     * @param inputOrder An InputOrder structure representing the NFT to be listed.
     */
    function _list(InputOrder calldata inputOrder) internal {
        globalIndex++;

        Order storage newOrder = orders[globalIndex];

        if (
            ERC165Checker.supportsInterface(
                inputOrder.nftContract,
                type(IERC721).interfaceId
            )
        ) {
            newOrder.nftContract = inputOrder.nftContract;
            newOrder.tokenId = inputOrder.tokenId;
            newOrder.payoutToken = inputOrder.payoutToken;
            newOrder.price = inputOrder.price;
            newOrder.seller = msg.sender;

            IERC721(inputOrder.nftContract).safeTransferFrom(
                msg.sender,
                address(this),
                inputOrder.tokenId
            );
        } else if (
            ERC165Checker.supportsInterface(
                inputOrder.nftContract,
                type(IERC1155).interfaceId
            )
        ) {
            newOrder.nftContract = inputOrder.nftContract;
            newOrder.tokenId = inputOrder.tokenId;
            newOrder.supply = inputOrder.supply;
            newOrder.payoutToken = inputOrder.payoutToken;
            newOrder.price = inputOrder.price;
            newOrder.seller = msg.sender;

            IERC1155(inputOrder.nftContract).safeTransferFrom(
                msg.sender,
                address(this),
                inputOrder.tokenId,
                inputOrder.supply,
                "0x0"
            );
        } else revert("Mastodon: not supported");

        emit List(globalIndex, newOrder);
    }

    /**
     * @dev Delists a single NFT from the marketplace.
     * @param listIndex The index of the NFT to be delisted.
     */
    function _delist(uint256 listIndex) internal {
        require(
            orders[listIndex].seller == msg.sender,
            "Mastodon: not owner of order"
        );

        if (
            ERC165Checker.supportsInterface(
                orders[listIndex].nftContract,
                type(IERC721).interfaceId
            )
        ) {
            IERC721(orders[listIndex].nftContract).safeTransferFrom(
                address(this),
                msg.sender,
                orders[listIndex].tokenId
            );
        } else if (
            ERC165Checker.supportsInterface(
                orders[listIndex].nftContract,
                type(IERC1155).interfaceId
            )
        ) {
            IERC1155(orders[listIndex].nftContract).safeTransferFrom(
                address(this),
                msg.sender,
                orders[listIndex].tokenId,
                orders[listIndex].supply,
                "0x0"
            );
        } else revert("not supported");

        delete (orders[listIndex]);
        emit Delist(globalIndex, orders[globalIndex]);
    }

    /**
     * @dev Buys a single NFT from the marketplace.
     * @param listIndex The index of the NFT to be bought.
     */
    function _buy(uint256 listIndex) internal {
        uint256 toSeller = (orders[listIndex].price * 9600) / MAX_BPS;
        uint256 toDev = (orders[listIndex].price * DEV_FEE_BPS) / MAX_BPS;
        uint256 toBurn = (orders[listIndex].price * BURN_FEE_BPS) / MAX_BPS;

        if (orders[listIndex].payoutToken == PayoutToken.NativeToken) {
            require(
                msg.value == orders[listIndex].price,
                "Mastodon: invalid price"
            );

            (bool success, ) = orders[listIndex].seller.call{value: toSeller}(
                ""
            );
            require(success, "1.Payment failed.");

            (success, ) = dxnBuyBurn.call{value: toBurn}("");
            require(success, "2.Payment failed.");

            (success, ) = dev.call{value: toDev}("");
            require(success, "3.Payment failed.");
        } else if (orders[listIndex].payoutToken == PayoutToken.Xen) {
            xen.transfer(orders[listIndex].seller, toSeller);

            xen.transfer(orders[listIndex].seller, toDev);

            xen.transfer(dxnBuyBurn, toBurn);
        } else {
            dxn.transfer(orders[listIndex].seller, toSeller);

            dxn.transfer(orders[listIndex].seller, toDev);

            dxn.transfer(0x0000000000000000000000000000000000000000, toBurn);
        }

        if (orders[listIndex].supply == 0) {
            IERC721(orders[listIndex].nftContract).safeTransferFrom(
                address(this),
                msg.sender,
                orders[listIndex].tokenId
            );
        } else {
            IERC1155(orders[listIndex].nftContract).safeTransferFrom(
                address(this),
                msg.sender,
                orders[listIndex].tokenId,
                orders[listIndex].supply,
                "0x0"
            );
        }

        delete (orders[listIndex]);
        emit Buy(globalIndex, orders[globalIndex]);
    }

    // ERC721 and ERC1155 receiver functions... //

    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4) {
        return (this.onERC721Received.selector);
    }

    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4) {
        return (this.onERC1155Received.selector);
    }

    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4) {
        return (this.onERC1155Received.selector);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(
        bytes4 interfaceId
    ) public view override returns (bool) {}
}
