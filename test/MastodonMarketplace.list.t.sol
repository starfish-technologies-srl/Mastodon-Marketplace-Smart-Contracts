pragma solidity 0.8.21;

import "forge-std/Test.sol"; //forge standard library
import "forge-std/console.sol";

import {MastodonMarketplace} from "../contracts/MastodonMarketplace.sol";

import {BurnerMock} from "../contracts/BurnerMock.sol";
import {ERC20Mock} from "../contracts/ERC20Mock.sol";
import {ERC721Mock} from "../contracts/ERC721Mock.sol";
import {ERC1155Mock} from "../contracts/ERC1155Mock.sol";

import {IMastodonMarketplace} from "../contracts/IMastodonMarketplace.sol";

//0xb4c79daB8f259C7Aee6E5b2Aa729821864227e84 the general deployer

contract List is Test {
    MastodonMarketplace mastodonMarketplace;
    ERC20Mock erc20MockA;
    ERC20Mock erc20MockB;
    ERC721Mock erc721Mock;
    ERC1155Mock erc1155Mock;
    BurnerMock burnerMock;

    address add1 = address(1);

    function setUp() public {
        //setUp: An optional function invoked before each test case is run.
        erc20MockA = new ERC20Mock(); //xen
        erc20MockB = new ERC20Mock();
        erc721Mock = new ERC721Mock();
        erc1155Mock = new ERC1155Mock();
        burnerMock = new BurnerMock(erc20MockA);

        mastodonMarketplace = new MastodonMarketplace(
            erc20MockA,
            erc20MockB,
            address(burnerMock)
        );
    }

    function test_ListMockERC721() public {
        address input_nftContract = address(erc721Mock);
        address input_seller = add1;
        uint256 input_tokenId = 1;
        uint256 input_supply = 0; //always 0 for ERC721
        IMastodonMarketplace.PayoutToken input_payoutToken = IMastodonMarketplace.PayoutToken.NativeToken;
        uint256 input_price = 1;
        IMastodonMarketplace.AssetClass expected_assetClass = IMastodonMarketplace.AssetClass.ERC721;

        IMastodonMarketplace.InputOrder[]
            memory inputOrders = new IMastodonMarketplace.InputOrder[](1);
        inputOrders[0] = IMastodonMarketplace.InputOrder(
            input_nftContract,
            input_tokenId,
            input_supply,
            input_payoutToken,
            input_price
        );

        erc721Mock.mint(add1);
        vm.prank(add1);
        erc721Mock.approve(address(mastodonMarketplace), 1);
        vm.prank(add1);
        mastodonMarketplace.batchList(inputOrders);

        //Verify
        (
            address nftContract,
            address seller,
            uint256 tokenId,
            uint256 supply,
            IMastodonMarketplace.PayoutToken payoutToken,
            uint256 price,
            IMastodonMarketplace.AssetClass assetClass
        ) = mastodonMarketplace.orders(1);

        assertEq(nftContract, address(erc721Mock));
        assertEq(seller, input_seller);
        assertEq(tokenId, input_tokenId);
        assertEq(supply, input_supply);
        assertEq(uint8(payoutToken), uint8(input_payoutToken));
        assertEq(price, input_price);
        assertEq(uint8(assetClass), uint8(expected_assetClass));
    }

    function test_ListMockERC1155() public {
        address input_nftContract = address(erc1155Mock);
        address input_seller = add1;
        uint256 input_tokenId = 1;
        uint256 input_supply = 10;
        IMastodonMarketplace.PayoutToken input_payoutToken = IMastodonMarketplace.PayoutToken.NativeToken;
        uint256 input_price = 1;
        IMastodonMarketplace.AssetClass expected_assetClass = IMastodonMarketplace.AssetClass.ERC1155;

        IMastodonMarketplace.InputOrder[]
            memory inputOrders = new IMastodonMarketplace.InputOrder[](1);
        inputOrders[0] = IMastodonMarketplace.InputOrder(
            input_nftContract,
            input_tokenId,
            input_supply,
            input_payoutToken,
            input_price
        );

        erc1155Mock.mint(add1, input_tokenId, input_supply);
        vm.prank(add1);
        erc1155Mock.setApprovalForAll(address(mastodonMarketplace), true);
        vm.prank(add1);
        mastodonMarketplace.batchList(inputOrders);

        (
            address nftContract,
            address seller,
            uint256 tokenId,
            uint256 supply,
            IMastodonMarketplace.PayoutToken payoutToken,
            uint256 price,
            IMastodonMarketplace.AssetClass assetClass
        ) = mastodonMarketplace.orders(1);

        assertEq(nftContract, address(erc1155Mock));
        assertEq(seller, input_seller);
        assertEq(tokenId, input_tokenId);
        assertEq(supply, input_supply);
        assertEq(uint8(payoutToken), uint8(input_payoutToken));
        assertEq(price, input_price);
        assertEq(uint8(assetClass), uint8(expected_assetClass));
    }

}
