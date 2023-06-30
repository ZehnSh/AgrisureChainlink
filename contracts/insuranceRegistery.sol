// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

import "./Libraries/LibCalculations.sol";
import "./chainLinkWeatherData.sol";

contract insuranceRegistery is ReentrancyGuard {
    using Counters for Counters.Counter;
    uint256 public InsuranceId;
    address public chainLinkWeatherDataAddress;

    struct insuranceData {
        address userWalletAddress;
        uint256 startDate;
        uint256 maturityDate;
        uint256 periodTime;
        uint256 areaOfLand;
        string seedsData;
        uint256 seedQuantity;
        string image;
        string yourAddress;
        uint256 Amount;
        uint16 percent;
    }

    // InsuranceId => insuranceData
    mapping(uint256 => insuranceData) public insuranceDetails;

    // InsuranceId => installment
    mapping(uint256 => uint8) public paidInstallments;

    // InsuranceId => block.timestamp
    mapping(uint256 => uint256) public lastInstallmentPaidTimestump;

    // userAddress => InsuranceIds
    mapping(address => uint256[]) public userInsurances;

    event insuranceRegistered(uint256 InsuranceId, uint256 amount);

    event Claimed(uint256 InsuranceId, string massage, uint256 amount);

    constructor(address _chainLinkWeatherData) {
        chainLinkWeatherDataAddress = _chainLinkWeatherData;
    }

    function insuranceRegister(insuranceData memory _insuranceData)
        external
        returns (uint256 _insuranceId)
    {
        require(msg.sender != address(0), "Fake Address");

        _insuranceId = ++InsuranceId;

        insuranceDetails[_insuranceId] = _insuranceData;

        userInsurances[msg.sender].push(_insuranceId);

        emit insuranceRegistered(_insuranceId, _insuranceData.Amount);
    }

    function payInstallment(address ERC20Address, uint256 _insuranceId)
        external
        nonReentrant
    {
        insuranceData memory details = insuranceDetails[_insuranceId];
        require(
            details.userWalletAddress == msg.sender,
            "This is not your Insurance"
        );
        require(
            ERC20Address != address(0),
            "you can't do this with zero address"
        );

        require(
            details.startDate + details.maturityDate <= block.timestamp,
            "your maturity Date is over"
        );

        paidInstallments[_insuranceId]++;
        lastInstallmentPaidTimestump[_insuranceId] = block.timestamp;

        require(
            IERC20(ERC20Address).transferFrom(
                msg.sender,
                address(this),
                details.Amount
            ),
            "Unable to tansfer Fund"
        );
    }

    function claim(
        address ERC20Address,
        uint256 _insuranceId,
        string memory image,
        string memory date
    ) external nonReentrant {
        require(
            lastInstallmentPaidTimestump[_insuranceId] < block.timestamp,
            "You are claiming at wrong timestamp"
        );

        uint256 windSpeed = chainLinkWeatherData(chainLinkWeatherDataAddress).getWindSpeedData();
        uint256 RainFall = chainLinkWeatherData(chainLinkWeatherDataAddress).getRainData();

        if (windSpeed >= 45 && RainFall >=300) {
            insuranceData memory details = insuranceDetails[_insuranceId];
            uint256 percent = LibCalculations.percent(
                details.Amount,
                details.percent
            );
            require(
                details.userWalletAddress == msg.sender,
                "This is not your Insurance"
            );
            require(
                ERC20Address != address(0),
                "you can't do this with zero address"
            );
            require(
                IERC20(ERC20Address).transferFrom(
                    msg.sender,
                    address(this),
                    details.Amount + percent
                ),
                "Unable to tansfer Fund"
            );
            emit Claimed(_insuranceId, "success", details.Amount + percent);
        } else {
            emit Claimed(_insuranceId, "unsuccess", 0);
        }
    }
}
