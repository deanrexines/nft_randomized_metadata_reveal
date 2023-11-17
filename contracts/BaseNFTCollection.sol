pragma solidity ^0.8.20;

// SPDX-License-Identifier: MIT
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";


contract BaseNFTCollection is ERC721, ERC721URIStorage, Ownable {
    mapping(uint256 => uint256) public native_to_external_token_ids;
    // address public immutable external_collection;

    constructor(
        string memory name, 
        string memory symbol,
        address owner
    ) 
        ERC721(name, symbol)
        Ownable(owner)

    {
        // external_collection = _external_collection;
    }

    function mint(address to, uint256 tokenId, string memory tokenURI) external {
        _mint(to, tokenId);
        _setTokenURI(tokenId, tokenURI);
    }

    function updateTokenURI(uint256 tokenId, string memory newTokenURI) external onlyOwner {
        // _setTokenURI(tokenId, newTokenURI);
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
