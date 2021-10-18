// SPDX-License-Identifier: MEH

pragma solidity ^0.8.0;

interface ISeriesController {

    function attemptToMint(
        uint256 _seriesId,
        address _by
    ) external returns(
        bool,
        uint256
    );

    
}