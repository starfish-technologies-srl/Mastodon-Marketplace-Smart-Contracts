// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import {ERC165Checker} from "@openzeppelin/contracts/utils/introspection/ERC165Checker.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {IMastodonMarketplace} from "./IMastodonMarketplace.sol";
import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";
import {IERC721} from "@openzeppelin/contracts/interfaces/IERC721.sol";
import {IERC1155} from "@openzeppelin/contracts/interfaces/IERC1155.sol";
import {IERC721Receiver} from "@openzeppelin/contracts/interfaces/IERC721Receiver.sol";
import {IERC1155Receiver} from "@openzeppelin/contracts/interfaces/IERC1155Receiver.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

/**
 * @title MastodonMarketplace
 * @dev A decentralized marketplace contract for trading ERC721 and ERC1155 NFTs.
 * Users can list, delist, and buy NFTs using native tokens or specified ERC20 tokens.
 */
contract MastodonMarketplace is
    IMastodonMarketplace,
    IERC721Receiver,
    IERC1155Receiver,
    ReentrancyGuard
{
    using SafeERC20 for IERC20;
    /**
     * @notice The global index representing the unique identifier for NFT listings on the marketplace.
     * @dev It increments with each new listing, providing a unique identifier for tracking and referencing listings.
     */
    uint256 public globalIndex;

    // Constants for fee calculations
    uint8 private constant DEV_FEE_BPS = 150;
    uint8 private constant BURN_FEE_BPS = 250;
    uint16 private constant MAX_BPS = 10000;

    //The ERC20 token contract address for the $XEN token.
    IERC20 public immutable xen;

    //The ERC20 token contract address for the $DXN token.
    IERC20 public immutable dxn;

    //The address of the contract developer.
    address public immutable dev;

    //The address of smart contract designated to BUY & BURN $DXN tokens
    //with $XEN token and native token of blockchain.
    address public dxnBuyBurn;

    /**
     * @dev The pending DXN token burn address.
     * @notice This address is set and updated by the developer before it becomes the active burn address.
     */
    address public pendingDxnBuyBurn;

    /**
     * @dev Flag indicating whether ownership of the DXN token burn functionality is renounced.
     * @notice If true, ownership is not renounced; if false, ownership is renounced.
     */
    bool public isOwned = true;

    /**
     * @dev Constant defining the duration of the time-lock for updates to the DXN token burn address.
     * @notice After setting a pending burn address, a delay of LOCK_DURATION must pass before it becomes active.
     */
    uint256 private constant LOCK_DURATION = 7 days;

    /**
     * @dev The timestamp threshold for updating the DXN token burn address.
     * @notice This threshold determines when the pending burn address becomes the active burn address.
     */
    uint256 public timeThreshold;

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
    function batchList(InputOrder[] calldata inputOrders) external nonReentrant {
        uint256 arrayLength = inputOrders.length;
        for (uint256 i = 0; i < arrayLength; i++) {
            _list(inputOrders[i]);
        }
    }

    /**
     * @dev Batch delists multiple NFTs from the marketplace.
     * @param listIndexes An array of list indexes representing the NFTs to be delisted.
     */
    function batchDelist(uint256[] calldata listIndexes) external nonReentrant {
        uint256 arrayLength = listIndexes.length;
        for (uint256 i = 0; i < arrayLength; i++) {
            _delist(listIndexes[i]);
        }
    }

    /**
     * @dev Batch buys multiple NFTs from the marketplace.
     * @param listIndexes An array of list indexes representing the NFTs to be bought.
     */
    function batchBuy(uint256[] calldata listIndexes) external payable nonReentrant {
        uint256 arrayLength = listIndexes.length;
        for (uint256 i = 0; i < arrayLength; i++) {
            _buy(listIndexes[i]);
        }
    }

    /**
     * @dev Batch changing prices and payout tokens for multiple NFTs from the marketplace.
     * @param listIndexes An array of list indexes representing the NFTs for which the prices will be changed.
     * @param newPrices An array of Price structures representing the new prices corresponding to the NFTs.
     */
    function batchChangePrice(uint256[] calldata listIndexes, Price[] calldata newPrices) external nonReentrant {
        require(listIndexes.length == newPrices.length, "Mastodon: length diff");

        uint256 arrayLength = listIndexes.length;
        for (uint256 i = 0; i < arrayLength; i++) {
            _changePrice(listIndexes[i], newPrices[i]);
        }
    }

    /**
     * @dev Sets the pending $DXN token burn address and updates the time threshold.
     * @param _dxnBuyBurn The address for buying and burning DXN tokens.
     */
    function setPendingDxnBuyBurn(address _dxnBuyBurn) external {
        require(isOwned == true, "Mastodon: renounced to ownership");
        require(msg.sender == dev, "Mastodon: not dev");
        timeThreshold = block.timestamp + LOCK_DURATION;
        pendingDxnBuyBurn = _dxnBuyBurn;
    }

    /**
     * @dev Accepts the pending $DXN token burn address after conditions are met.
     */
    function acceptDxnBuyBurn() external {
        require(isOwned == true, "Mastodon: renounced to ownership");
        require(msg.sender == dev, "Mastodon: not dev");
        require(block.timestamp > timeThreshold, "Mastodon: not enough time passed");
        require(pendingDxnBuyBurn != address(0), "Mastodon: zero address not alowed");

        dxnBuyBurn = pendingDxnBuyBurn;
    }

    /**
     * @dev Renounces ownership of changing the dxn address for buy and burn.
     */
    function renounceDxnBuyBurnOwnership () external {
        require(msg.sender == dev, "Mastodon: not dev");
        isOwned = false;
    }

    /**
     * @dev Lists a single NFT for sale on the marketplace.
     * @param inputOrder An InputOrder structure representing the NFT to be listed.
     */
    function _list(InputOrder calldata inputOrder) internal {
        globalIndex++;

        Order storage newOrder = orders[globalIndex];
        newOrder.nftContract = inputOrder.nftContract;
        newOrder.tokenId = inputOrder.tokenId;
        newOrder.payoutToken = inputOrder.payoutToken;
        newOrder.price = inputOrder.price;
        newOrder.seller = msg.sender;

        bool supportsERC721 = ERC165Checker.supportsInterface(
            inputOrder.nftContract,
            type(IERC721).interfaceId
        );
        bool supportsERC1155 = ERC165Checker.supportsInterface(
            inputOrder.nftContract,
            type(IERC1155).interfaceId
        );

        if (supportsERC721 && !supportsERC1155) {
            newOrder.assetClass = AssetClass.ERC721;
            IERC721(inputOrder.nftContract).safeTransferFrom(
                msg.sender,
                address(this),
                inputOrder.tokenId
            );
        } else if (!supportsERC721 && supportsERC1155) {
            require(inputOrder.supply > 0, "Mastodon: erc1155 supply > 0");
            newOrder.supply = inputOrder.supply;
            newOrder.assetClass = AssetClass.ERC1155;
            IERC1155(inputOrder.nftContract).safeTransferFrom(
                msg.sender,
                address(this),
                inputOrder.tokenId,
                inputOrder.supply,
                "0x0"
            );
        } else if (supportsERC721 && supportsERC1155) {
            if (inputOrder.supply == 0) {
                newOrder.assetClass = AssetClass.BothClass_ERC721;
                IERC721(inputOrder.nftContract).safeTransferFrom(
                    msg.sender,
                    address(this),
                    inputOrder.tokenId
                );
            } else {
                newOrder.assetClass = AssetClass.BothClass_ERC1155;
                newOrder.supply = inputOrder.supply;
                IERC1155(inputOrder.nftContract).safeTransferFrom(
                    msg.sender,
                    address(this),
                    inputOrder.tokenId,
                    inputOrder.supply,
                    "0x0"
                );
            }
        } else {
            revert("Mastodon: not supported");
        }

        emit List(globalIndex, newOrder);
    }

    /**
     * @dev Delists a single NFT from the marketplace.
     * @param listIndex The index of the NFT to be delisted.
     */
    function _delist(uint256 listIndex) internal {
        require(
            orders[listIndex].seller == msg.sender,
            "Mastodon: not the order owner"
        );

        Order memory order = orders[listIndex];

        if (
            order.assetClass == AssetClass.ERC721 ||
            order.assetClass == AssetClass.BothClass_ERC721
        ) {
            IERC721(orders[listIndex].nftContract).safeTransferFrom(
                address(this),
                msg.sender,
                orders[listIndex].tokenId
            );
        } else if (
            order.assetClass == AssetClass.ERC1155 ||
            order.assetClass == AssetClass.BothClass_ERC1155

        ) {
            IERC1155(orders[listIndex].nftContract).safeTransferFrom(
                address(this),
                msg.sender,
                order.tokenId,
                order.supply,
                "0x0"
            );
        } else revert("Mastodon: not supported");

        emit Delist(listIndex, order);
        delete (orders[listIndex]);
    }

    /**
     * @dev Buys a single NFT from the marketplace.
     * @param listIndex The index of the NFT to be bought.
     */
    function _buy(uint256 listIndex) internal {
        Order memory order = orders[listIndex];

        uint256 price = order.price;

        uint256 sellerProceeds = (price * 9600) / MAX_BPS;
        uint256 developerFee = (price * DEV_FEE_BPS) /MAX_BPS;
        uint256 burnAmount = (price * BURN_FEE_BPS) / MAX_BPS;

        if (order.payoutToken == PayoutToken.NativeToken) {
            require(address(this).balance >= price, "Mastodon: invalid price");

            (bool success, ) = order.seller.call{
                value: sellerProceeds
            }("");
            require(success, "1.Payment failed.");

            (success, ) = dev.call{value: developerFee}("");
            require(success, "2.Payment failed.");

            (success, ) = dxnBuyBurn.call{value: burnAmount}("");
            require(success, "3.Payment failed.");
        } else if (order.payoutToken == PayoutToken.Xen) {
            xen.safeTransfer(order.seller, sellerProceeds);

            xen.safeTransfer(dev, developerFee);

            xen.safeTransfer(dxnBuyBurn, burnAmount);
        } else {
            dxn.safeTransfer(order.seller, sellerProceeds);

            dxn.safeTransfer(dev, developerFee);

            dxn.safeTransfer(
                0x0000000000000000000000000000000000000000,
                burnAmount
            );
        }

        if (order.assetClass == AssetClass.ERC721 ||
            order.assetClass == AssetClass.BothClass_ERC721) {
            IERC721(order.nftContract).safeTransferFrom(
                address(this),
                msg.sender,
                order.tokenId
            );
        } else {
            IERC1155(order.nftContract).safeTransferFrom(
                address(this),
                msg.sender,
                order.tokenId,
                order.supply,
                "0x0"
            );
        }

        emit Buy(listIndex, orders[listIndex]);
        delete (orders[listIndex]);
    }

    /**
     * @dev Updates the price and payout token for a specific NFT listing.
     * @param listIndex The index of the NFT listing to be updated.
     * @param newPrice A Price structure representing the new price and payout token for the NFT.
     */
    function _changePrice(uint256 listIndex, Price calldata newPrice) internal {
        require(
            orders[listIndex].seller == msg.sender,
            "Mastodon: not the order owner"
        );

        orders[listIndex].payoutToken = newPrice.payoutToken;
        orders[listIndex].price = newPrice.newPrice;

        emit NewPrice(listIndex, newPrice);
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
        return (this.onERC1155BatchReceived.selector);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(
        bytes4 interfaceId
    ) public view override returns (bool) {}
}
