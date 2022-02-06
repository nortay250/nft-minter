// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract PixelHornicornClubLowerGas is ERC721, Ownable {
  using Strings for uint256;
  using Counters for Counters.Counter;

  Counters.Counter private supply;

  string public uriPrefix = "";
  string public uriSuffix = ".json";
  string public hiddenMetadataUri;
  
  uint256 public cost = 0.09 ether;
  uint256 public maxSupply = 10000;
  uint256 public maxMintAmountPerTx = 1;
  uint256 public nftPerAddressLimit = 3;

  bool public paused = true;
  bool public onlyWhitelisted = true;
  address[] public whitelistedAddresses;
  
  mapping (uint256 => bool) public revealed;
  mapping(address => uint256) public addressMintedBalance;

  constructor() ERC721("NAME", "SYMBOL") {
    setHiddenMetadataUri("ipfs://__CID__/hidden.json");
    // mint(msg.sender, 20);
  }

  function totalSupply() public view returns (uint256) {
    return supply.current();
  }

  // public
    function mint(uint256 _mintAmount) public payable {
        require(!paused, "The contract is paused!");
        require(msg.value >= cost * _mintAmount, "Insufficient funds!");
        require(_mintAmount > 0 && _mintAmount <= maxMintAmountPerTx, "Invalid mint amount!");
        require(supply.current() + _mintAmount <= maxSupply, "Max supply exceeded!");
        

         if (msg.sender != owner()) {
             if (onlyWhitelisted == true) {
                require(isWhitelisted(msg.sender), "user is not whitelisted");
                uint256 ownerMintedCount = addressMintedBalance[msg.sender]; 
                require(ownerMintedCount + _mintAmount <= nftPerAddressLimit);
             }
            require(msg.value >= cost * _mintAmount);
        }

        for (uint256 i = 1; i <= _mintAmount; i++) {
            addressMintedBalance[msg.sender]++;
            supply.increment();
            _safeMint(msg.sender, supply.current());
            revealed[supply.current()] = true;
        }
    }

    function isWhitelisted(address _user) public view returns (bool) {
        for(uint256 i=0; i<whitelistedAddresses.length; i++) {
            if (whitelistedAddresses[i] == _user) {
                return true;
            }
        }
        return false;
    }

    function walletOfOwner(address _owner)
    public
    view
    returns (uint256[] memory)
    {
        uint256 ownerTokenCount = balanceOf(_owner);
        uint256[] memory ownedTokenIds = new uint256[](ownerTokenCount);
        uint256 currentTokenId = 1;
        uint256 ownedTokenIndex = 0;

        while (ownedTokenIndex < ownerTokenCount && currentTokenId <= maxSupply) {
        address currentTokenOwner = ownerOf(currentTokenId);

        if (currentTokenOwner == _owner) {
            ownedTokenIds[ownedTokenIndex] = currentTokenId;

            ownedTokenIndex++;
        }

        currentTokenId++;
        }

        return ownedTokenIds;
    }

    function tokenURI(uint256 _tokenId)
    public
    view
    virtual
    override
    returns (string memory)
    {
        require(
        _exists(_tokenId),
        "ERC721Metadata: URI query for nonexistent token"
        );

        if (revealed[_tokenId] == false){
                return hiddenMetadataUri;
        }

        string memory currentBaseURI = _baseURI();
        return bytes(currentBaseURI).length > 0
            ? string(abi.encodePacked(currentBaseURI, _tokenId.toString(), uriSuffix))
            : "";
    }
    

    //only owner
    function setNftPerAddressLimit(uint256 _limit) public onlyOwner {
        nftPerAddressLimit = _limit;
    }

    function setCost(uint256 _newCost) public onlyOwner {
        cost = _newCost; //WEI
    }

     function setMaxMintAmountPerTx(uint256 _maxMintAmountPerTx) public onlyOwner {
        maxMintAmountPerTx = _maxMintAmountPerTx;
    }

    function setHiddenMetadataUri(string memory _hiddenMetadataUri) public onlyOwner {
        hiddenMetadataUri = _hiddenMetadataUri;
    }

    function setUriPrefix(string memory _uriPrefix) public onlyOwner {
        uriPrefix = _uriPrefix;
    }

    function setUriSuffix(string memory _uriSuffix) public onlyOwner {
        uriSuffix = _uriSuffix;
    }

    function setPaused(bool _state) public onlyOwner {
        paused = _state;
    }

    function setOnlyWhitelisted(bool _state) public onlyOwner {
        onlyWhitelisted = _state;
    }

    function whitelistUsers(address[] calldata _users) public onlyOwner {
        delete whitelistedAddresses;
        whitelistedAddresses = _users;
    }

    function withdraw() public onlyOwner {
        (bool os, ) = payable(owner()).call{value: address(this).balance}("");
        require(os);
    }

}

