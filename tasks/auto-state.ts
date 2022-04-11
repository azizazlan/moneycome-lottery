import { task } from 'hardhat/config';

task('autoresult', 'Get the bet state')
  .addParam('cycles', 'Number sessions')
  .setAction(async (taskArgs, hre) => {
    const { ethers } = hre;
    const contractAddr = `${process.env.UPKEEP_CONTRACT_ADDR}`;

    const contract = (
      await ethers.getContractFactory('KeeperCompatibleDraw')
    ).attach(contractAddr);

    let cycles = taskArgs.cycles;
    while (cycles > 0) {
      const tx = await contract.startNewDraw(9); //9 seconds
      await tx.wait();

      const drawId = await contract.s_drawId();
      console.log(`Start new draw ${drawId}`);

      let s = 0;
      while (s === 0 || s === 2 || s === 3) {
        s = ethers.BigNumber.from(await contract.s_drawState()).toNumber();
      }

      const i: number = ethers.BigNumber.from(
        await contract.s_drawId(),
      ).toNumber();
      let first = await contract.s_drawIdWinningDraw(
        ethers.BigNumber.from(i),
        0,
      );
      let second = await contract.s_drawIdWinningDraw(
        ethers.BigNumber.from(i),
        1,
      );
      let third = await contract.s_drawIdWinningDraw(
        ethers.BigNumber.from(i),
        2,
      );

      console.log('\t', first);
      console.log('\t', second);
      console.log('\t', third);
      cycles--;
    }
  });

export default {};
