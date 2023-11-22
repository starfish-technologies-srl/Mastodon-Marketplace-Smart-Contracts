// // SPDX-License-Identifier: MIT

// /*


// ██╗  ██╗███████╗███╗   ██╗    ██████╗ ██╗   ██╗██████╗ ███╗   ██╗
// ╚██╗██╔╝██╔════╝████╗  ██║    ██╔══██╗██║   ██║██╔══██╗████╗  ██║
//  ╚███╔╝ █████╗  ██╔██╗ ██║    ██████╔╝██║   ██║██████╔╝██╔██╗ ██║
//  ██╔██╗ ██╔══╝  ██║╚██╗██║    ██╔══██╗██║   ██║██╔══██╗██║╚██╗██║
// ██╔╝ ██╗███████╗██║ ╚████║    ██████╔╝╚██████╔╝██║  ██║██║ ╚████║
// ╚═╝  ╚═╝╚══════╝╚═╝  ╚═══╝    ╚═════╝  ╚═════╝ ╚═╝  ╚═╝╚═╝  ╚═══╝
                                                                 

// */

// pragma solidity ^0.8.17;
// import "@uniswap/v3-periphery/contracts/libraries/OracleLibrary.sol";
// import "./interfaces/IWETH9Minimal.sol";
// import "./interfaces/IERC20Minimal.sol";
// import "./interfaces/ISwapRouterMinimal.sol";

// interface IPlayerNameRegistryBurn {
//     function getPlayerNames(address playerAddress) external view returns (string[] memory);
// }

// contract xenBurn {
//     address public immutable BURN_ADDRESS = 0x000000000000000000000000000000000000dEaD;
//     address public DXN;
//     address public DXN_WETH9_Pool = 0x7F808fD904FFA3eb6A6F259e6965Fb1466A05372;
//     address public WETH9 = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
//     mapping(address => uint256) public lastCall;
//     mapping(address => uint256) public callCount;
//     uint256 public totalCount;
//     uint256 public totalXenBurned;
//     uint256 public totalEthBurned;
//     address private swapRouter = 0x68b3465833fb72A70ecDF485E0e4C7bD8665Fc45;
//     IPlayerNameRegistryBurn private playerNameRegistry;

//     constructor( address _DXN, address _playerNameRegistry) {
//         DXN = _DXN;
//         playerNameRegistry = IPlayerNameRegistryBurn(_playerNameRegistry);
//     }

//     event TokenBurned(address indexed user, uint256 amount, string playerName);

//     // Modifier to allow only human users to perform certain actions
//     modifier isHuman() {
//         require(msg.sender == tx.origin, "Only human users can perform this action");
//         _;
//     }

//     // Modifier to enforce restrictions on the frequency of calls
//     modifier gatekeeping() {
//         require(
//             (lastCall[msg.sender] + 1 days) <= block.timestamp || (callCount[msg.sender] + 5) <= totalCount,
//             "Function can only be called once per 24 hours, or 5 times within the 24-hour period by different users"
//         );
//         _;
//     }

//     // Function to burn tokens by swapping ETH for the token
//     function burnDXN() public isHuman gatekeeping {
//         require(address(this).balance > 2, "No ETH available");

//         address player = msg.sender;

//         // Pull player's name from game contract
//         string[] memory names = playerNameRegistry.getPlayerNames(player);
//         require(names.length > 0, "User must have at least 1 name registered");

//         // Amount to use for swap (98% of the contract's ETH balance)
//         uint256 amountETH = address(this).balance * 98 / 100;
//         totalEthBurned += amountETH;

//         // Get current token price from PriceOracle
//         uint256 amountOutExpected = _getQuote(uint128(amountETH));

//         // // Calculate the minimum amount of tokens to purchase. Slippage set to 10% max
//         uint256 minTokenAmount = (amountOutExpected * 90) / 100;
//         require(minTokenAmount > 0, "Min. token amount can't be zero");

//         _swap(minTokenAmount, amountETH);

//         // // Update the call count and last call timestamp for the user
//         totalCount++;
//         callCount[player] = totalCount;
//         lastCall[player] = block.timestamp;

//         // Transfer 1% of the ETH balance to the user who called the function
//         amountETH = address(this).balance / 2;
//         address payable senderPayable = payable(msg.sender);
//         (bool success,) = senderPayable.call{value: amountETH}("");
//         require(success, "Transfer failed.");   
//     }

//     // Function to calculate the expected amount of tokens to be burned based on the contract's ETH balance and token price
//     function calculateExpectedBurnAmount() public view returns (uint256 amountOutExpected) {
//         // Check if the contract has ETH balance
//         if (address(this).balance == 0) {
//             return 0;
//         }

//         // Calculate the amount of ETH to be used for the swap (98% of the contract's ETH balance)
//         uint256 amountETH = address(this).balance;

//         // Get current token price from PriceOracle
//         amountOutExpected = _getQuote(uint128(amountETH));
//     }

//     // Function to deposit ETH into the contract
//     function deposit() public payable returns (bool) {
//         require(msg.value > 0, "No ETH received");
//         return true;
//     }

//     // Fallback function to receive ETH
//     receive() external payable {}

//     function _swap(uint256 amountOutMinimum, uint256 amountIn) private {
//         ISwapRouterMinimal.ExactInputSingleParams memory params =
//             ISwapRouterMinimal.ExactInputSingleParams({
//                 tokenIn: WETH9,
//                 tokenOut: DXN,
//                 fee: 10000,
//                 recipient: BURN_ADDRESS,
//                 amountIn: amountIn,
//                 amountOutMinimum: amountOutMinimum,
//                 sqrtPriceLimitX96: 0
//             });

//         // The call to `exactInputSingle` executes the swap.
//         ISwapRouterMinimal(swapRouter).exactInputSingle{value: amountIn}(params);
//     }

//     function _getQuote(uint128 amountIn) private view returns(uint256 amountOut) {
//         (int24 tick, ) = OracleLibrary.consult(DXN_WETH9_Pool, 1);
//         amountOut = OracleLibrary.getQuoteAtTick(tick, amountIn, WETH9, DXN);
//     }
// }