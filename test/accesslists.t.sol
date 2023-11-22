pragma solidity 0.8.21;

import "forge-std/Test.sol";
import "forge-std/console.sol";

contract ContractBTest is Test {
    uint256 testNumber;

    function setUp() public {
        testNumber = 42;
    }

    function test_NumberIs42() public {
        assertEq(testNumber, 42);
    }

    function testFail_Subtract43() public {
        testNumber -= 43;
    }
    
}

contract ErrorsTest {
    function arithmeticError(uint256 a) public {
        uint256 a = a - 100;
    }
}