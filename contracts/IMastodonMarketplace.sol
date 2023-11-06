// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import {IERC721} from '@openzeppelin/contracts/interfaces/IERC721.sol';

interface IMastodonMarketplace {

    enum PayoutToken{
        NativeToken,
        Xen,
        Dxn
    }

    struct Order {
        IERC721 nftContract;
        address seller;
        uint256 tokenId;
        address payoutToken;
        uint256 price;
    }

    struct InputOrder{
        IERC721 nftContract;
        uint256 tokenId;
        address payoutToken;
        uint256 price;
    }

    event List(uint256, Order);

    event Delist();

    event Buy();

    function list(InputOrder memory order) external;

    function delist(uint256) external;

    function buy(uint256, PayoutToken) external payable;

    //Optional

    // function batchList() external;

    // function batchDelist() external;

    // function batchBuy() external;

    // function changePrice() external;

}
