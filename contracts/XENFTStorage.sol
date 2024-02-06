pragma solidity ^0.8.19;

import {IERC721} from "@openzeppelin/contracts/interfaces/IERC721.sol";
import {IERC721Receiver} from "@openzeppelin/contracts/interfaces/IERC721Receiver.sol";

contract XENFTStorage is IERC721Receiver{
    address public immutable factory;

    constructor() {
        factory = msg.sender;
    }

    function transferBack(
        address xenft,
        address destination,
        uint256 tokenId
    ) external {
        require(msg.sender == factory, "XENFTStorage: Caller is not factory");

        IERC721(xenft).safeTransferFrom(address(this), destination, tokenId);
    }

    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4) {
        return (this.onERC721Received.selector);
    }
}
