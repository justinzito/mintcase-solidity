// SPDX-License-Identifier: MEH

pragma solidity ^0.8.0;

interface ICreatorDataType {

    enum CreatorStatus {
        NotInvited,
        Invited,
        Active,
        Inactive,
        Banished
    }

    struct Creator {
        string name;
        uint platformPercentage;
        uint remainingInvitations;
        address invitedBy;
        address[] invitations;
        uint256[] seriesIds;
        uint256 totalSeriesTokensMinted;
        CreatorStatus status;
    }
}