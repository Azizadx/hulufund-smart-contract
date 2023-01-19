// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

import "@openzeppelin/contracts/utils/math/SafeMath.sol";

// import "./SafeDecimalMath.sol";

contract PriceConsumerV3 {
    using SafeMath for uint256;
    // using SafeDecimalMath for uint;

    AggregatorV3Interface internal priceFeed;

    /**
     * Network: Goerli
     * Aggregator: ETH/USD
     * Address: 0xD4a33860578De61DBAbDc8BFdb98FD742fA7028e
     */

    constructor() {
        priceFeed = AggregatorV3Interface(
            0xD4a33860578De61DBAbDc8BFdb98FD742fA7028e
        );
    }

    /**
     * Returns the latest price
     */
    function getLatestPrice() public view returns (int) {
        (
            ,
            /*uint80 roundID*/ int price /*uint startedAt*/ /*uint timeStamp*/ /*uint80 answeredInRound*/,
            ,
            ,

        ) = priceFeed.latestRoundData();
        return price;
    }

    function convertEthToUsd(uint ethAmount) public view returns (uint256) {
        int price = getLatestPrice();
        //    uint256(decodedOutput["0"]);

        return (ethAmount.mul(1e18).mul(uint256(price))).div(1e10);
    }

    function decoded() public view returns (uint256) {
        uint256 out = convertEthToUsd(1);
        return out;
    }

    // function convertUsdToEth(uint usdAmount) public view returns (uint256) {
    //     int price = getLatestPrice();
    //    uint x =  SafeDecimalMath.multiplyDecimalRoundPrecise(usdAmount,1e18);
    //    uint newPrice = uint256(price);
    //    uint value = SafeDecimalMath.divideDecimalRoundPrecise(x,newPrice);
    //     return value;
    // }
}
