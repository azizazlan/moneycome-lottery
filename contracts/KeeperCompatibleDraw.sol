// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

// KeeperCompatible.sol imports the functions from both ./KeeperBase.sol and
// ./interfaces/KeeperCompatibleInterface.sol
import "@chainlink/contracts/src/v0.8/KeeperCompatible.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import {IVRFConsumerDraw} from "./interfaces/IVRFConsumerDraw.sol";
import {IGovernance} from "./interfaces/IGovernance.sol";

contract KeeperCompatibleDraw is KeeperCompatibleInterface {
    event NewDraw(uint256 indexed drawId);
    event GainsClaimed(address indexed claimant, uint256 prize);
    event Staked(address indexed player, uint256 value, uint256 digits);
    event DrawAnnounced(uint256 drawId, uint256[] winningDraw);

    using Counters for Counters.Counter;
    Counters.Counter private drawIdCounter;
    // latest draw id
    uint256 public drawId;

    enum DRAW_STATE {
        OPEN,
        CLOSED,
        RANDOM,
        CLAIM
    }
    DRAW_STATE public drawState;

    uint256 public s_requestId;
    uint256[] public s_randomWords;

    mapping(uint256 => uint256) public requestIdDrawId;
    mapping(uint256 => uint256[]) public drawIdWinningDraw;

    struct Player {
        uint256 amountBet;
        uint256 digits;
        uint256 drawId;
    }
    mapping(address => Player) public players;

    // minimum bet is .00015 ETH
    uint256 public MINIMUM_BET = 0.00015 * 10**18;

    // Prizes - value chosen arbitrarily
    uint256 public FIRST_PRIZE = 0.15 * 10**18;
    uint256 public SECOND_PRIZE = 0.05 * 10**18;
    uint256 public THIRD_PRIZE = 0.025 * 10**18;

    uint256 public immutable interval;
    uint256 public lastTimeStamp;
    uint256 public expiredTimeStamp;
    uint256 public claimExpiredTimeStamp;

    IGovernance public igov;

    constructor(uint256 upkeepInterval, address govInterfaceAddress) {
        interval = upkeepInterval;
        igov = IGovernance(govInterfaceAddress);

        drawState = DRAW_STATE.CLOSED;
        lastTimeStamp = block.timestamp;
        expiredTimeStamp = block.timestamp;
        claimExpiredTimeStamp = block.timestamp;

        drawId = drawIdCounter.current();
        drawIdCounter.increment();
    }

    receive() external payable {
        // Do something
    }

    function getContractBalance() public view returns (uint256) {
        return address(this).balance;
    }

    /// Initialise a new draw session
    /// @param duration in seconds for a new draw and claiming sessions
    function startNewDraw(uint256 duration) public {
        require(drawState == DRAW_STATE.CLOSED, "Incorrect state");
        drawState = DRAW_STATE.OPEN;
        expiredTimeStamp = block.timestamp + duration;

        drawId = drawIdCounter.current();
        drawIdCounter.increment();

        emit NewDraw(drawId);
    }

    /// Play the lottery
    /// @param digits are the four digits entered by player
    function play(uint256 digits) public payable {
        require(!hasPlayerPlacedBet(msg.sender), "Player already played");
        require(msg.value >= MINIMUM_BET, "Insufficient bet amount");
        require(drawState == DRAW_STATE.OPEN, "Incorrect state");

        players[msg.sender].amountBet = msg.value;
        players[msg.sender].digits = digits;
        players[msg.sender].drawId = drawId;

        emit Staked(msg.sender, msg.value, digits);
    }

    function claim() public {
        require(drawState == DRAW_STATE.CLAIM, "Incorrect state");
        require(hasPlayerPlacedBet(msg.sender), "Player not in list");
        require(hasPlayerWon(msg.sender), "Player lost");

        uint256 prize;
        uint256 userDigits = players[msg.sender].digits;

        if (userDigits == drawIdWinningDraw[drawId][0]) {
            prize = FIRST_PRIZE;
        }
        if (userDigits == drawIdWinningDraw[drawId][1]) {
            prize = SECOND_PRIZE;
        }
        if (userDigits == drawIdWinningDraw[drawId][2]) {
            prize = THIRD_PRIZE;
        }

        (bool success, ) = msg.sender.call{value: prize}("");

        require(success, "Transfer failed");

        // clean up
        delete players[msg.sender];

        emit GainsClaimed(msg.sender, prize);
    }

    function hasPlayerPlacedBet(address playerAddress)
        public
        view
        returns (bool)
    {
        return players[playerAddress].drawId == drawId;
    }

    function hasPlayerWon(address playerAddress) public view returns (bool) {
        uint256 userDigits = players[playerAddress].digits;

        // Player won when his numbers match any of the first, second or third prize number
        if (
            userDigits == drawIdWinningDraw[drawId][0] ||
            userDigits == drawIdWinningDraw[drawId][1] ||
            userDigits == drawIdWinningDraw[drawId][2]
        ) {
            return true;
        }
        return false;
    }

    function pickWinningDraw() private {
        require(drawState == DRAW_STATE.RANDOM, "Incorrect state");

        uint256 requestId = IVRFConsumerDraw(igov.vrfConsumerDraw())
            .requestWinningDraw();

        s_requestId = requestId;

        requestIdDrawId[requestId] = drawId;
    }

    function setWinningDraw(uint256 requestId, uint256[] memory winningDraw)
        external
    {
        require(drawState == DRAW_STATE.RANDOM, "Incorrect state");

        // draw id
        uint256 did = requestIdDrawId[requestId];

        // Reduce to 4 digits. There are three winning prizes; first, second and third place.
        uint256 fourdigits = (winningDraw[0] % 10000) - 1;
        drawIdWinningDraw[did].push(fourdigits);

        fourdigits = (winningDraw[1] % 10000) - 1;
        drawIdWinningDraw[did].push(fourdigits);

        fourdigits = (winningDraw[2] % 10000) - 1;
        drawIdWinningDraw[did].push(fourdigits);

        // START TESTING
        // uint256 first = 65237367840995691791037444202571953548149283008744462358132421008753727641639;
        // uint256 fourdigits = (first % 10000) - 1;
        // drawIdWinningDraw[did].push(fourdigits);

        // uint256 second = 69718720022744266635288021941284383327431551282589957548486363367314376140960;
        // fourdigits = (second % 10000) - 1;
        // drawIdWinningDraw[did].push(fourdigits);

        // uint256 third = 90574700480603757870434099306867474662467717804341916486748550723967215698377;
        // fourdigits = (third % 10000) - 1;
        // drawIdWinningDraw[did].push(fourdigits);
        // END TESTING

        s_randomWords = winningDraw;

        drawState = DRAW_STATE.CLAIM;

        // claimng session's duration is twice longer than betting session
        claimExpiredTimeStamp = block.timestamp + interval + interval;

        emit DrawAnnounced(did, winningDraw);
    }

    // Time KeeperCompatible functions

    function checkUpkeep(
        bytes calldata /* checkData */
    )
        external
        view
        override
        returns (
            bool upkeepNeeded,
            bytes memory /* performData */
        )
    {
        upkeepNeeded = (block.timestamp - lastTimeStamp) > interval;
    }

    function performUpkeep(
        bytes calldata /* performData */
    ) external override {
        //We highly recommend revalidating the upkeep in the performUpkeep function
        if ((block.timestamp - lastTimeStamp) > interval) {
            lastTimeStamp = block.timestamp;
        }
        if (lastTimeStamp > expiredTimeStamp && drawState == DRAW_STATE.OPEN) {
            drawState = DRAW_STATE.RANDOM;
            pickWinningDraw();
        }
        if (
            lastTimeStamp > claimExpiredTimeStamp &&
            drawState == DRAW_STATE.CLAIM
        ) {
            drawState = DRAW_STATE.CLOSED;
        }
    }
}
