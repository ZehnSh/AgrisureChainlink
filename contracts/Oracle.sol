// SPDX-License-Identifier: MIT
pragma solidity 0.8.18;

import "@chainlink/contracts/src/v0.8/ChainlinkClient.sol";
import "@chainlink/contracts/src/v0.8/ConfirmedOwner.sol";

/**
 * Request testnet LINK and ETH here: https://faucets.chain.link/
 * Find information on LINK Token Contracts and get the latest ETH and LINK faucets here: https://docs.chain.link/docs/link-token-contracts/
 */

/**
 * THIS IS AN EXAMPLE CONTRACT WHICH USES HARDCODED VALUES FOR CLARITY.
 * THIS EXAMPLE USES UN-AUDITED CODE.
 * DO NOT USE THIS CODE IN PRODUCTION.
 */

contract APIConsumer is ChainlinkClient, ConfirmedOwner {
    using Chainlink for Chainlink.Request;

    string apiURL = "https://history.openweathermap.org/data/2.5/history/city?";
    string apiKey = "b34a6b9c4842420f8cf851a4de5f4f6f";
    uint256 public windSpeed;
    uint256 public RainData;
    bytes32 private jobId;
    uint256 private fee;

    event RequestRain(bytes32 indexed requestId, uint256 Rain);
    event RequestWindSpeed(bytes32 indexed requestId, uint256 WindSpeed);
    event RequestFullfilled(uint requestNumber);
    /**
     * @notice Initialize the link token and target oracle
     *
     * Sepolia Testnet details:
     * Link Token: 0x779877A7B0D9E8603169DdbD7836e478b4624789
     * Oracle: 0x6090149792dAAeE9D1D568c9f9a6F6B46AA29eFD (Chainlink DevRel)
     * jobId: ca98366cc7314957b8c012c72f05aeeb
     *
     */
    constructor() ConfirmedOwner(msg.sender) {
        setChainlinkToken(0x326C977E6efc84E512bB9C30f76E30c160eD06FB);
        setChainlinkOracle(0x40193c8518BB267228Fc409a613bDbD8eC5a97b3);
        jobId = "ca98366cc7314957b8c012c72f05aeeb";
        fee = (1 * LINK_DIVISIBILITY) / 10; // 0,1 * 10**18 (Varies by network and job)
    }

    function requestWeatherData(
        string memory lat,
        string memory lon,
        string memory date,
        string memory hour
    ) external {
        requestRainData(lat, lon, date, hour);
        requestWindSpeed(lat, lon, date, hour);
    }

    /**
     * Create a Chainlink request to retrieve API response, find the target
     * data, then multiply by 1000000000000000000 (to remove decimal places from data).
     */
    function requestWindSpeed(
        string memory lat,
        string memory lon,
        string memory date,
        string memory hour
    ) internal returns (bytes32 requestId) {
        require(
            bytes(lat).length > 0 && bytes(lon).length > 0,
            "invalid lat lon input"
        );
        Chainlink.Request memory req = buildChainlinkRequest(
            jobId,
            address(this),
            this.fulfillWindspeed.selector
        );

        string memory api = concatAPI(lat, lon, date);

        // Set the URL to perform the GET request on
        req.add("get", api);

        //set the path with hour to get the data of that particular api

        // Set the path to find the desired data in the API response, where the response format is:
        req.add("path", concatPath("hourly,windspeed_100m,", hour)); // Chainlink nodes 1.0.0 and later support this format

        // Multiply the result by 1000000000000000000 to remove decimals
        int256 timesAmount = 10**18;
        req.addInt("times", timesAmount);

        // Sends the request
        return sendChainlinkRequest(req, fee);
    }

    /**
     * Create a Chainlink request to retrieve API response, find the target
     * data, then multiply by 1000000000000000000 (to remove decimal places from data).
     */
    function requestRainData(
        string memory lat,
        string memory lon,
        string memory date,
        string memory hour
    ) internal returns (bytes32 requestId) {
        require(
            bytes(lat).length > 0 && bytes(lon).length > 0,
            "invalid lat lon input"
        );
        Chainlink.Request memory req = buildChainlinkRequest(
            jobId,
            address(this),
            this.fulfillRainData.selector
        );

        string memory api = concatAPI(lat, lon, date);

        // Set the URL to perform the GET request on
        req.add("get", api);

        //set the path with hour to get the data of that particular api

        // Set the path to find the desired data in the API response, where the response format is:
        req.add("path", concatPath("hourly,rain,", hour)); // Chainlink nodes 1.0.0 and later support this format

        // Multiply the result by 1000000000000000000 to remove decimals
        int256 timesAmount = 10**18;
        req.addInt("times", timesAmount);

        // Sends the request
        return sendChainlinkRequest(req, fee);
    }

    /**
     * Receive the response in the form of uint256
     */
    function fulfillWindspeed(bytes32 _requestId, uint256 _windSpeed)
        public
        recordChainlinkFulfillment(_requestId)
    {
        emit RequestWindSpeed(_requestId, _windSpeed);
        windSpeed = _windSpeed;
    }

    /**
     * Receive the response in the form of uint256
     */
    function fulfillRainData(bytes32 _requestId, uint256 _rainData)
        public
        recordChainlinkFulfillment(_requestId)
    {
        emit RequestWindSpeed(_requestId, _rainData);
        RainData = _rainData;
    }

    // return the full api after concatenation of multiple strings
    // eg:- https://history.openweathermap.org/data/2.5/history/city?lat=41.85&lon=-87.65&appid=09e47741e90493c8b21bbbb66f7c59b1
    function concatAPI(
        string memory lat,
        string memory lon,
        string memory date
    ) internal pure returns (string memory) {
        return
            string(
                abi.encodePacked(
                    "https://archive-api.open-meteo.com/v1/archive?latitude=",
                    lat,
                    "&longitude=",
                    lon,
                    "&start_date=",
                    date,
                    "&end_date=",
                    date,
                    "&hourly=rain,windspeed_100m&daily=rain_sum,windspeed_10m_max&timezone=auto"
                )
            );
    }

    function concatPath(string memory path, string memory hour)
        internal
        pure
        returns (string memory)
    {
        return string(abi.encodePacked(path, hour));
    }

    /**
     * Allow withdraw of Link tokens from the contract
     */
    function withdrawLink() public onlyOwner {
        LinkTokenInterface link = LinkTokenInterface(chainlinkTokenAddress());
        require(
            link.transfer(msg.sender, link.balanceOf(address(this))),
            "Unable to transfer"
        );
    }
}
