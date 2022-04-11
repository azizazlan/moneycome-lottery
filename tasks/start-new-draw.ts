import { task } from 'hardhat/config';

task('start', 'Initialise new bet session')
  .addParam('duration', 'Duration in seconds of this bet session')
  .setAction(async (taskArgs, hre) => {
    enum DRAW_STATE {
      OPEN,
      CLOSED,
      RANDOM,
      CLAIM,
    }

    const { ethers } = hre;
    const contractAddr = `${process.env.UPKEEP_CONTRACT_ADDR}`;
    const duration = taskArgs.duration;

    const contract = (
      await ethers.getContractFactory('KeeperCompatibleDraw')
    ).attach(contractAddr);
    const tx = await contract.startNewDraw(duration);
    await tx.wait();
    console.log(DRAW_STATE[await contract.s_drawState()]);
  });

export default {};
