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
    Counters.Counter private s_drawIdCounter;
    // latest draw id uint256 public s_DrawId;
    uint256 public s_drawId;
    enum DRAW_STATE {
        OPEN,
        CLOSED,
        RANDOM,
        CLAIM
    }
    DRAW_STATE public s_drawState;

    mapping(uint256 => uint256) public s_requestIdDrawId;
    mapping(uint256 => uint256[]) public s_drawIdWinningDraw;

    struct Player {
        uint256 amountBet;
        uint256 digits;
        uint256 drawId;
    }
    mapping(address => Player) public s_players;

    // minimum bet is .00015 ETH
    uint256 public MINIMUM_BET = 0.00015 * 10**18;

    // Prizes - value chosen arbitrarily
    uint256 public FIRST_PRIZE = 0.15 * 10**18;
    uint256 public SECOND_PRIZE = 0.05 * 10**18;
    uint256 public THIRD_PRIZE = 0.025 * 10**18;

    uint256 public immutable s_upkeepInterval;
    uint256 public s_lastTimeStamp;
    uint256 public s_expiredTimeStamp;
    uint256 public s_claimExpiredTimeStamp;
    uint256 public s_drawDuration;

    IGovernance public s_iGovernance;

    constructor(uint256 upkeepInterval, address govInterfaceAddress) {
        s_upkeepInterval = upkeepInterval;
        s_iGovernance = IGovernance(govInterfaceAddress);

        s_drawState = DRAW_STATE.CLOSED;
        s_lastTimeStamp = block.timestamp;
        s_expiredTimeStamp = block.timestamp;
        s_claimExpiredTimeStamp = block.timestamp;

        s_drawId = s_drawIdCounter.current();
        s_drawIdCounter.increment();
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
        require(s_drawState == DRAW_STATE.CLOSED, "Incorrect state");
        s_drawState = DRAW_STATE.OPEN;
        s_drawDuration = duration;
        s_expiredTimeStamp = block.timestamp + duration;

        s_drawId = s_drawIdCounter.current();
        s_drawIdCounter.increment();

        emit NewDraw(s_drawId);
    }

    /// Play the lottery
    /// @param digits are the four digits entered by player
    function play(uint256 digits) public payable {
        require(!hasPlayerPlacedBet(msg.sender), "Only allow play once");
        require(msg.value >= MINIMUM_BET, "Insufficient bet amount");
        require(s_drawState == DRAW_STATE.OPEN, "Incorrect state");

        s_players[msg.sender].amountBet = msg.value;
        s_players[msg.sender].digits = digits;
        s_players[msg.sender].drawId = s_drawId;

        emit Staked(msg.sender, msg.value, digits);
    }

    function claim() public {
        require(s_drawState == DRAW_STATE.CLAIM, "Incorrect state");
        require(hasPlayerPlacedBet(msg.sender), "Only claim once");
        require(hasPlayerWon(msg.sender), "Player lost");

        uint256 prize;
        uint256 userDigits = s_players[msg.sender].digits;

        if (userDigits == s_drawIdWinningDraw[s_drawId][0]) {
            prize = FIRST_PRIZE;
        }
        if (userDigits == s_drawIdWinningDraw[s_drawId][1]) {
            prize = SECOND_PRIZE;
        }
        if (userDigits == s_drawIdWinningDraw[s_drawId][2]) {
            prize = THIRD_PRIZE;
        }

        (bool success, ) = msg.sender.call{value: prize}("");

        require(success, "Transfer failed");

        // clean up
        delete s_players[msg.sender];

        emit GainsClaimed(msg.sender, prize);
    }

    function hasPlayerPlacedBet(address playerAddress)
        public
        view
        returns (bool)
    {
        return s_players[playerAddress].drawId == s_drawId;
    }

    function hasPlayerWon(address playerAddress) public view returns (bool) {
        uint256 userDigits = s_players[playerAddress].digits;

        // Player won when his numbers match any of the first, second or third prize number
        if (
            userDigits == s_drawIdWinningDraw[s_drawId][0] ||
            userDigits == s_drawIdWinningDraw[s_drawId][1] ||
            userDigits == s_drawIdWinningDraw[s_drawId][2]
        ) {
            return true;
        }
        return false;
    }

    function pickWinningDraw() private {
        require(s_drawState == DRAW_STATE.RANDOM, "Incorrect state");

        uint256 requestId = IVRFConsumerDraw(s_iGovernance.vrfConsumerDraw())
            .requestWinningDraw();

        s_requestIdDrawId[requestId] = s_drawId;
    }

    function setWinningDraw(uint256 requestId, uint256[] memory winningDraw)
        external
    {
        require(s_drawState == DRAW_STATE.RANDOM, "Incorrect state");

        uint256 drawId = s_requestIdDrawId[requestId];

        // Reduce to 4 digits of random number in a range from 1 to 9999.
        //There are three winning prizes; first, second and third place.
        uint256 fourdigits = (winningDraw[0] % 10000) - 1;
        s_drawIdWinningDraw[drawId].push(fourdigits);

        fourdigits = (winningDraw[1] % 10000) - 1;
        s_drawIdWinningDraw[drawId].push(fourdigits);

        fourdigits = (winningDraw[2] % 10000) - 1;
        s_drawIdWinningDraw[drawId].push(fourdigits);

        s_drawState = DRAW_STATE.CLAIM;

        // claimng session's duration is twice longer than betting session
        s_claimExpiredTimeStamp =
            block.timestamp +
            s_drawDuration +
            s_drawDuration;

        emit DrawAnnounced(drawId, winningDraw);
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
        upkeepNeeded = (block.timestamp - s_lastTimeStamp) > s_upkeepInterval;
    }

    function performUpkeep(
        bytes calldata /* performData */
    ) external override {
        //We highly recommend revalidating the upkeep in the performUpkeep function
        if ((block.timestamp - s_lastTimeStamp) > s_upkeepInterval) {
            s_lastTimeStamp = block.timestamp;
        }
        if (
            s_lastTimeStamp > s_expiredTimeStamp &&
            s_drawState == DRAW_STATE.OPEN
        ) {
            s_drawState = DRAW_STATE.RANDOM;
            pickWinningDraw();
        }
        if (
            s_lastTimeStamp > s_claimExpiredTimeStamp &&
            s_drawState == DRAW_STATE.CLAIM
        ) {
            s_drawState = DRAW_STATE.CLOSED;
        }
    }
}
