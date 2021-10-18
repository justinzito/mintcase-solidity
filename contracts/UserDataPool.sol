// SPDX-License-Identifier: MEH

pragma solidity ^0.8.0;

import "./interfaces/IUserDataPoolCreator.sol";
import "./interfaces/IUserDataPoolSeries.sol";
import "./oz/Counters.sol";
import "./oz/AccessControl.sol";
import "./oz/Context.sol";
import "./oz/SafeMath.sol";
import "./oz/Address.sol";

contract UserDataPool is IUserDataPoolCreator, IUserDataPoolSeries, AccessControl {
    using Counters for Counters.Counter;
    using SafeMath for uint256;
    using Address for address;

    event CreatorAdded(address _creatorAddress);

    event SeriesAdded(address _creatorAddress, uint256 _seriesId);
    event SeriesUpdated(uint256 _seriesId);
    event SeriesPriceUpdated(uint256 _seriesId);

    //Role Creation
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant PROXY_ROLE = keccak256("PROXY_ROLE");

    uint defaultPlatformPercentage = 80;
    uint defaultInvitations = 2;
    string defaultTokenURI = "https://token.mintcase.io/";
    uint256 totalTokensMinted = 0;

    mapping(address => Creator) internal creators;

    uint256 constant ONE_MILLION = 1_000_000;
    Counters.Counter private nextSeriesId;
    mapping(uint256 => Series) private seriesList;

    modifier onlyProxyOrAdmin() {
        
        require (
            hasRole(ADMIN_ROLE,_msgSender()) ||
            hasRole(PROXY_ROLE,_msgSender()),
            "No Permission.");
        _;
    }

    constructor() {

        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(ADMIN_ROLE,_msgSender());

        nextSeriesId.increment();
    }

    /*
    ADMIN FUNCTIONS
    */

    function updateDefaultPlatformPercentage(
        uint _invitations
    ) external onlyRole(ADMIN_ROLE) {
        defaultInvitations = _invitations;
    }

    function updateDefaultInvitations(
        uint _defaultInvitations
    ) external onlyRole(ADMIN_ROLE) {
        defaultInvitations = _defaultInvitations;
    }

    function updateDefaultTokenURI(
        string memory _defaultTokenURI
    ) external onlyRole(ADMIN_ROLE) {
        defaultTokenURI = _defaultTokenURI;
    }

    function updateCreatorPlatformPercentage(
        address _creatorAddress,
        uint _platformPercentage
    ) external onlyRole(ADMIN_ROLE) {
        creators[_creatorAddress].platformPercentage = _platformPercentage;
    }

    function updateSeriesPlatformPercentage(
        uint256 _seriesId,
        uint _platformPercentage
    ) external onlyRole(ADMIN_ROLE) {
        seriesList[_seriesId].platformPercentage = _platformPercentage;
    }

    //TODO: remove creator role?
    function banishCreator(
        address _creatorAddress
    ) external onlyRole(ADMIN_ROLE) {

        creators[_creatorAddress].status = CreatorStatus.Banished;

        uint256[] memory seriesIds = _getCreatorSeriesIds(_creatorAddress);

        for (uint256 i = 0; i < seriesIds.length; i = i.add(1)) {
            seriesList[seriesIds[i]].status = SeriesStatus.Delisted;
        }
    }

    function getDefaultPlatformPercent(
    ) external view override returns (uint) {
        return defaultPlatformPercentage;
    }

    function getDefaultInvitations(
    ) external view override returns (uint) {
        return defaultInvitations;
    }

    function isAdmin(
        address _by
    ) external view onlyProxyOrAdmin() override(IUserDataPoolCreator,IUserDataPoolSeries) returns (bool) {
        return hasRole(ADMIN_ROLE,_by);
    }

    function isProxy(
        address _by
    ) external view onlyProxyOrAdmin() override returns (bool) {
        return hasRole(PROXY_ROLE,_by);
    }

    /*
    CREATOR IMPLEMENTATION
    */

    function _addCreator(
        address _creatorAddress,
        string memory _name,
        uint _platformPercentage,
        uint _remainingInvitations,
        address _invitedBy,
        CreatorStatus _status) internal {

        require(creators[_creatorAddress].status == CreatorStatus.NotInvited,"registered.");
        require(_status != CreatorStatus.NotInvited,"Invalid.");
        require(_platformPercentage <= 250,"Invalid %");
        //TODO: verify that out of range status will throw error.

        creators[_creatorAddress].name = _name;
        creators[_creatorAddress].platformPercentage = _platformPercentage;
        creators[_creatorAddress].remainingInvitations = _remainingInvitations;
        creators[_creatorAddress].invitedBy = _invitedBy;
        creators[_creatorAddress].status = _status;

        emit CreatorAdded(_creatorAddress);
    }

    function addCreator(
        address _creatorAddress,
        string memory _name,
        uint _platformPercentage,
        uint _remainingInvitations,
        address _invitedBy,
        CreatorStatus _status
    ) external override onlyProxyOrAdmin() {
        
        _addCreator(
        _creatorAddress,
        _name,
        _platformPercentage,
        _remainingInvitations,
        _invitedBy,
        _status);

    }

    function updateCreatorName(
        address _creatorAddress,
        string memory _name
    ) external override onlyProxyOrAdmin() {
        creators[_creatorAddress].name = _name;
    }

    function updateCreatorInvitations(
        address _creatorAddress,
        address _invitationAddress,
        uint _remainingInvitations
    ) external override onlyProxyOrAdmin() {
        creators[_creatorAddress].invitations.push(_invitationAddress);
        creators[_creatorAddress].remainingInvitations = _remainingInvitations;
    }

    function updateCreatorRemainingInvitations(
        address _creatorAddress,
        uint _remainingInvitations
    ) external override onlyProxyOrAdmin() {
        creators[_creatorAddress].remainingInvitations = _remainingInvitations;
    }
    
    function addCreatorTokensMinted(
        address _creatorAddress
    ) external override onlyProxyOrAdmin() {
        creators[_creatorAddress].totalSeriesTokensMinted = creators[_creatorAddress].totalSeriesTokensMinted.add(1);
    }

    function updateCreatorStatus(
        address _creatorAddress,
        CreatorStatus _status
    ) external override onlyProxyOrAdmin() {
        creators[_creatorAddress].status = _status;
    }

    function getCreator(
        address _creatorAddress
    ) external view override returns (
        Creator memory
    ) {
        return creators[_creatorAddress];
    }

    function getCreatorRemainingInvites(
        address _creatorAddress
    ) external view override returns (
        uint
    ) {
        return creators[_creatorAddress].remainingInvitations;
    }

    function getCreatorInvites(
        address _creatorAddress
    ) external view override returns (
        address[] memory
    ) {
        uint256 inviteLength = creators[_creatorAddress].invitations.length;
        address[] memory invitationList = new address[](inviteLength);
        uint256 i = 0;
        for (i = 0; i < inviteLength; i++) {
            invitationList[i] = creators[_creatorAddress].invitations[i];
        }
        return invitationList;
    }

    function _getCreatorSeriesIds(
        address _creatorAddress
    ) internal view returns (
        uint256[] memory
    ) {
        uint256 seriesLength = creators[_creatorAddress].seriesIds.length;
        uint256[] memory seriesIds = new uint256[](seriesLength);
        uint256 i = 0;
        for (i = 0; i < seriesLength; i++) {
        seriesIds[i] = creators[_creatorAddress].seriesIds[i];
        }

        return seriesIds;
    }

    function getCreatorSeriesIds(
        address _creatorAddress
    ) external view override returns (
        uint256[] memory
    ) {

        return _getCreatorSeriesIds(_creatorAddress);
    }

    function getCreatorPlatformPercent(
        address _creatorAddress
    ) external view override returns (
        uint
    ) {
        return creators[_creatorAddress].platformPercentage;
    }

    function isCreatorStatus(
        address _creatorAddress,
        CreatorStatus _status
    ) external view override(IUserDataPoolCreator,IUserDataPoolSeries) returns (
        bool
    ) {
        return (creators[_creatorAddress].status == _status);
    }

    /*
    SERIES IMPLEMENTATION
    */

    function addSeries(
        address _creatorAddress,
        string memory _name, 
        string memory _description, 
        uint _platformPercentage,
        uint256 _maxSupply,
        uint256 _priceInWei,
        bool _onePerWallet,
        string memory _scriptConfig
    ) external override onlyProxyOrAdmin() returns (uint256) {
    
        require(
            _maxSupply <= ONE_MILLION,
            "Supply too large."
        );

        uint256 seriesId = nextSeriesId.current();
        nextSeriesId.increment();
      
        seriesList[seriesId].creatorAddress = _creatorAddress;
        seriesList[seriesId].name = _name;
        seriesList[seriesId].description = _description;
        seriesList[seriesId].platformPercentage = _platformPercentage;
        seriesList[seriesId].maxSupply = _maxSupply;
        seriesList[seriesId].priceInWei = _priceInWei;
        seriesList[seriesId].onePerWallet = _onePerWallet;
        seriesList[seriesId].scriptConfig = _scriptConfig;
        seriesList[seriesId].tokenURI = defaultTokenURI;
        
        creators[_creatorAddress].seriesIds.push(seriesId);

        emit SeriesAdded(_creatorAddress,seriesId);

        return seriesId;
    }

    function tokenMinted(
        uint256 _seriesId
    ) external override onlyProxyOrAdmin() {
        seriesList[_seriesId].totalMinted = seriesList[_seriesId].totalMinted.add(1);

        address seriesCreator = seriesList[_seriesId].creatorAddress;
        creators[seriesCreator].totalSeriesTokensMinted = 
            creators[seriesCreator].totalSeriesTokensMinted.add(1);
        
        totalTokensMinted = totalTokensMinted.add(1);
    }

    function updateSeriesNameAndDescription(
        uint256 _seriesId,
        string memory _name,
        string memory _description
    ) external override onlyProxyOrAdmin() {
        seriesList[_seriesId].name = _name;
        seriesList[_seriesId].description = _description;
    }

    function updateSeriesSecondPayee(
        uint256 _seriesId,
        address _secondPayeeAddress,
        uint _secondPayeePercentage
    ) external override onlyProxyOrAdmin() {
        require (
            _secondPayeePercentage < 1000,
            "Invalid Percentage."
        );
        seriesList[_seriesId].secondPayeeAddress = _secondPayeeAddress;
        seriesList[_seriesId].secondPayeePercentage = _secondPayeePercentage;
    }

    function removeSeriesSecondPayee(
        uint256 _seriesId
    ) external override onlyProxyOrAdmin() {
        delete seriesList[_seriesId].secondPayeeAddress;
        delete seriesList[_seriesId].secondPayeePercentage;
    }

    function updateSeriesCurrency(
        uint256 _seriesId,
        address _currencyContract,
        string memory _currencySymbol
    ) external override onlyProxyOrAdmin() {

        require(
            _currencyContract.isContract(),
            "Not a contract."
        );

        seriesList[_seriesId].currencyContract = _currencyContract;
        seriesList[_seriesId].currencySymbol = _currencySymbol;
    }

    function removeSeriesCurrency(
        uint256 _seriesId
    ) external override onlyProxyOrAdmin() {
        delete seriesList[_seriesId].currencyContract;
        delete seriesList[_seriesId].currencySymbol;
    }

    function updateSeriesMaxSupply(
        uint256 _seriesId,
        uint256 _maxSupply
    ) external override onlyProxyOrAdmin() {
        seriesList[_seriesId].maxSupply = _maxSupply;
    }

    function updateSeriesPriceInWei(
        uint256 _seriesId,
        uint256 _priceInWei
    ) external override onlyProxyOrAdmin() {
        seriesList[_seriesId].priceInWei = _priceInWei;
    }

    function updateSeriesOnePerWallet(
        uint256 _seriesId,
        bool _onePerWallet
    ) external override onlyProxyOrAdmin() {
        seriesList[_seriesId].onePerWallet = _onePerWallet;
    }

    function updateSeriesScriptConfig(
        uint256 _seriesId,
        string memory _scriptConfig
    ) external override onlyProxyOrAdmin() {
        seriesList[_seriesId].scriptConfig = _scriptConfig;
    }

    function addScriptToSeries(
        uint256 _seriesId,
        string memory _script
    ) external override onlyProxyOrAdmin() {
        seriesList[_seriesId].scripts.push(_script);

        if (seriesList[_seriesId].status == SeriesStatus.Uninitialized) {
            seriesList[_seriesId].status = SeriesStatus.Ready;
        }
    }

    function removeLastScriptFromSeries(
        uint256 _seriesId
    ) external override onlyProxyOrAdmin() {
        seriesList[_seriesId].scripts.pop();
    }

    function updateSeriesStatus(
        uint256 _seriesId,
        SeriesStatus _status
    ) external override onlyProxyOrAdmin() {
        seriesList[_seriesId].status = _status;
    }

    function getSeries(
        uint256 _seriesId
    ) external view override returns (Series memory) {
        return seriesList[_seriesId];
    }

    function getSeriesCreatorAddress(
        uint256 _seriesId
    ) external view override returns (
        address
    ) {
        return seriesList[_seriesId].creatorAddress;
    }

    function getSeriesScriptCount(
        uint256 _seriesId
    ) external view override returns (uint256) {
        return seriesList[_seriesId].scripts.length;
    }

    function getSeriesScriptAtIndex(
        uint256 _seriesId,
        uint256 _scriptIndex
    ) external view override returns (string memory) {
        return seriesList[_seriesId].scripts[_scriptIndex];
    }

    function getSeriesMintInformation(
        uint256 _seriesId
    ) external view override returns (
        uint256 _totalMinted,
        uint256 _maxSupply
    ) {

        _totalMinted = seriesList[_seriesId].totalMinted;
        _maxSupply = seriesList[_seriesId].maxSupply;
        return (_totalMinted,_maxSupply);
    }

    function getSeriesPriceInWei(
        uint256 _seriesId
    ) external view override returns (
        uint256
    ) {
        return seriesList[_seriesId].priceInWei;
    }

    function getSeriesPlatformPercent(
        uint256 _seriesId
    ) external view override returns (
        uint
    ) {
        return seriesList[_seriesId].platformPercentage;
    }

    function getSeriesSecondPayeeInformation(
        uint256 _seriesId
    ) external view override returns (
        address _secondPayeeAddress,
        uint _secondPayeePercent
    ) {
        return (
            seriesList[_seriesId].secondPayeeAddress,
            seriesList[_seriesId].secondPayeePercentage
        );
    }

    function getSeriesOnePerWallet(
        uint256 _seriesId
    ) external view override returns (
        bool
    ) {
        return seriesList[_seriesId].onePerWallet;
    }

    function getSeriesTokenURI(
        uint256 _seriesId
    ) external view override returns (
        string memory
    ) {
        return seriesList[_seriesId].tokenURI;
    }

    function isSeriesStatus(
        uint256 _seriesId,
        SeriesStatus _status
    ) external view override returns (
        bool
    ) {
        return (seriesList[_seriesId].status == _status);
    }

    function isSeriesCreator(
        uint256 _seriesId,
        address _creatorAddress
    ) external view override returns (
        bool
    ) {
        return (seriesList[_seriesId].creatorAddress == _creatorAddress);
    }

    function getTotalTokensMinted(
    )
    external view override returns (
        uint256
    ) {
        return totalTokensMinted;
    }
}