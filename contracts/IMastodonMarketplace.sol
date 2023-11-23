// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import {IERC721} from '@openzeppelin/contracts/interfaces/IERC721.sol';
import {IERC1155} from '@openzeppelin/contracts/interfaces/IERC1155.sol';

interface IMastodonMarketplace {

    enum PayoutToken{
        NativeToken,
        Xen,
        Dxn
    }

    struct Order {
        address nftContract;
        address seller;
        uint256 tokenId;
        uint256 supply;
        address payoutToken;
        uint256 price;
    }

    struct InputOrderERC721{
        address nftContract;
        uint256 tokenId;
        address payoutToken;
        uint256 price;
    }

    struct InputOrderERC1155{
        address nftContract;
        uint256 tokenId;
        uint256 supply;
        address payoutToken;
        uint256 price;
    }

    struct InputOrder{
        address nftContract;
        uint256 tokenId;
        uint256 supply;
        address payoutToken;
        uint256 price;
    }

    event List(uint256, Order);

    event Delist(uint256, Order);

    event Buy(uint256, Order);

    function listERC721(InputOrderERC721 memory order) external;

    function listERC1155(InputOrderERC1155 memory order) external;

    function delistERC721(uint256) external;

    function delistERC1155(uint256) external;

    // function _buy(uint256, PayoutToken) external payable;

    //Optional

    function batchList(InputOrder[] calldata inputOrders) external;

    function batchDelist(uint256[] calldata listIndexes) external;

    function batchBuy(uint256[] calldata listIndexes, PayoutToken[] calldata payoutTokens) external payable;

    // function changePrice() external;

}
