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

    struct InputOrder{
        address nftContract;
        uint256 tokenId;
        uint256 supply;
        address payoutToken;
        uint256 price;
    }

    struct Order {
        address nftContract;
        address seller;
        uint256 tokenId;
        uint256 supply;
        address payoutToken;
        uint256 price;
    }

    event List(uint256, Order);

    event Delist(uint256, Order);

    event Buy(uint256, Order);

    function batchList(InputOrder[] calldata inputOrders) external;

    function batchDelist(uint256[] calldata listIndexes) external;

    function batchBuy(uint256[] calldata listIndexes, PayoutToken[] calldata payoutTokens) external payable;

    // function changePrice() external;

}
