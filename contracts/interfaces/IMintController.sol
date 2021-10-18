// SPDX-License-Identifier: MEH

pragma solidity ^0.8.0;

interface IMintController {

    function mint(
        uint256 _seriesId,
        address _to,
        address _by
    ) external;
}