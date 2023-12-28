// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;
import "forge-std/Test.sol";
import "../contracts/MastodonMarketplace.sol";
import "../contracts/ERC20Mock.sol";
import "../contracts/ERC721Mock.sol";

contract BuyTest is Test {
    MastodonMarketplace public market;
    ERC20Mock public xen;
    ERC20Mock public dxn;
    ERC721Mock public erc721;
    address public owner = vm.addr(999);
    address public burn = vm.addr(990);
    address public user1 = vm.addr(1);
    address public user2 = vm.addr(2);

    function setUp() public {
        xen = new ERC20Mock();
        dxn = new ERC20Mock();
        erc721 = new ERC721Mock();
        vm.startPrank(owner);
        market = new MastodonMarketplace(xen, dxn, burn);
        vm.stopPrank();
    }

    // TODO: Verify why the test passes before adding SafeERC and also after adding it.
    function testBuywithERC20Token() public {
        vm.startPrank(user1);
        erc721.setApprovalForAll(address(market), true);

        erc721.mint(user1);
        IMastodonMarketplace.InputOrder[] memory inputOrders = new IMastodonMarketplace.InputOrder[](2);
        inputOrders[0].nftContract = address(erc721);
        inputOrders[0].tokenId = 1; //
        inputOrders[0].supply = 0;
        inputOrders[0].payoutToken = IMastodonMarketplace.PayoutToken.Xen;
        inputOrders[0].price = 1 ether;
        erc721.mint(user1);
        inputOrders[1].nftContract = address(erc721);
        inputOrders[1].tokenId = 2; //
        inputOrders[1].supply = 0;
        inputOrders[1].payoutToken = IMastodonMarketplace.PayoutToken.Dxn;
        inputOrders[1].price = 1 ether;

        market.batchList(inputOrders);
        vm.stopPrank();
        vm.startPrank(user2);
        deal(address(xen), user2, 1 ether);
        deal(address(dxn), user2, 1 ether);
        xen.approve(address(market), 100 ether);
        dxn.approve(address(market), 100 ether);
        uint256[] memory lists = new uint256[](2);
        lists[0] = 1;
        lists[1] = 2;
        vm.expectRevert();
        market.batchBuy(lists);
        vm.stopPrank();
    }
}
