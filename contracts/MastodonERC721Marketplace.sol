// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

/**
 * Allows the exchange (swapping) of ERC-721 tokens for fixed amounts of ERC-20 tokens requested by the seller. 
 * The address of the ERC-20 token is configurable.
 * The marketplace sale fee is split in equal amounts and sent to the owner and developer addresses.
 * Contract addresses for supported ERC-721 tokens must be whitelisted.
 */
contract TipsyERC721Marketplace is Ownable, ReentrancyGuard {
    using SafeMath for uint256;
    using Address for address;

    /**
     * Represents a listing order that is created when a token is 
     * listed for sale at a price desired by the owner.
     */
    struct Order {
        // NFT token owner
        address seller;
        // Token id
        uint256 tokenId;
        // NFT registry address
        address nftContract;
        // Price (in wei) for the listed NFT token
        uint256 price;
        // Index in orderKeyList
        uint256 listIndex;
    }

    /**
     * Composite identifier for one Order instance.
     */
    struct OrderKey {
        // NFT registry address
        address nftContract;
        // Token id
        uint256 tokenId;
    }

    // Maps a Order instance (value) to a NFT token (key). 
    mapping(address => mapping(uint256 => Order)) public orderByAssetId;

    // Current orders stored in array ready for retrieval.
    OrderKey[] internal orderKeyList;

    // Addresses of NFTs that are allowed for trading.
    mapping(address => bool) public whitelist;

    // Base token for swaping
    IERC20 public erc20;

    // Developer address
    address public dev;

    // The interface ID for the ERC721 contract
    bytes4 public constant ERC721_Interface = bytes4(0x80ac58cd);

    // Sale fee in basis points (bps). Default value corresponds to 10%. 1bps = 0.01%.
    uint16 public saleFeePerc = 1000;

    /**
     * Initializes the contract setting the initial base token, owner and dev addresses.
     */
    constructor(
        address _erc20,
        address _owner,
        address _dev
    ) {
        transferOwnership(_owner);
        erc20 = IERC20(_erc20);
        dev = _dev;
    }

    /**
     * Modifier checks that a given address is a NFT contract whitelisted for trading.
     */
    modifier onlyWhitelisted(address nftAddress) {
        require(
            whitelist[nftAddress],
            "TipsyERC721Marketplace: address not whitelisted"
        );
        _;
    }

    /**
     * Creates a sell order of a token at a given price.
     *
     * Access: all accounts.
     *
     * @param nftContract the address of the ERC-721 contract to be listed.
     * @param tokenId token identifier.
     * @param price the proposed listing price in base ERC-20 token.
     */
    function sell (
        address nftContract,
        uint256 tokenId,
        uint256 price
    ) public  onlyWhitelisted(nftContract) nonReentrant() {
        require(price >= 20000, "TipsyERC721Marketplace: the price must be at least 20000 wei");
        require(
            price < erc20.totalSupply(),
            "TipsyERC721Marketplace: the price must be lower than total supply"
        );
        IERC721 nftRegistry = IERC721(nftContract);
        address assetOwner = nftRegistry.ownerOf(tokenId);

        require(
            msg.sender == assetOwner,
            "TipsyERC721Marketplace: only the owner of the tokenId can sell it"
        );
        require(
            nftRegistry.getApproved(tokenId) == address(this) ||
                nftRegistry.isApprovedForAll(assetOwner, address(this)),
            "TipsyERC721Marketplace: the contract is not authorized to manage the asset"
        );

        Order storage order = orderByAssetId[nftContract][tokenId];
        order.nftContract = nftContract;
        order.seller = msg.sender;
        order.price = price;
        order.tokenId = tokenId;

        if (order.listIndex == 0) {
            orderKeyList.push(
                OrderKey({nftContract: nftContract, tokenId: tokenId})
            );
            order.listIndex = orderKeyList.length;
        }

        emit TokenListed(tokenId, assetOwner, nftContract, price);
    }

    /**
     * Removes the order corresponding to the given NFT address and identifier.
     *
     * Access: only the account that holds the token.
     *
     * @param nftContract the address of the ERC-721 contract to be listed.
     * @param tokenId token identifier.
     */
    function cancelListing(address nftContract, uint256 tokenId) public  {
       IERC721 nftRegistry = IERC721(nftContract);
        require(
            nftRegistry.ownerOf(tokenId) == msg.sender,
            "TipsyERC721Marketplace: sender must be the holder of the token"
        );
        removeOrder(nftContract, tokenId);

        Order memory order = orderByAssetId[nftContract][tokenId];

        emit TokenCancelled(tokenId, order.seller, nftContract);
    }

    /**
     * Transfers the NFT token to the sender’s account and the ERC20 amount to the seller’s account.
     * Splits the fee equally and transfers the corresponding amounts to the owner and dev addresses.
     *
     * Access: all accounts.
     *
     * @dev exception when nftContract address is not whitelisted.
     * @dev exception when order is not found (nftContract, tokenId)
     * @dev exception when sender does not have enough of erc20 balance
     * @dev exception when seller does not own tokenId
     * @dev order is deleted in case of transfer errors
     * @param nftContract the address of the ERC-721 contract.
     * @param tokenId identifier of the token to be listed.
     */
    function buy(address nftContract, uint256 tokenId)
        public
        
        onlyWhitelisted(nftContract)
        nonReentrant()
        returns (Order memory)
    {
        Order memory order = orderByAssetId[nftContract][tokenId];
        require(order.listIndex != 0, "Order does not exist");
        address seller = order.seller;
        address sender = msg.sender;
        require(seller != address(0), "TipsyERC721Marketplace: invalid address");
        require(seller != sender, "TipsyERC721Marketplace: unauthorized user");

        IERC721 nftRegistry = IERC721(nftContract);
        require(
            seller == nftRegistry.ownerOf(order.tokenId),
            "TipsyERC721Marketplace: the seller is no longer the owner of the NFT token"
        );

        uint256 price = order.price;
        if (saleFeePerc > 0) {
            require(
                erc20.transferFrom(
                    sender,
                    seller,
                    (price.sub(((price.mul(saleFeePerc))) / 10000))
                ),
                "TipsyERC721Marketplace: transfering the sale amount failed (1)"
            );
            uint256 halfFee = price.mul(saleFeePerc) / 2 / 10000;
            require(
                erc20.transferFrom(sender, owner(), halfFee),
                "TipsyERC721Marketplace: transfering the sale fee to the owner failed"
            );
            require(
                erc20.transferFrom(sender, dev, halfFee),
                "TipsyERC721Marketplace: transfering the sale fee to the dev failed"
            );
        } else {
            require(
                erc20.transferFrom(sender, seller, price),
                "TipsyERC721Marketplace: transfering the sale amount failed (2)"
            );
        }
        removeOrder(nftContract, tokenId);
        nftRegistry.safeTransferFrom(seller, sender, tokenId);
        emit TokenSold(order, sender);
        return order;
    }

    /**
     * Internal helper to remove one sell order.
     * 
     * @param nftContract the address of the ERC-721 contract to be listed.
     * @param tokenId token identifier.
     */
    function removeOrder(address nftContract, uint256 tokenId) internal {
        Order storage order = orderByAssetId[nftContract][tokenId];

        require(order.listIndex != 0, "TipsyERC721Marketplace: order does not exist");
        require(order.listIndex <= orderKeyList.length, "TipsyERC721Marketplace: invalid index value");

        // Moves the last array element into the vacated key slot.
        uint256 keyListIndex = order.listIndex.sub(1);
        uint256 keyListLastIndex = orderKeyList.length.sub(1);
        OrderKey memory orderKey = orderKeyList[keyListLastIndex];
        orderByAssetId[orderKey.nftContract][orderKey.tokenId]
            .listIndex = keyListIndex.add(1);
        orderKeyList[keyListIndex] = orderKeyList[keyListLastIndex];
        orderKeyList.pop();
        delete orderByAssetId[nftContract][tokenId];
    }

    /**
     * Updates the marketplace fee.
     *
     * Access: only the contract owner account.
     *
     * @param newsaleFeePerc percentage fee in basis points (100 basis points correspond to 1%).
     */
    function setSaleFee(uint16 newsaleFeePerc) public onlyOwner {
        require(
            newsaleFeePerc <= 10000,
            "TipsyERC721Marketplace: Fee percentage greater than 10000"
        );
        saleFeePerc = newsaleFeePerc;
    }

    /**
     * Changes the address to which the developer fee is transferred.
     *
     * Access: only the developer account.
     *
     * @param newDev new developer address value.
     */
    function changeDevAddress(address newDev) public {
        require(msg.sender == dev, "TipsyERC721Marketplace: only the dev can change the dev address");
        require(
            newDev != address(0),
            "TipsyERC721Marketplace: dev address cannot be the zero address"
        );
        dev = newDev;
    }

    /**
     * Adds an NFT contract address to the whitelist.
     *
     * Access: only the contract owner account.
     *
     * @param whitelistAddress NFT contract to be whitelisted.
     */
    function addWhitelistAddress(address whitelistAddress) public onlyOwner {
       _requireERC721(whitelistAddress);
        whitelist[whitelistAddress] = true;
    }

    /**
     * Removes an NFT contract address from the whitelist.
     *
     * Access: only the contract owner account.
     *
     * @param whitelistAddress NFT contract to be removed from the whitelist.
     */
    function removeWhitelistAddress(address whitelistAddress) public onlyOwner {
        whitelist[whitelistAddress] = false;
    }

    /**
     * Pauses the ability to call the sell function.
     *
     * Access: only the contract owner account.
     */
    function pauseListings() public onlyOwner {
        _pause();
    }

    /**
     * Resumes the ability to call the sell function.
     *
     * Access: only the contract owner account.
     */
    function unpauseListings() public onlyOwner {
        _unpause();
    }

    /**
     * Returns a list containing all the order keys.
     *
     * Access: all acounts
     */
    function getOrderKeys() public view returns (OrderKey[] memory) {
        return orderKeyList;
    }

    /**
     * Returns the size of the order list.
     *
     * Access: all acounts
     */
    function orderListSize() public view returns (uint256) {
        return orderKeyList.length;
    }

    /**
     * Returns whether or not a certain token is listed.
     *
     * Access: all acounts
     *
     * @param nftContract NFT contract address of the token.
     * @param tokenId token identifier.
     */
    function orderListContains(address nftContract, uint256 tokenId)
        public
        view
        returns (bool)
    {
        return orderByAssetId[nftContract][tokenId].listIndex > 0;
    }

    /**
     * Returns an order from the order list based on an index
     *
     * Access: all acounts
     *
     * @param _index index in order list.
     */
    function getOrderByIndex(uint256 _index) public view returns (Order memory) {
        require(_index < orderKeyList.length, "_index must be < orderKeyList.length");
        OrderKey memory orderKey = orderKeyList[_index];
        return orderByAssetId[orderKey.nftContract][orderKey.tokenId];
    }

    /**
     * Returns an array containing all orders.  
     *
     * Access: all acounts
     * 
     * @param start the start index (0-based)
     * @param end the end index (0-based)
     */
    function getOrders(uint256 start, uint256 end) public view returns (Order[] memory) {
        require(end >= start, "TipsyERC721Marketplace: end must be >= start");
        require(end < orderKeyList.length, "end must be < orderKeyList.length");

        uint256 sliceLength = SafeMath.add(SafeMath.sub(end, start), 1);
        Order[] memory slice = new Order[](sliceLength);

        for (uint256 arrIdx = 0; arrIdx < sliceLength; arrIdx++) {
            OrderKey memory currentOrderKey = orderKeyList[arrIdx];
            slice[arrIdx] = orderByAssetId[currentOrderKey.nftContract][currentOrderKey.tokenId];
        }
        return slice;
    }

    /**
     * Utility method to check that an address is a ERC721 contract.
     */
    function _requireERC721(address nftContract) internal view {
        require(
            nftContract.isContract(),
            "TipsyERC721Marketplace: address is not a contract"
        );
       IERC721 nftRegistry = IERC721(nftContract);
        require(
            nftRegistry.supportsInterface(ERC721_Interface),
            "TipsyERC721Marketplace: invalid ERC721 implementation"
        );
    }

    /**
     * Event for one token listing.
     */
    event TokenListed(
        uint256 indexed assetId,
        address indexed seller,
        address nftAddress,
        uint256 priceInWei
    );

    /**
     * Event for one token sell.
     */
    event TokenSold(Order order, address newOwner);

    /**
     * Event for cancelling one token listing.
     */
    event TokenCancelled(
        uint256 indexed assetId,
        address indexed seller,
        address nftAddress
    );
}