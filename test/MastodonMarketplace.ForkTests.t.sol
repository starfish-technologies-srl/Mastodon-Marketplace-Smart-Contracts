// pragma solidity 0.8.21;

// import "forge-std/Test.sol"; //forge standard library
// import "forge-std/console.sol";

// import {MastodonMarketplace} from "../contracts/MastodonMarketplace.sol";
// import {BurnerMock} from "../contracts/BurnerMock.sol";

// import {IMastodonMarketplace} from "../contracts/IMastodonMarketplace.sol";
// import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";
// import {IERC721} from "@openzeppelin/contracts/interfaces/IERC721.sol";

// //0xb4c79daB8f259C7Aee6E5b2Aa729821864227e84 the general deployer

// contract List is Test {
//     MastodonMarketplace mastodonMarketplace;
//     IERC20 erc20Dxn;
//     IERC20 erc20Xen;
//     IERC721 erc721Xenft;
//     BurnerMock burnerMock;

//     address dev = address(1); //=dev add
//     address buyer = address(2);
//     address seller = address(3);

//     function setUp() public {
//         //ethereum
//         erc20Dxn = IERC20(0x80f0C1c49891dcFDD40b6e0F960F84E6042bcB6F);
//         erc20Xen = IERC20(0x06450dEe7FD2Fb8E39061434BAbCFC05599a6Fb8);
//         erc721Xenft = IERC721(0x0a252663DBCc0b073063D6420a40319e438Cfa59);
//         burnerMock = new BurnerMock(erc20Xen);

//         vm.prank(dev);
//         mastodonMarketplace = new MastodonMarketplace(
//             erc20Dxn,
//             erc20Xen,
//             address(burnerMock)
//         );

//         deal(buyer, 1 ether);
//         //should buy dxn and xen from uniswap
//     }

//     function test_BuyXenft() public {
//         address input_nftContract = address(erc721Mock);
//         address input_seller = seller;
//         uint256 input_tokenId = 1;
//         uint256 input_supply = 0; //always 0 for ERC721
//         IMastodonMarketplace.PayoutToken input_payoutToken = IMastodonMarketplace
//                 .PayoutToken
//                 .NativeToken;
//         uint256 input_price = 1 ether;

//         uint8 DEV_FEE_BPS = 150; //BPS, 1.5%, 10% = 1000
//         uint8 BURN_FEE_BPS = 250;
//         uint16 MAX_BPS = 10000;
//         uint256 expected_seller = (input_price * 9600) / MAX_BPS;
//         uint256 expected_dev = (input_price * DEV_FEE_BPS) / MAX_BPS;
//         uint256 expected_burn = (input_price * BURN_FEE_BPS) / MAX_BPS;

//         IMastodonMarketplace.InputOrder[]
//             memory inputOrders = new IMastodonMarketplace.InputOrder[](1);
//         inputOrders[0] = IMastodonMarketplace.InputOrder(
//             input_nftContract,
//             input_tokenId,
//             input_supply,
//             input_payoutToken,
//             input_price
//         );

//         erc721Mock.mint(seller);
//         vm.prank(seller);
//         erc721Mock.approve(address(mastodonMarketplace), 1);
//         vm.prank(seller);
//         mastodonMarketplace.batchList(inputOrders);

//         (
//             address nftContract,
//             address seller,
//             uint256 tokenId,
//             uint256 supply,
//             IMastodonMarketplace.PayoutToken payoutToken,
//             uint256 price
//         ) = mastodonMarketplace.orders(1);

//         uint256[] memory buyIndexes = new uint256[](1);
//         buyIndexes[0] = 1;

//         vm.prank(buyer);
//         mastodonMarketplace.batchBuy{value: input_price}(buyIndexes);

//         assertEq(seller.balance, expected_seller);
//         assertEq(address(burnerMock).balance, expected_burn);
//         assertEq(dev.balance, expected_dev);
//     }

//     function test_BuyMockERC1155() public {
//         address input_nftContract = address(erc1155Mock);
//         address input_seller = seller;
//         uint256 input_tokenId = 1;
//         uint256 input_supply = 10;
//         IMastodonMarketplace.PayoutToken input_payoutToken = IMastodonMarketplace
//                 .PayoutToken
//                 .NativeToken;
//         uint256 input_price = 1 ether;

//         uint8 DEV_FEE_BPS = 150; //BPS, 1.5%, 10% = 1000
//         uint8 BURN_FEE_BPS = 250;
//         uint16 MAX_BPS = 10000;
//         uint256 expected_seller = (input_price * 9600) / MAX_BPS;
//         uint256 expected_dev = (input_price * DEV_FEE_BPS) / MAX_BPS;
//         uint256 expected_burn = (input_price * BURN_FEE_BPS) / MAX_BPS;

//         IMastodonMarketplace.InputOrder[]
//             memory inputOrders = new IMastodonMarketplace.InputOrder[](1);
//         inputOrders[0] = IMastodonMarketplace.InputOrder(
//             input_nftContract,
//             input_tokenId,
//             input_supply,
//             input_payoutToken,
//             input_price
//         );

//         erc1155Mock.mint(seller, input_tokenId, input_supply);
//         vm.prank(seller);
//         erc1155Mock.setApprovalForAll(address(mastodonMarketplace), true);
//         vm.prank(seller);
//         mastodonMarketplace.batchList(inputOrders);

//         (
//             address nftContract,
//             address seller,
//             uint256 tokenId,
//             uint256 supply,
//             IMastodonMarketplace.PayoutToken payoutToken,
//             uint256 price
//         ) = mastodonMarketplace.orders(1);

//         uint256[] memory buyIndexes = new uint256[](1);
//         buyIndexes[0] = 1;

//         vm.prank(buyer);
//         mastodonMarketplace.batchBuy{value: input_price}(buyIndexes);

//         assertEq(seller.balance, expected_seller);
//         assertEq(address(burnerMock).balance, expected_burn);
//         assertEq(dev.balance, expected_dev);
//     }

//     function test_BuyXENFT() public {}

//     function test_BuyDBXENFT() public {}

//     // function testFail_Subtract43() public { //testFail: The inverse of the test prefix - if the function does not revert, the test fails.
//     //     testNumber -= 43;
//     // }
// }

// contract ErrorsTest {
//     function arithmeticError(uint256 a) public {
//         uint256 a = a - 100;
//     }
// }
