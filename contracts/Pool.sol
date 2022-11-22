pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";

import "./lib/VRFConsumerBaseV2Upgradeable.sol";

/// @title Minting NFT
/// @author Khang Trinh.
contract Pool is
    Initializable,
    VRFConsumerBaseV2Upgradeable,
    ERC721Upgradeable
{
    using Counters for Counters.Counter;

    // Save request mint NFT of user
    struct RequestMintData {
        address user;
        uint256 priceNft;
    }

    // Result of mint request, can be fail or success
    event MintNFTResult(
        address indexed to,
        bool result,
        uint256 random,
        uint256 tokenId,
        uint256 requestId
    );

    /* Owner of contract */
    address public _owner;
    /* Price of NFT */
    uint256 public _priceNft;
    /* Default URI of NFT */
    string private _contractURI;

    /* Rate of successfully mint nft */
    uint256 DOMINATOR;
    uint256 RATE_TO_MINT_NFT;

    /* Refund rate */
    uint256 REFUND_RATE;

    /* Chainlink coordinator */
    VRFCoordinatorV2Interface COORDINATOR;

    /* Chainlink config */
    uint64 s_subscriptionId;
    bytes32 s_keyHash;
    uint32 callbackGasLimit;
    uint16 requestConfirmations;
    uint32 numWords;

    /* Optional mapping for token URIs*/
    mapping(uint256 => string) private _tokenURIs;
    mapping(uint256 => RequestMintData) private _requests;
    mapping(uint256 => uint256) private _tokenMintedPrice;

    Counters.Counter private _currentTokenID;
    Counters.Counter public _totalNft;

    function initialize(
        address owner_,
        uint64 subscriptionId_,
        address vrfCoordinator_,
        bytes32 s_keyHash_
    ) public initializer {
        __ERC721_init("BLOCK", "BLK");
        __VRF_initialize(vrfCoordinator_);
        s_keyHash = s_keyHash_;
        _owner = owner_;
        COORDINATOR = VRFCoordinatorV2Interface(vrfCoordinator_);
        s_subscriptionId = subscriptionId_;

        // Default config of contract
        _priceNft = 100;
        DOMINATOR = 100;
        RATE_TO_MINT_NFT = 30;

        // Init param for Chainlink VRF contract
        callbackGasLimit = 1720000;
        requestConfirmations = 3;
        numWords = 1;
    }

    modifier onlyOwner() {
        require(msg.sender == _owner, "BlockPool::Only owner can do this!");
        _;
    }

    /**
     * Update gas call back limit of VRF when call fullfill random
     *
     * @param maxGas_ new gas limit value
     */
    function setGasCallbackLimit(uint32 maxGas_) public onlyOwner {
        callbackGasLimit = maxGas_;
    }

    /**
     * Update new price when user request mint NFT
     * @param priceNft_ new price of NFT
     */
    function setPriceNft(uint32 priceNft_) public onlyOwner {
        _priceNft = priceNft_;
    }

    function _mint(address to_, string memory tokenURI_)
        internal
        returns (uint256 trackedTokenID)
    {
        require(to_ != address(0), "BlockPool::Owner address is invalid!");

        _currentTokenID.increment();
        _totalNft.increment();

        trackedTokenID = _currentTokenID.current();
        _mint(to_, trackedTokenID);
        _tokenURIs[trackedTokenID] = tokenURI_;

        return trackedTokenID;
    }

    /**
     * Use to call to VRF contract to get a new random value
     *
     * @param user_ Address of user who will own NFT
     */
    function requestRandomNumber(address user_)
        internal
        returns (uint256 requestId)
    {
        // Will revert if subscription is not set and funded.
        requestId = COORDINATOR.requestRandomWords(
            s_keyHash,
            s_subscriptionId,
            requestConfirmations,
            callbackGasLimit,
            numWords
        );
        // Save request
        _requests[requestId] = RequestMintData({
            user: user_,
            priceNft: _priceNft
        });
    }

    /**
     * Callback function for VRF contract call when fullfill request
     *
     * @param requestId_ Request ID
     * @param randomWords_ Return data of VRF contract
     */
    function fulfillRandomWords(
        uint256 requestId_,
        uint256[] memory randomWords_
    ) internal override {
        uint256 randomValue = (randomWords_[0] % DOMINATOR) + 1;
        address toUser = _requests[requestId_].user;
        // Use mint success
        if (randomValue <= RATE_TO_MINT_NFT) {
            // Mint nft
            _mint(toUser, _contractURI);
            // Save price of nft to support refund
            _tokenMintedPrice[_currentTokenID.current()] = _requests[requestId_]
                .priceNft;
            emit MintNFTResult(
                toUser,
                true,
                randomValue,
                _currentTokenID.current(),
                requestId_
            );
        } else {
            // Use mint fail
            emit MintNFTResult(toUser, false, randomValue, 0, requestId_);
        }
    }

    /**
     * User call to request minting an NFT
     *
     * @param to_ Address of user who will own NFT
     */
    function requestNft(address to_) external payable {
        uint256 _amount = msg.value;
        require(_amount >= _priceNft);
        requestRandomNumber(to_);
    }

    /**
     * User call to refund an NFT
     *
     * @param tokenId_ Token ID user want to refund
     * @param receiver_ Address of user would receive ETH
     */
    function refund(uint256 tokenId_, address payable receiver_) external {
        require(_ownerOf(tokenId_) == msg.sender);
        // burn before refund to avoid reentrancy
        _burn(tokenId_);

        uint256 refundAmount = _tokenMintedPrice[tokenId_];
        require(address(this).balance > refundAmount);

        // Does not need safe math since using solidity 0.8+
        receiver_.transfer((refundAmount * REFUND_RATE) / DOMINATOR);
    }
}
