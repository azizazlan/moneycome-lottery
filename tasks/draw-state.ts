import { task } from 'hardhat/config';

task('state', 'Get the bet state').setAction(async (taskArgs, hre) => {
  enum DRAW_STATE {
    OPEN,
    CLOSED,
    RANDOM,
    CLAIM,
  }

  const { ethers } = hre;
  const contractAddr = `${process.env.UPKEEP_CONTRACT_ADDR}`;

  const contract = (
    await ethers.getContractFactory('KeeperCompatibleDraw')
  ).attach(contractAddr);

  console.log(DRAW_STATE[await contract.drawState()]);
});

export default {};
