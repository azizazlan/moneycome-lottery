// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

interface IGovernance {
    function lotteryKeeper() external view returns (address);

    function vrfConsumerLottery() external view returns (address);
}
