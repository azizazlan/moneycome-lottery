// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Counters.sol";

contract Governance {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdCounter;

    uint256 public oneTime;
    address public keeperCompatibleDraw;
    address public vrfConsumerDraw;

    constructor() {
        _tokenIdCounter.increment();
        oneTime = _tokenIdCounter.current();
    }

    function init(address keeperCompatibleDrawAddr, address vrfConsumerDrawAddr)
        public
    {
        require(vrfConsumerDrawAddr != address(0), "no vrfConsumerDrawAddr");
        require(
            keeperCompatibleDrawAddr != address(0),
            "no keeperCompatibleDrawAddr"
        );
        require(oneTime > 0, "only call once");

        keeperCompatibleDraw = keeperCompatibleDrawAddr;
        vrfConsumerDraw = vrfConsumerDrawAddr;

        _tokenIdCounter.decrement();
        oneTime = _tokenIdCounter.current();
    }
}
