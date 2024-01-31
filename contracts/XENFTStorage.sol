pragma solidity ^0.8.19;

import {IERC721} from "@openzeppelin/contracts/interfaces/IERC721.sol";
import {IERC721Receiver} from "@openzeppelin/contracts/interfaces/IERC721Receiver.sol";

contract XENFTStorage {
    address public immutable factory;

    constructor() {
        factory = msg.sender;
    }

    function transferBack(
        address xenft,
        address destination,
        uint256 tokenId
    ) external {
        require(msg.sender == factory, "Caller is not factory");

        IERC721(xenft).safeTransferFrom(address(this), destination, tokenId);
    }
}
