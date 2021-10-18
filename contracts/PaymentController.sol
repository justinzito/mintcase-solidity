// SPDX-License-Identifier: MEH

pragma solidity ^0.8.0;

import "./interfaces/IUserDataPoolSeries.sol";
import "./interfaces/ISeriesDataType.sol";
import "./interfaces/IMintController.sol";
import "./oz/Ownable.sol";
import "./oz/Address.sol";
import "./oz/SafeMath.sol";
import "./oz/ReentrancyGuard.sol";

contract PaymentController is Ownable, ReentrancyGuard {
    using SafeMath for uint256;
    using Address for address payable;

    event DepositProcessed(uint256 _seriesId, address _to, uint256 _amount);
    event Withdrawn(address indexed payee, uint256 weiAmount);

    address dataPoolAddress;
    address mintControllerAddress; 
    address treasuryAddress;

    mapping(address => uint256) private _deposits;

    constructor(address _dataPoolAddress, address _mintControllerAddress, address _treasuryAddress) {
        dataPoolAddress = _dataPoolAddress;
        mintControllerAddress = _mintControllerAddress;
        treasuryAddress = _treasuryAddress;
    }

    function updateMintControllerAddress(address _mintControllerAddress) external onlyOwner() {
        mintControllerAddress = _mintControllerAddress;
    }

    function updateTreasuryAddress(address _treasuryAddress) external onlyOwner() {
        treasuryAddress = _treasuryAddress;
    }

    function updateDataPoolAddress(address _dataPoolAddress) external onlyOwner() {
        dataPoolAddress = _dataPoolAddress;
    }

    function purchase(uint256 _seriesId) external payable nonReentrant() {
        uint256 amount = msg.value;

        uint256 priceInWei = IUserDataPoolSeries(
            dataPoolAddress
        ).getSeriesPriceInWei(_seriesId);

        require(
            amount >= priceInWei,
            "Invalid Price."
        );

        IMintController(
            mintControllerAddress
        ).mint(_seriesId, _msgSender(),_msgSender());
        
        splitPayment(_seriesId,amount);

    }

    function splitPayment(uint256 _seriesId, uint256 _value) internal {

        uint platformPercent = IUserDataPoolSeries(
            dataPoolAddress
        ).getSeriesPlatformPercent(_seriesId);

        uint256 remainingValue = _value;
        uint256 platformAmount = remainingValue * platformPercent / 1000;
        remainingValue = remainingValue.sub(platformAmount);
        _deposits[treasuryAddress] = _deposits[treasuryAddress].add(platformAmount);
        emit DepositProcessed(_seriesId,treasuryAddress,platformAmount);


        address secondPayeeAddress;
        uint secondPayeePercent;
        (secondPayeeAddress,secondPayeePercent) = IUserDataPoolSeries(
            dataPoolAddress
        ).getSeriesSecondPayeeInformation(_seriesId);

        if (secondPayeeAddress != address(0)) {
            uint256 secondPayeeAmount = remainingValue * secondPayeePercent / 1000;
            remainingValue = remainingValue.sub(secondPayeeAmount);
            _deposits[secondPayeeAddress] = _deposits[secondPayeeAddress].add(secondPayeeAmount);
            emit DepositProcessed(_seriesId,secondPayeeAddress,secondPayeeAmount);
        }

        address creatorAddress = IUserDataPoolSeries(
            dataPoolAddress
        ).getSeriesCreatorAddress(_seriesId);
        _deposits[creatorAddress] = _deposits[creatorAddress].add(remainingValue);
        emit DepositProcessed(_seriesId,creatorAddress,remainingValue);

    }

    function withdraw(address payable _payee) public virtual nonReentrant() {
        
        require(
            _payee == _msgSender(),
            "Only payee can withdrawal"
        );

        uint256 payment = _deposits[_payee];

        _deposits[_payee] = 0;

        _payee.sendValue(payment);
        
        emit Withdrawn(_payee, payment);
    }

    function depositsOf(address payee) public view returns (uint256) {
        return _deposits[payee];
    }
}