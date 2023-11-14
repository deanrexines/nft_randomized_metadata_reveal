// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts@5.0.0/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts@5.0.0/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts@5.0.0/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts@5.0.0/access/Ownable.sol";
import "./VRFAttributeRandomizer.sol";

contract NFTInternalCollectionReveal is ERC721, ERC721URIStorage, ERC721Burnable, Ownable {
    string[] public trait_types;
    string[] private REVEAL_METADATA;
    string UNREVEALED_METADATA;
    address public immutable _this;
    uint64 subscriptionId = "";
    uint8 num_attributes;
    uint _num_claimed = 0;
    mapping(address => mapping(uint256 => bool)) has_revealed;
    VRFAttributeRandomizer private vrfAttributeRandomizer;
    uint256 _tokenId; 
    mapping(uint256 => bool) claimed_reveal_ids;
    uint256 max_supply;
    uint256 private _request_id;
    bool private REVEAL_STARTED = false;

    constructor(
        address owner,
        string memory name,
        string memory description,
        string[] memory _trait_types,
        uint32 _num_words,
        uint8 _num_attributes,
        string[] memory _reveal_metadata,
        string memory _unrevealed_metadata,
        uint256 _max_supply
    )
        ERC721(name, description)
        Ownable(owner)
    {
        _this = address(this);

        require(_trait_types.length == _num_words, "There must be as many trait types as there are randomized trait values");
        trait_types = _trait_types;

        num_attributes = _num_attributes;
        REVEAL_METADATA = _reveal_metadata;
        UNREVEALED_METADATA = _unrevealed_metadata;
        max_supply = _max_supply;

        vrfAttributeRandomizer = new VRFAttributeRandomizer(        
            subscriptionId,
            _num_words
        );

        _tokenId = 0;
    }

    modifier revealStarted {
        require(REVEAL_STARTED);
        _;
    }

    function mint(address to) public  onlyOwner {
        _safeMint(to, _tokenId++);
        _setTokenURI(tokenId, UNREVEALED_METADATA);
    }

    start_reveal() onlyOwner {
        uint256 _request_id = requestRandomWords();
        REVEAL_STARTED = true;
    }

    function reveal(uint256 tokenId) external onlyOwner revealStarted {
        require(msg.sender == ownerOf(tokenId), "User does not own this token");
        require(!has_revealed[msg.sender][tokenId], "User has already revealed for this token");
        claim_id = _num_claimed++;

        uint256 i = 0;
        uint256 unclaimed_reveal_id;
        uint256[] random_attribute_values = _this.random_attribute_values(_request_id); 
        
        while (!claimed_reveal_ids[unclaimed_reveal_id] && i <= random_attribute_values.length && i <= max_supply) {
            // if (!claimed_reveal_ids[unclaimed_reveal_id]) {
            //     claimed_reveal_ids[unclaimed_reveal_id] = true;
            //     unclaimed_reveal_id = sdfsdfs;
            //     break;
            // }
            if (!claimed_reveal_ids[random_attribute_values[i]]) {
                unclaimed_reveal_id = random_attribute_values[i];

                claimed_reveal_ids[unclaimed_reveal_id] = true;
                break;
            }
            
            ++i;    
            if (i == random_attribute_values.length || i == max_supply) {
                revert("Ran out of id's somehow");
            }
        }

        string memory revealed_uri = REVEAL_METADATA[unclaimed_reveal_id];
        // string memory revealed_uri = _this.get_randomized_metadata();

        _this._setTokenURI(tokenId,  revealed_uri);

        has_revealed[msg.sender][tokenId] = true;
    }

    function random_attribute_values(uint256 request_id) private pure returns (uint256[]) {
        return vrfAttributeRandomizer.get_random_number(request_id);
    }

    function get_randomized_metadata(uint256[] memory random_attribute_values) private pure returns (string memory) {
        string memory jsonString = '{';
        jsonString = string(abi.encodePacked(jsonString, '"name":"', _this.name(), '","description":"', _this.description(), '","attributes":['));

        for (uint256 i = 0; i < num_attributes; i++) {
            if (i > 0) {
                jsonString = string(abi.encodePacked(jsonString, ','));
            }
            jsonString = string(abi.encodePacked(jsonString, '{"trait_type":"', trait_types[random_attribute_values[i]], '","value":"', random_attribute_values[i], '"}'));
        }

        jsonString = string(abi.encodePacked(jsonString, ']}'));
        
        return jsonString;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
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