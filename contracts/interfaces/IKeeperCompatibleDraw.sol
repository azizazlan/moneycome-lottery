// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

interface IKeeperCompatibleDraw {
    function setWinningDraw(uint256, uint256[] memory) external;
}
