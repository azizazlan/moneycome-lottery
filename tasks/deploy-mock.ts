import { task } from 'hardhat/config';

task('mockdeploy', 'Deploy Bet smart contract').setAction(
  async (taskArgs, hre) => {
    const { ethers } = hre;

    // Governance
    console.log('Deploying Governance contract...');
    const GovernanceContractFactory = await ethers.getContractFactory(
      'Governance',
    );
    const governance = await GovernanceContractFactory.deploy();
    console.log(`Governance deployed at ${governance.address}`);

    const MockVRFCoordinatorFactory = await ethers.getContractFactory(
      'MockVRFCoordinator',
    );
    const mockVrfCoordinator = await MockVRFCoordinatorFactory.deploy();
    console.log(`MockVRFCoordinator ${mockVrfCoordinator.address}`);

    // VRFConsumerLotteryFactory
    const MOCK_SUBSCRIPTION_ID = '0';
    const MOCK_LINK = ethers.constants.AddressZero;
    const VRFConsumerDrawFactory = await ethers.getContractFactory(
      'VRFConsumerDraw',
    );
    const vrf = await VRFConsumerDrawFactory.deploy(
      mockVrfCoordinator.address,
      MOCK_LINK,
      MOCK_SUBSCRIPTION_ID,
      governance.address,
    );
    console.log(`VRF Consumer deployed at ${vrf.address}`);
    console.log(
      'Note: To add the consumer address at https://vrf.chain.link/new',
    );

    // Bet
    const upkeepInterval = `${process.env.UPKEEP_INTERVAL_SECS}`;
    console.log(
      `\nDeploying KeeperCompatibleDraw contract with upkeep interval of ${upkeepInterval} seconds ...`,
    );
    const KeeperCompatibleDrawFactory = await ethers.getContractFactory(
      'KeeperCompatibleDraw',
    );
    const keeper = await KeeperCompatibleDrawFactory.deploy(
      upkeepInterval,
      governance.address,
    );
    console.log(`Chainlink Upkeep deployed at ${keeper.address}`);
    console.log(
      `Register this new Upkeep contract at https://keepers.chain.link/chapel`,
    );

    console.log(`\nInit governanace...`);
    const tx = await governance.init(keeper.address, vrf.address);
    const receipt = await tx.wait();

    console.log(receipt);
  },
);

export default {};
