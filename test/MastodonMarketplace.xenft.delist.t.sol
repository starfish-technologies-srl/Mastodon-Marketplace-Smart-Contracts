pragma solidity 0.8.21;

import "forge-std/Test.sol"; //forge standard library
import "forge-std/console.sol";

import {MastodonMarketplaceXENFT} from "../contracts/MastodonMarketplaceXENFT.sol";
import {IMastodonMarketplace} from "../contracts/IMastodonMarketplace.sol";

import {BurnerMock} from "../contracts/BurnerMock.sol";
import {ERC20Mock} from "../contracts/ERC20Mock.sol";
import {ERC721Mock} from "../contracts/ERC721Mock.sol";
import {XENCrypto} from "@faircrypto/xen-crypto/contracts/XENCrypto.sol";
import {XENTorrent} from "@faircrypto/XENFT/contracts/XENFT.sol";

contract XENFTDelist is Test {
    MastodonMarketplaceXENFT mastodonMarketplace;
    ERC20Mock erc20MockB;
    XENCrypto xenCrypto;
    BurnerMock burnerMock;
    XENTorrent xenft;

    address public user;
    
    function setUp() public {
        xenCrypto = new XENCrypto(); //xen
        erc20MockB = new ERC20Mock();
        burnerMock = new BurnerMock(xenCrypto);

        uint256[] memory burnRates = new uint256[](7);
        burnRates[0] = 0;
        burnRates[1] = 250000000000000000000000000;
        burnRates[2] = 500000000000000000000000000;
        burnRates[3] = 1000000000000000000000000000;
        burnRates[4] = 2000000000000000000000000000;
        burnRates[5] = 5000000000000000000000000000;
        burnRates[6] = 10000000000000000000000000000;

        uint256[] memory tokenLimits = new uint256[](7);
        tokenLimits[0] = 0;
        tokenLimits[1] = 0;
        tokenLimits[2] = 10000;
        tokenLimits[3] = 6000;
        tokenLimits[4] = 3000;
        tokenLimits[5] = 1000;
        tokenLimits[6] = 100;

        xenft = new XENTorrent(
            address(xenCrypto),
            burnRates,
            tokenLimits,
            block.number - 1,
            address(0),
            address(0)
        );

        vm.prank(vm.addr(3));
        mastodonMarketplace = new MastodonMarketplaceXENFT(
            xenCrypto,
            erc20MockB,
            address(burnerMock)
        );
    }

    function test_delistOneXENFT() public {
        user = msg.sender;
        vm.deal(user, 1 ether);

        address input_nftContract = address(xenft);
        address input_seller = user;
        uint256 input_tokenId = 10001;
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

        
        vm.startPrank(user);
        xenft.bulkClaimRank(1, 8);
        xenft.approve(address(mastodonMarketplace), 10001);
        mastodonMarketplace.batchList(inputOrders);
        vm.stopPrank();

        uint256[] memory delistIndexes = new uint256[](1);
        delistIndexes[0] = 1;

        vm.prank(user);
        mastodonMarketplace.batchDelist(delistIndexes);

        assertEq(xenft.ownerOf(10001), user);
        (
            ,
            address seller,
            ,
            ,
            ,
            ,
            
        ) = mastodonMarketplace.orders(1);

        assertEq(seller, address(0));
    }
}