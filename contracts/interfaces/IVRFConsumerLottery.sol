// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

interface IVRFConsumerLottery {
    function requestWinningDraw() external returns (uint256);
}
