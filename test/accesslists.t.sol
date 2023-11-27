pragma solidity 0.8.21;

import "forge-std/Test.sol"; //forge standard library
import "forge-std/console.sol";

import {MastodonMarketplace} from '../contracts/MastodonMarketplace.sol';

import {BurnerMock} from '../contracts/BurnerMock.sol';
import {ERC20Mock} from '../contracts/ERC20Mock.sol';
import {ERC721Mock} from '../contracts/ERC721Mock.sol';
import {ERC1155Mock} from '../contracts/ERC1155Mock.sol';

//0xb4c79daB8f259C7Aee6E5b2Aa729821864227e84 the general deployer

contract ContractBTest is Test {
    MastodonMarketplace mastodonMarketplace;
    ERC20Mock erc20MockA;
    ERC20Mock erc20MockB;
    ERC721Mock erc721Mock;
    ERC1155Mock erc1155Mock;
    BurnerMock burnerMock;

    function setUp() public { //setUp: An optional function invoked before each test case is run.
        erc20MockA = new ERC20Mock(); //xen
        erc20MockB = new ERC20Mock();
        erc721Mock = new ERC721Mock();
        erc1155Mock = new ERC1155Mock();
        burnerMock = new BurnerMock(erc20MockA);

        mastodonMarketplace = new MastodonMarketplace(erc20MockA, erc20MockB, address(burnerMock));
    }

    function test_NumberIs42() public { //test: Functions prefixed with test are run as a test case.

        // assertEq(testNumber, 42);
    }

    // function testFail_Subtract43() public { //testFail: The inverse of the test prefix - if the function does not revert, the test fails.
    //     testNumber -= 43;
    // }
    
}

contract ErrorsTest {
    function arithmeticError(uint256 a) public {
        uint256 a = a - 100;
    }
}