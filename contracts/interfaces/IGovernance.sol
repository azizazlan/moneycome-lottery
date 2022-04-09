// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

interface IGovernance {
    function keeperCompatibleDraw() external view returns (address);

    function vrfConsumerDraw() external view returns (address);
}
