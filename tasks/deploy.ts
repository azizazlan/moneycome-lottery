import { task } from 'hardhat/config';

task('deploy', 'Deploy Bet smart contract').setAction(async (taskArgs, hre) => {
  const { ethers } = hre;

  // Governance
  console.log('Deploying Governance contract...');
  const GovernanceContractFactory = await ethers.getContractFactory(
    'Governance',
  );
  const governance = await GovernanceContractFactory.deploy();
  console.log(`Governance deployed at ${governance.address}`);

  // VRFConsumerLotteryFactory
  const vrfCoordinatorContractAddr = `${process.env.CHAINLINK_VRF_COORDINATOR_ADDR}`;
  const linkAddr = `${process.env.CHAINLINK_LINK_ADDR}`;
  const subscriptionId = `${process.env.CHAINLINK_VRF_SID}`;
  console.log(
    `\nDeploying VRFConsumerV2 contract that uses Subscription Id ${subscriptionId} ...`,
  );
  const VRFConsumerDrawFactory = await ethers.getContractFactory(
    'VRFConsumerDraw',
  );
  const vrf = await VRFConsumerDrawFactory.deploy(
    vrfCoordinatorContractAddr,
    linkAddr,
    subscriptionId,
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
  await tx.wait();
});

export default {};
