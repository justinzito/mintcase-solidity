// SPDX-License-Identifier: MEH

pragma solidity ^0.8.0;

import "./ISeriesDataType.sol";
import "./ICreatorDataType.sol";

interface IUserDataPoolSeries is ISeriesDataType, ICreatorDataType {

    function isAdmin(
        address _by
    ) external view returns (bool);

    function isProxy(
        address _by
    ) external view returns (bool);

    function isCreatorStatus(
        address _creatorAddress,
        CreatorStatus _status
    ) external view returns (
        bool
    );

    function addSeries(
        address _creatorAddress,
        string memory _name, 
        string memory _description,
        uint _platformPercentage,
        uint256 _maxSupply,
        uint256 _priceInWei,
        bool _onePerWallet,
        string memory _scriptConfig
    ) external returns (uint256);

    function tokenMinted(
        uint256 _seriesId
    ) external;

    function updateSeriesNameAndDescription(
        uint256 _seriesId,
        string memory _name,
        string memory _description
    ) external;

    function updateSeriesSecondPayee(
        uint256 _seriesId,
        address _secondPayeeAddress,
        uint _secondPayeePercentage
    ) external;

    function removeSeriesSecondPayee(
        uint256 _seriesId
    ) external;

    function updateSeriesCurrency(
        uint256 _seriesId,
        address _currencyContract,
        string memory _currencySymbol
    ) external;

    function removeSeriesCurrency(
        uint256 _seriesId
    ) external;

    function updateSeriesMaxSupply(
        uint256 _seriesId,
        uint256 _maxSupply
    ) external;

    function updateSeriesPriceInWei(
        uint256 _seriesId,
        uint256 _priceInWei
    ) external;

    function updateSeriesOnePerWallet(
        uint256 _seriesId,
        bool _onePerWallet
    ) external;

    function updateSeriesScriptConfig(
        uint256 _seriesId,
        string memory _scriptConfig
    ) external;

    function addScriptToSeries(
        uint256 _seriesId,
        string memory _script
    ) external;

    function removeLastScriptFromSeries(
        uint256 _seriesId
    ) external;

    function updateSeriesStatus(
        uint256 _seriesId,
        SeriesStatus _status
    ) external;

    function getSeries(
        uint256 _seriesId
    ) external view returns (
        Series memory
    );

    function getSeriesCreatorAddress(
        uint256 _seriesId
    ) external view returns (
        address
    );

    function getSeriesScriptCount(
        uint256 _seriesId
    ) external view returns (
        uint256
    );

    function getSeriesScriptAtIndex(
        uint256 _seriesId,
        uint256 _scriptIndex
    ) external view returns (
        string memory
    );

    function getSeriesTokenURI(
        uint256 _seriesId
    ) external view returns (
        string memory
    );

    function isSeriesStatus(
        uint256 _seriesId,
        SeriesStatus _status
    ) external view returns (
        bool
    );

    function isSeriesCreator(
        uint256 _seriesId,
        address _creatorAddress
    ) external view returns (
        bool
    );

    function getCreatorPlatformPercent(
        address _creatorAddress
    ) external view returns (
        uint
    );

    function getSeriesPlatformPercent(
        uint256 _seriesId
    ) external view returns (
        uint
    );

    function getSeriesSecondPayeeInformation(
        uint256 _seriesId
    ) external view returns (
        address _secondPayeeAddress,
        uint _secondPayeePercent
    );

    function getSeriesMintInformation(
        uint256 _seriesId
    ) external view returns (
        uint256 _totalMinted,
        uint256 _maxSupply
    );

    function getSeriesPriceInWei(
        uint256 _seriesId
    ) external view returns (
        uint256
    );

    function getSeriesOnePerWallet(
        uint256 _seriesId
    ) external view returns (
        bool
    );

    function getTotalTokensMinted(
    )
    external view returns (
        uint256
    );
}