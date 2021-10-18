// SPDX-License-Identifier: MEH

pragma solidity ^0.8.0;

interface ISeriesDataType {
    
    enum SeriesStatus {
        Uninitialized,
        Ready,
        Active,
        Paused,
        Locked,
        Delisted
    }

    struct Series {
        string name;
        string description;
        address creatorAddress;
        uint platformPercentage;
        address secondPayeeAddress;
        uint secondPayeePercentage;
        address currencyContract;
        string currencySymbol;
        uint256 totalMinted;
        uint256 maxSupply;
        uint256 priceInWei;
        bool onePerWallet;
        string[] scripts;
        string scriptConfig;
        string tokenURI;
        SeriesStatus status;
    }
}