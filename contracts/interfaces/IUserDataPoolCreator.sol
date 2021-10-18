// SPDX-License-Identifier: MEH

pragma solidity ^0.8.0;

import "./ICreatorDataType.sol";

interface IUserDataPoolCreator is ICreatorDataType {

    function isAdmin(
        address _by
    ) external view returns (bool);

    function addCreator(
        address _creatorAddress,
        string memory _name,
        uint _platformPercentage,
        uint _remainingInvitations,
        address _invitedBy,
        CreatorStatus _status
    ) external;

    function updateCreatorName(
        address _creatorAddress,
        string memory _name
    ) external;

    function updateCreatorInvitations(
        address _creatorAddress,
        address _invitationAddress,
        uint _remainingInvitations
    ) external;

    function updateCreatorRemainingInvitations(
        address _creatorAddress,
        uint _remainingInvitations
    ) external;
    
    function addCreatorTokensMinted(
        address _creatorAddress
    ) external;

    function updateCreatorStatus(
        address _creatorAddress,
        CreatorStatus _status
    ) external;

    function isCreatorStatus(
        address _creatorAddress,
        CreatorStatus _status
    ) external view returns (
        bool
    );

    function getCreator(
        address _creatorAddress
    ) external view returns (
        Creator memory
    );

    function getCreatorRemainingInvites(
        address _creatorAddress
    ) external view returns (
        uint
    );

    function getCreatorInvites(
        address _creatorAddress
    ) external view returns (
        address[] memory
    );

    function getCreatorSeriesIds(
        address _creatorAddress
    ) external view returns (
        uint256[] memory
    );

    function getDefaultPlatformPercent(
    ) external view returns (
        uint
    );

    function getDefaultInvitations(
    ) external view returns (
        uint
    );
}