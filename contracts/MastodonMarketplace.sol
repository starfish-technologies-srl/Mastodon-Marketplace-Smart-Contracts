// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import "hardhat/console.sol";

import {IMastodonMarketplace} from "./IMastodonMarketplace.sol";
import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";
import {IERC721} from "@openzeppelin/contracts/interfaces/IERC721.sol";
import {IERC1155} from "@openzeppelin/contracts/interfaces/IERC1155.sol";

import {ERC165Checker} from "@openzeppelin/contracts/utils/introspection/ERC165Checker.sol";

import {IERC721Receiver} from "@openzeppelin/contracts/interfaces/IERC721Receiver.sol";
import {IERC1155Receiver} from "@openzeppelin/contracts/interfaces/IERC1155Receiver.sol";

contract MastodonMarketplace is
    IMastodonMarketplace,
    IERC721Receiver,
    IERC1155Receiver
{
    uint256 globalIndex;

    mapping(uint256 listIndex => Order order) public orders;

    IERC20 public immutable xen;

    IERC20 public immutable dxn;

    address public immutable dxnBuyBurn;

    uint8 constant DEV_FEE_BPS = 150; //BPS, 1.5%, 10% = 1000

    uint8 constant BURN_FEE_BPS = 250;

    uint16 constant MAX_BPS = 10000;

    address public immutable dev;

    constructor(IERC20 _xen, IERC20 _dxn, address _dxnBuyBurn) {
        xen = _xen;
        dxn = _dxn;
        dxnBuyBurn = _dxnBuyBurn;
        dev = msg.sender;
    }

    function batchList(InputOrder[] memory inputOrders) external {
        for (uint256 i = 0; i < inputOrders.length; i++) {
            _list(inputOrders[i]);
        }
    }

    function batchDelist(uint256[] calldata listIndexes) external {
        for (uint256 i = 0; i < listIndexes.length; i++) {
            _delist(listIndexes[i]);
        }
    }

    function batchBuy(
        uint256[] calldata listIndexes,
        PayoutToken[] calldata payoutTokens
    ) external payable {
        for (uint256 i = 0; i < listIndexes.length; i++) {
            _buy(listIndexes[i], payoutTokens[i]);
        }
    }

    function _list(InputOrder memory inputOrder) public {
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
        } else revert("not supported");

        emit List(globalIndex, newOrder);
    }

    function _delist(uint256 listIndex) public {
        require(orders[listIndex].seller == msg.sender, "not owner");

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

    function _buy(uint256 listIndex, PayoutToken token) public payable {
        uint256 toSeller = (orders[listIndex].price * 9600) / MAX_BPS;
        uint256 toDev = (orders[listIndex].price * DEV_FEE_BPS) / MAX_BPS;
        uint256 toBurn = (orders[listIndex].price * BURN_FEE_BPS) / MAX_BPS;

        if (token == PayoutToken.NativeToken) {
            require(msg.value == orders[listIndex].price, "invalid price");

            (bool success, ) = orders[listIndex].seller.call{value: toSeller}(
                ""
            );
            require(success, "Payment failed.");

            (success, ) = dxnBuyBurn.call{value: toBurn}("");
            require(success, "Payment failed.");

            (success, ) = orders[listIndex].seller.call{value: toDev}("");
            require(success, "Payment failed.");
        } else if (token == PayoutToken.Xen) {
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
    ) public view virtual override returns (bool) {
        return interfaceId == type(IERC1155).interfaceId; // ||
        // interfaceId == type(IERC1155MetadataURI).interfaceId ||
        // super.supportsInterface(interfaceId);
    }
}
