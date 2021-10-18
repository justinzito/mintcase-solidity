// SPDX-License-Identifier: MEH

pragma solidity ^0.8.0;

import "./interfaces/IUserDataPoolCreator.sol";
import "./interfaces/ICreatorDataType.sol";
import "./oz/Ownable.sol";
import "./oz/SafeMath.sol";

contract CreatorController is Ownable, ICreatorDataType {
    using SafeMath for uint256;

    event CreatorUpdated(address _creatorAddress);

    address dataPoolAddress;

    modifier onlyActiveCreatorOrAdmin() {

        require(
            IUserDataPoolCreator(
                dataPoolAddress
            ).isCreatorStatus(_msgSender(), CreatorStatus.Active) || 
            IUserDataPoolCreator(
                dataPoolAddress
            ).isAdmin(_msgSender()),
            "No access."
        );
        _;
    }

    constructor(address _dataPoolAddress) {
        dataPoolAddress = _dataPoolAddress;
    }

    function updateDataPoolAddress(address _dataPoolAddress) external onlyOwner() {
        dataPoolAddress = _dataPoolAddress;
    }

    function inviteCreator(
        address _invitationAddress
    ) external onlyActiveCreatorOrAdmin() {

        uint remainingInvites = IUserDataPoolCreator(
                dataPoolAddress
            ).getCreatorRemainingInvites(_msgSender());
        require (
            remainingInvites > 0,
            "No invites remain."
        );

        require(
            IUserDataPoolCreator(
                dataPoolAddress
            ).isCreatorStatus(_invitationAddress,CreatorStatus.NotInvited),
            "Creator already invited."
        );

        remainingInvites = remainingInvites.sub(1);

        IUserDataPoolCreator(
            dataPoolAddress
        ).updateCreatorInvitations(
            _msgSender(),
            _invitationAddress,
            remainingInvites
        );
        
        IUserDataPoolCreator(
            dataPoolAddress
        ).addCreator(
            _invitationAddress,
            "",
            IUserDataPoolCreator(
            dataPoolAddress
            ).getDefaultPlatformPercent(),
            IUserDataPoolCreator(
            dataPoolAddress
            ).getDefaultInvitations(),
            _msgSender(),
            CreatorStatus.Invited
        );

        emit CreatorUpdated(_msgSender());
    }

    function redeemInvitation(
        string memory _name
    ) external {
        require(
            IUserDataPoolCreator(
                dataPoolAddress
            ).isCreatorStatus(_msgSender(),CreatorStatus.Invited),
            "Not Invited."
        );

        IUserDataPoolCreator(
            dataPoolAddress
        ).updateCreatorName(_msgSender(),_name);

        IUserDataPoolCreator(
            dataPoolAddress
        ).updateCreatorStatus(_msgSender(),CreatorStatus.Active);


        emit CreatorUpdated(_msgSender());
    }

    function updateCreatorName(
        string memory _name
    ) external onlyActiveCreatorOrAdmin() {

        IUserDataPoolCreator(
            dataPoolAddress
        ).updateCreatorName(_msgSender(),_name);

        emit CreatorUpdated(_msgSender());
    }

    function deactivateAccount(
    ) external onlyActiveCreatorOrAdmin() {

        IUserDataPoolCreator(
            dataPoolAddress
        ).updateCreatorStatus(_msgSender(),CreatorStatus.Inactive);
        
        emit CreatorUpdated(_msgSender());
    }
}