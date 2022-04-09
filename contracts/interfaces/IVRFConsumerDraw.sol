// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

interface IVRFConsumerDraw {
    function requestWinningDraw() external returns (uint256);
}
