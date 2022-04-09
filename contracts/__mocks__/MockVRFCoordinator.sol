//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";

contract MockVRFCoordinator {
    function requestRandomWords(
        bytes32,
        uint64,
        uint16,
        uint32,
        uint32
    ) external returns (uint256 requestId) {
        VRFConsumerBaseV2 consumer = VRFConsumerBaseV2(msg.sender);
        uint256[] memory randomWords = new uint256[](3);
        randomWords[
            0
        ] = 65237367840995691791037444202571953548149283008744462358132421008753727641639; // 1638
        randomWords[
            1
        ] = 69718720022744266635288021941284383327431551282589957548486363367314376140960; // 959
        randomWords[
            2
        ] = 90574700480603757870434099306867474662467717804341916486748550723967215698377; // 8376
        consumer.rawFulfillRandomWords(requestId, randomWords);
    }
}
