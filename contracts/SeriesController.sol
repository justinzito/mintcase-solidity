// SPDX-License-Identifier: MEH

pragma solidity ^0.8.0;

import "./interfaces/IUserDataPoolSeries.sol";
import "./interfaces/ICreatorDataType.sol";
import "./interfaces/ISeriesDataType.sol";
import "./interfaces/ISeriesController.sol";
import "./oz/Ownable.sol";
import "./oz/SafeMath.sol";

contract SeriesController is Ownable, ISeriesController, ICreatorDataType, ISeriesDataType {
    using SafeMath for uint256;

    event SeriesUpdated(uint256 _seriesId);
    event SeriesPriceUpdated(uint256 _seriesId);

    uint256 constant ONE_MILLION = 1_000_000;

    address dataPoolAddress;


    modifier onlyActiveCreatorOrAdmin() {

        require(
            IUserDataPoolSeries(
                dataPoolAddress
            ).isCreatorStatus(_msgSender(), CreatorStatus.Active) || 
            IUserDataPoolSeries(
                dataPoolAddress
            ).isAdmin(_msgSender()),
            "No access."
        );
        _;
    }

    modifier onlyOpenSeries(uint256 _seriesId) {
        require(
            !IUserDataPoolSeries(
                dataPoolAddress
            ).isSeriesStatus(_seriesId,SeriesStatus.Locked) &&
            !IUserDataPoolSeries(
                dataPoolAddress
            ).isSeriesStatus(_seriesId,SeriesStatus.Delisted),
            "Series closed."
        );
        _;
    }

    modifier onlyOpenSeriesCreator(uint256 _seriesId) {
        
        require(
            IUserDataPoolSeries(
                dataPoolAddress
            ).isCreatorStatus(_msgSender(), CreatorStatus.Active) || 
            IUserDataPoolSeries(
                dataPoolAddress
            ).isAdmin(_msgSender()),
            "No access."
        );
    
        require(
            !IUserDataPoolSeries(
                dataPoolAddress
            ).isSeriesStatus(_seriesId,SeriesStatus.Locked) &&
            !IUserDataPoolSeries(
                dataPoolAddress
            ).isSeriesStatus(_seriesId,SeriesStatus.Delisted),
            "Series closed."
        );
        
        require(
            IUserDataPoolSeries(
                dataPoolAddress
            ).isSeriesCreator(_seriesId,_msgSender()),
            "Not creator."
        );

        _;
    }

    constructor(address _dataPoolAddress) {
        dataPoolAddress = _dataPoolAddress;
    }

    function updateDataPoolAddress(address _dataPoolAddress) external onlyOwner() {
        dataPoolAddress = _dataPoolAddress;
    }

    function addSeries(
        string memory _name, 
        string memory _description, 
        uint256 _maxSupply,
        uint256 _priceInWei,
        bool _onePerWallet,
        string memory _scriptConfig
    ) external onlyActiveCreatorOrAdmin() returns (uint256) {

        uint256 seriesId = IUserDataPoolSeries(
            dataPoolAddress
        ).addSeries(
            _msgSender(),
            _name,
            _description,
            IUserDataPoolSeries(
                dataPoolAddress
            ).getCreatorPlatformPercent(
                _msgSender()
            ),
            _maxSupply,
            _priceInWei,
            _onePerWallet,
            _scriptConfig
        );

        return seriesId;
    }

    function updateSeriesNameAndDescription(
        uint256 _seriesId,
        string memory _name,
        string memory _description
    ) external onlyOpenSeriesCreator(_seriesId) {
        IUserDataPoolSeries(
            dataPoolAddress
        ).updateSeriesNameAndDescription(_seriesId,_name,_description);

        emit SeriesUpdated(_seriesId);
    }

    function updateSeriesSecondPayee(
        uint256 _seriesId,
        address _secondPayeeAddress,
        uint _secondPayeePercentage
    ) external onlyOpenSeriesCreator(_seriesId) {

        IUserDataPoolSeries(
            dataPoolAddress
        ).updateSeriesSecondPayee(
            _seriesId,
            _secondPayeeAddress,
            _secondPayeePercentage
        );

        emit SeriesUpdated(_seriesId);
    }

    function removeSeriesSecondPayee(
        uint256 _seriesId
    ) external onlyOpenSeriesCreator(_seriesId) {

        IUserDataPoolSeries(
            dataPoolAddress
        ).removeSeriesSecondPayee(_seriesId);

         emit SeriesUpdated(_seriesId);
    }

    function updateSeriesCurrency(
        uint256 _seriesId,
        address _currencyContract,
        string memory _currencySymbol
    ) external onlyOpenSeriesCreator(_seriesId) {

        require(
            IUserDataPoolSeries(
            dataPoolAddress
            ).isSeriesStatus(_seriesId,SeriesStatus.Ready) ||
            IUserDataPoolSeries(
            dataPoolAddress
            ).isSeriesStatus(_seriesId,SeriesStatus.Paused),
            "Cannot change now."
        );

        IUserDataPoolSeries(
            dataPoolAddress
        ).updateSeriesCurrency(
            _seriesId,
            _currencyContract,
            _currencySymbol
        );

         emit SeriesUpdated(_seriesId);
    }

    function removeSeriesCurrency(
        uint256 _seriesId
    ) external {

        IUserDataPoolSeries(
            dataPoolAddress
        ).removeSeriesCurrency(
            _seriesId
        );

        emit SeriesUpdated(_seriesId);
    }

    function updateSeriesMaxSupply(
        uint256 _seriesId,
        uint256 _maxSupply
    ) external onlyOpenSeriesCreator(_seriesId) {
        uint256 totalMinted;
        uint256 maxSupply;

        (totalMinted,maxSupply) = IUserDataPoolSeries(
            dataPoolAddress
        ).getSeriesMintInformation(_seriesId);

        require(totalMinted == 0,"Cannot change now.");

        IUserDataPoolSeries(
            dataPoolAddress
        ).updateSeriesMaxSupply(_seriesId,_maxSupply);

        emit SeriesUpdated(_seriesId);
    }

    function updateSeriesPriceInWei(
        uint256 _seriesId,
        uint256 _priceInWei
    ) external onlyOpenSeriesCreator(_seriesId) {

        IUserDataPoolSeries(
            dataPoolAddress
        ).updateSeriesPriceInWei(_seriesId,_priceInWei);

        emit SeriesUpdated(_seriesId);
    }

    function updateSeriesScriptConfig(
        uint256 _seriesId,
        string memory _scriptConfig
    ) external onlyOpenSeriesCreator(_seriesId) {

        IUserDataPoolSeries(
            dataPoolAddress
        ).updateSeriesScriptConfig(_seriesId,_scriptConfig);

        emit SeriesUpdated(_seriesId);
    }

    function addScriptToSeries(
        uint256 _seriesId,
        string memory _script
    ) external onlyOpenSeriesCreator(_seriesId) {

        IUserDataPoolSeries(
            dataPoolAddress
        ).addScriptToSeries(_seriesId,_script);

        emit SeriesUpdated(_seriesId);
    }

    function removeLastScriptFromSeries(
        uint256 _seriesId
    ) external onlyOpenSeriesCreator(_seriesId) {

        IUserDataPoolSeries(
            dataPoolAddress
        ).removeLastScriptFromSeries(_seriesId);

        emit SeriesUpdated(_seriesId);
    }

    function updateSeriesStatus(
        uint256 _seriesId,
        SeriesStatus _status
    ) external onlyOpenSeriesCreator(_seriesId) {

        require(
            !IUserDataPoolSeries(
                dataPoolAddress
            ).isSeriesStatus(_seriesId,_status),
            "Did not change."
        );

        require(
            !IUserDataPoolSeries(
                dataPoolAddress
            ).isSeriesStatus(_seriesId,SeriesStatus.Uninitialized) &&
            (_status == SeriesStatus.Active ||
            _status == SeriesStatus.Paused) ,
            "Cannot change."
        );

        IUserDataPoolSeries(
            dataPoolAddress
        ).updateSeriesStatus(_seriesId,_status);

        emit SeriesUpdated(_seriesId);
    }

    /*
      ISERIES CONTROLLER METHODS
    */
    
    function attemptToMint(
        uint256 _seriesId,
        address _by
    ) external override returns(
        bool,
        uint256
    ) {

        require(
            IUserDataPoolSeries(
                dataPoolAddress
            ).isProxy(_msgSender()),
            "No Access."
        );

        require(
            IUserDataPoolSeries(
                dataPoolAddress
            ).isSeriesStatus(_seriesId,SeriesStatus.Ready) ||
            IUserDataPoolSeries(
                dataPoolAddress
            ).isSeriesStatus(_seriesId,SeriesStatus.Active) ||
            IUserDataPoolSeries(
                dataPoolAddress
            ).isSeriesStatus(_seriesId,SeriesStatus.Paused),
            "Series closed."
        );

        require(
            IUserDataPoolSeries(
                dataPoolAddress
            ).isSeriesStatus(_seriesId,SeriesStatus.Active) || 
            IUserDataPoolSeries(
                dataPoolAddress
            ).isSeriesCreator(_seriesId,_by),
            "Denied."
        );

        uint256 totalMinted;
        uint256 maxSupply;

        (totalMinted,maxSupply) = IUserDataPoolSeries(
            dataPoolAddress
        ).getSeriesMintInformation(_seriesId);

        require(
            totalMinted < maxSupply,
            "Supply reached."
        );

        IUserDataPoolSeries(
            dataPoolAddress
        ).tokenMinted(_seriesId);

        uint256 tokenId = (_seriesId * ONE_MILLION) + totalMinted;

        return (true,tokenId);
    }
}

