// SPDX-License-Identifier: MEH

pragma solidity ^0.8.0;

import "./oz/ERC721Enumerable.sol";
import "./oz/Ownable.sol";
import "./oz/Strings.sol";
import "./interfaces/IUserDataPoolSeries.sol";
import "./interfaces/ICreatorDataType.sol";
import "./interfaces/ISeriesDataType.sol";
import "./interfaces/ISeriesController.sol";


contract MintController is ERC721Enumerable, Ownable, ISeriesDataType {
    using Strings for uint256;

    event TokenMinted(uint256 _seriesId, address _to);

    address dataPoolAddress;
    address seriesControllerAddress;
    mapping(uint256 => bytes32) public tokenIdHashes;
    mapping(uint256 => uint256) public tokenIdToSeriesId;

    modifier onlyMinter() {

        require(
            IUserDataPoolSeries(
                dataPoolAddress
            ).isProxy(_msgSender()),
            "No access."
        );
        _;
    }

    constructor(
        address _dataPoolAddress,
        address _seriesControllerAddress,
        string memory _tokenName,
        string memory _tokenSymbol
    ) ERC721(_tokenName, _tokenSymbol) {
        dataPoolAddress = _dataPoolAddress;
        seriesControllerAddress = _seriesControllerAddress;
    }

    function updateDataPoolAddress(address _dataPoolAddress) external onlyOwner() {
        dataPoolAddress = _dataPoolAddress;
    }
    
    function updateSeriesControllerAddress(address _seriesControllerAddress) external onlyOwner() {
        seriesControllerAddress = _seriesControllerAddress;
    }

    //TODO: one per wallet functionality?
    function mint(uint256 _seriesId, address _to, address _by) external onlyMinter() {

        bool ok;
        uint256 tokenId;
        (ok,tokenId) = ISeriesController(
            seriesControllerAddress
        ).attemptToMint(_seriesId, _by);
        require(ok,"Denied.");

        bytes32 tokenHash = keccak256(abi.encodePacked(tokenId, block.number, _to, block.timestamp));
        tokenIdHashes[tokenId]= tokenHash;
        tokenIdToSeriesId[tokenId] = _seriesId;
        _mint(_to, tokenId);
    }

    function tokensOfOwner(address _owner) external view returns (uint256[] memory) {
        uint256 tokenCount = balanceOf(_owner);
        uint256[] memory tokenList = new uint256[](tokenCount);
        uint256 i = 0;
        for (i = 0; i < tokenCount; i++) {
          tokenList[i] = tokenOfOwnerByIndex(_owner,i);
        }

        return tokenList;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {

        uint256 seriesId = tokenIdToSeriesId[tokenId];

        string memory baseURI = IUserDataPoolSeries(
            dataPoolAddress
        ).getSeriesTokenURI(seriesId);

        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

}