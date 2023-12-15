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

    address dev = address(1); //=dev add
    address buyer = address(2);
    address seller = address(3);

    function setUp() public {
        //setUp: An optional function invoked before each test case is run.
        erc20MockA = new ERC20Mock(); //xen
        erc20MockB = new ERC20Mock();
        erc721Mock = new ERC721Mock();
        erc1155Mock = new ERC1155Mock();
        burnerMock = new BurnerMock(erc20MockA);

        vm.prank(dev);
        mastodonMarketplace = new MastodonMarketplace(
            erc20MockA,
            erc20MockB,
            address(burnerMock)
        );

        deal(buyer, 1 ether);
    }

    function test_BuyMockERC721() public {
        address input_nftContract = address(erc721Mock);
        address input_seller = seller;
        uint256 input_tokenId = 1;
        uint256 input_supply = 0; //always 0 for ERC721
        IMastodonMarketplace.PayoutToken input_payoutToken = IMastodonMarketplace
                .PayoutToken
                .NativeToken;
        uint256 input_price = 1 ether;

        uint8 DEV_FEE_BPS = 150; //BPS, 1.5%, 10% = 1000
        uint8 BURN_FEE_BPS = 250;
        uint16 MAX_BPS = 10000;
        uint256 expected_seller = (input_price * 9600) / MAX_BPS;
        uint256 expected_dev = (input_price * DEV_FEE_BPS) / MAX_BPS;
        uint256 expected_burn = (input_price * BURN_FEE_BPS) / MAX_BPS;

        IMastodonMarketplace.InputOrder[]
            memory inputOrders = new IMastodonMarketplace.InputOrder[](1);
        inputOrders[0] = IMastodonMarketplace.InputOrder(
            input_nftContract,
            input_tokenId,
            input_supply,
            input_payoutToken,
            input_price
        );

        erc721Mock.mint(seller);
        vm.prank(seller);
        erc721Mock.approve(address(mastodonMarketplace), 1);
        vm.prank(seller);
        mastodonMarketplace.batchList(inputOrders);

        (
            address nftContract,
            address seller,
            uint256 tokenId,
            uint256 supply,
            IMastodonMarketplace.PayoutToken payoutToken,
            uint256 price
        ) = mastodonMarketplace.orders(1);

        uint256[] memory buyIndexes = new uint256[](1);
        buyIndexes[0] = 1;

        vm.prank(buyer);
        mastodonMarketplace.batchBuy{value: input_price}(buyIndexes);

        assertEq(seller.balance, expected_seller);
        assertEq(address(burnerMock).balance, expected_burn);
        assertEq(dev.balance, expected_dev);
    }

    function test_BuyMockERC1155() public {
        address input_nftContract = address(erc1155Mock);
        address input_seller = seller;
        uint256 input_tokenId = 1;
        uint256 input_supply = 10;
        IMastodonMarketplace.PayoutToken input_payoutToken = IMastodonMarketplace
                .PayoutToken
                .NativeToken;
        uint256 input_price = 1 ether;

        uint8 DEV_FEE_BPS = 150; //BPS, 1.5%, 10% = 1000
        uint8 BURN_FEE_BPS = 250;
        uint16 MAX_BPS = 10000;
        uint256 expected_seller = (input_price * 9600) / MAX_BPS;
        uint256 expected_dev = (input_price * DEV_FEE_BPS) / MAX_BPS;
        uint256 expected_burn = (input_price * BURN_FEE_BPS) / MAX_BPS;

        IMastodonMarketplace.InputOrder[]
            memory inputOrders = new IMastodonMarketplace.InputOrder[](1);
        inputOrders[0] = IMastodonMarketplace.InputOrder(
            input_nftContract,
            input_tokenId,
            input_supply,
            input_payoutToken,
            input_price
        );

        erc1155Mock.mint(seller, input_tokenId, input_supply);
        vm.prank(seller);
        erc1155Mock.setApprovalForAll(address(mastodonMarketplace), true);
        vm.prank(seller);
        mastodonMarketplace.batchList(inputOrders);

        (
            address nftContract,
            address seller,
            uint256 tokenId,
            uint256 supply,
            IMastodonMarketplace.PayoutToken payoutToken,
            uint256 price
        ) = mastodonMarketplace.orders(1);

        uint256[] memory buyIndexes = new uint256[](1);
        buyIndexes[0] = 1;

        vm.prank(buyer);
        mastodonMarketplace.batchBuy{value: input_price}(buyIndexes);

        assertEq(seller.balance, expected_seller);
        assertEq(address(burnerMock).balance, expected_burn);
        assertEq(dev.balance, expected_dev);
    }

    function test_BuyXENFT() public {}

    function test_BuyDBXENFT() public {}

    // function testFail_Subtract43() public { //testFail: The inverse of the test prefix - if the function does not revert, the test fails.
    //     testNumber -= 43;
    // }
}

contract ErrorsTest {
    function arithmeticError(uint256 a) public {
        uint256 a = a - 100;
    }
}
