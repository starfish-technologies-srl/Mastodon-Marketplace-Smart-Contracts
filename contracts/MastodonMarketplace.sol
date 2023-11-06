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

    uint8 constant DEV_FEE_BPS = 250; //BPS, 2.5%, 10% = 1000
    
    uint8 constant BURN_FEE_BPS = 150;

    uint16 constant MAX_BPS = 10000;

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
        emit Delist(globalIndex, orders[globalIndex]);
    }

    function buy(uint256 listIndex, PayoutToken token) external payable{
        uint256 toSeller = orders[listIndex].price * 9600 / MAX_BPS;
        uint256 toDev = orders[listIndex].price * DEV_FEE_BPS / MAX_BPS;
        uint256 toBurn = orders[listIndex].price * BURN_FEE_BPS / MAX_BPS;

        if(token == PayoutToken.NativeToken){
            require(msg.value == orders[listIndex].price, "invalid price");

            //TODO: buy and burn from Uniswap

            (bool success, ) = orders[listIndex].seller.call{value: toSeller}("");
            require(success, "Payment failed.");
        }else if(token == PayoutToken.Xen){
            xen.transfer(orders[listIndex].seller, toSeller);
            //transfer to dev
            //direct burn
        }else {
            dxn.transfer(orders[listIndex].seller, toSeller);
            //transfer to dev
            //direct burn
        }

        IERC721(orders[listIndex].nftContract).safeTransferFrom(address(this), msg.sender, orders[listIndex].tokenId);

        delete(orders[listIndex]);
        emit Buy(globalIndex, orders[globalIndex]);
    }

}
