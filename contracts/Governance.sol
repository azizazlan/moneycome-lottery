// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/utils/Counters.sol';

contract Governance {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdCounter;

    uint256 public oneTime;
    address public lotteryKeeper;
    address public vrfConsumerLottery;

    constructor() {
        _tokenIdCounter.increment();
        oneTime = _tokenIdCounter.current();
    }

    function init(
        address lotteryKeeperAddress,
        address vrfConsumerLotteryAddress
    ) public {
        require(
            vrfConsumerLotteryAddress != address(0),
            'no governance/vrfConsumerLottery'
        );
        require(
            lotteryKeeperAddress != address(0),
            'no-lottery-keeper-address-given'
        );
        require(oneTime > 0, 'can-only-be-called-once');

        lotteryKeeper = lotteryKeeperAddress;
        vrfConsumerLottery = vrfConsumerLotteryAddress;

        _tokenIdCounter.decrement();
        oneTime = _tokenIdCounter.current();
    }
}
