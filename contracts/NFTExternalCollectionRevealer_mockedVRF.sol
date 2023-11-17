pragma solidity ^0.8.20;
// SPDX-License-Identifier: MIT

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "./BaseNFTCollection.sol";
import "./VRFv2Consumer.sol";


contract NFTExternalCollectionRevealer_mockedVRF is ERC721, ERC721URIStorage, ERC721Burnable, Ownable, Pausable {
    bool public REVEAL_STARTED = true;
    bool public VRF_INITIALIZED = true;
    
    mapping(uint256 => bool) is_token_revealed;
    mapping(uint256 => bool) is_reveal_id_claimed;

    uint256 public MINT_PRICE;
    string[] public REVEAL_METADATA;
    string public UNREVEALED_METADATA;
    
    uint256 _token_id; 
    uint _num_claimed;
    uint256 public max_supply;

    BaseNFTCollection public externalNFTCollection;
    VRFv2Consumer private vrfV2Consumer;

    event Mint(address collection, address indexed to, uint256 token_id);
    event Reveal(address collection, address indexed to, uint256 token_id, uint256 reveal_id);

    error RevealFailed();

    constructor(
        string memory name,
        string memory description,
        string memory external_collection_name,
        string memory external_collection_description,
        address owner
    )
        ERC721(name, description)
        Ownable(owner)
    {
        is_reveal_id_claimed[0] = true; // token_id=0 should not exist

        max_supply = 6;

        REVEAL_METADATA = [
            '{"trait1": "value1"}',
            '{"trait2": "value2"}',
            '{"trait3": "value3"}',
            '{"trait4": "value4"}',
            '{"trait5": "value5"}',
            '{"trait6": "value6"}'
        ];
        UNREVEALED_METADATA = '{"generic_trait": "generic_value"}';
        MINT_PRICE = 0.0;
        
        externalNFTCollection = new BaseNFTCollection(external_collection_name, external_collection_description, address(this));

        _token_id = 1;
        _num_claimed = 0;
    }

    modifier revealStarted {
        require(REVEAL_STARTED);
        _;
    }

    modifier vrfInitialized {
        require(VRF_INITIALIZED);
        _;
    }

    function start_reveal() external onlyOwner vrfInitialized {
        // once reveal stage is started, it should not be able to be switched back off
        REVEAL_STARTED = true;
    }

    function confirm_vrf_intialized() external onlyOwner {
        // once reveal stage is started, it should not be able to be switched back off
        VRF_INITIALIZED = true;
    }

    function mint(address to) public payable whenNotPaused vrfInitialized {
        require(msg.value >= MINT_PRICE, "Insufficient funds to mint");

        _safeMint(to, _token_id);
        emit Mint(address(this), msg.sender, _token_id);

        _setTokenURI(_token_id++, UNREVEALED_METADATA);

        uint256 refund = msg.value - MINT_PRICE;
        if (refund > 0) {
            (bool sent, ) = payable(to).call{value: msg.value}("");
            require(sent, "Failed to send Ether");
        }
    }

    function initiate_reveal_request() public revealStarted vrfInitialized returns (uint256 _request_id) {
        _request_id = request_random_words();
    }

    function reveal(uint256 tokenId, uint256 request_id) public revealStarted vrfInitialized {
        require(msg.sender == ownerOf(tokenId), "User does not own this token");
        require(!is_token_revealed[tokenId], "Token already revealed"); // to help throttle unecessary traffic from already-claimed token & prevent users from abusing Chainlink calls

        uint256[6] memory random_words = get_random_words(request_id);
        _reveal(msg.sender, tokenId, _get_random_metadata_index(random_words));
    }

    function _reveal(address token_owner, uint256 tokenId, uint256 reveal_id) private revealStarted vrfInitialized {
        require(token_owner == ownerOf(tokenId), "User does not own this token");

        string memory revealed_uri = REVEAL_METADATA[reveal_id];

        burnAndMintToExternal(token_owner, tokenId, revealed_uri);

        is_reveal_id_claimed[reveal_id] = true;
    }

    function burnAndMintToExternal(address token_owner, uint256 tokenId, string memory revealed_uri) internal virtual vrfInitialized {
        require(token_owner == ownerOf(tokenId), "User does not own this token");

        externalNFTCollection.mint(ownerOf(tokenId), tokenId, revealed_uri);
        _burn(tokenId);
        
        require(token_owner == externalNFTCollection.ownerOf(tokenId), "ownerOf(tokenId)");
    }

    function request_random_words() private view vrfInitialized returns (uint256 _request_id) {
        uint256 rand_seed = uint256(keccak256(abi.encodePacked(block.timestamp, blockhash(block.number - 1))));

        _request_id = (rand_seed % max_supply) + 1; // mock return value of VRFv2Consumer.requestRandomWords()
    }

    function get_random_words(uint256 _request_id) private view vrfInitialized returns (uint256[6] memory random_words) {
        uint256[6] memory random_words = [
            uint256(8639826497326470932),
            uint256(2342389583947543498),
            uint256(9809110990999999111),
            uint256(1100023829839829382),
            uint256(1236676776737773717),
            uint256(8745936730928489899)
        ]; // mock return value of VRFv2Consumer.getRequestStatus()[1]
    }

    function _truncate_number_within_max_supply_range(uint256 value) private view vrfInitialized returns (uint256) {
        return (value % max_supply) + 1;
    }

    function _get_random_metadata_index(uint256[6] memory random_words) private view vrfInitialized returns(uint256) {
        uint256 reveal_id;

        for (uint i = 0; i < random_words.length; ++i){
            reveal_id = _truncate_number_within_max_supply_range(random_words[i]);

            if (!is_reveal_id_claimed[reveal_id] && reveal_id <= REVEAL_METADATA.length) {
                return reveal_id;
            }
        }

        revert RevealFailed();
    }
    
    function get_external_nft_collection_address() public view returns (address) {
        return address(externalNFTCollection);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
        vrfInitialized
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}
