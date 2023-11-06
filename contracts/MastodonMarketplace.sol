// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import "hardhat/console.sol";

import {IMastodonMarketplace} from './IMastodonMarketplace.sol';
import {IERC20} from '@openzeppelin/contracts/interfaces/IERC20.sol';
import {IERC721} from '@openzeppelin/contracts/interfaces/IERC721.sol';

contract MastodonMarketplace is IMastodonMarketplace {

    uint256 globalIndex;

    mapping (uint256 listIndex => Order order) orders;

    IERC20 immutable xen;

    IERC20 immutable dxn;

    constructor(IERC20 _xen, IERC20 _dxn){
        xen = _xen;
        dxn = _dxn;
    }

    function list(InputOrder memory inputOrder) external{
        globalIndex++;

        orders[globalIndex].nftContract = inputOrder.nftContract;
        orders[globalIndex].tokenId = inputOrder.tokenId;
        orders[globalIndex].payoutToken = inputOrder.payoutToken;
        orders[globalIndex].price = inputOrder.price;
        orders[globalIndex].seller = msg.sender;

        IERC721(inputOrder.nftContract).safeTransferFrom(msg.sender, address(this), inputOrder.tokenId);

        emit List(globalIndex, orders[globalIndex]);
    }

    function delist(uint256 listIndex) external{
        require(orders[listIndex].seller == msg.sender, "not owner");

        IERC721(orders[listIndex].nftContract).safeTransferFrom(address(this), msg.sender, orders[listIndex].tokenId);

        delete(orders[listIndex]);
        emit Delist();
    }

    function buy(uint256 listIndex, PayoutToken token) external payable{
        if(token == PayoutToken.NativeToken){
            require(msg.value == orders[listIndex].price, "invalid price");
            (bool success, ) = orders[listIndex].seller.call{value: orders[listIndex].price}("");
            require(success, "Payment failed.");
        }else if(token == PayoutToken.Xen){
            xen.transfer(orders[listIndex].seller, orders[listIndex].price);
        }else dxn.transfer(orders[listIndex].seller, orders[listIndex].price);

        IERC721(orders[listIndex].nftContract).safeTransferFrom(address(this), msg.sender, orders[listIndex].tokenId);

        delete(orders[listIndex]);
        emit Buy();
    }

}
