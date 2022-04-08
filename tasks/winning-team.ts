import { task } from 'hardhat/config';

task('team', 'Get the winning team').setAction(async (taskArgs, hre) => {
  enum BET_STATE {
    OPEN,
    CLOSED,
    RANDOM,
    CLAIM,
  }

  const { ethers } = hre;
  const contract = `${process.env.VITE_BET_CONTRACT_ADDR}`;

  const bet = (await ethers.getContractFactory('Bet')).attach(contract);

  let i: number = ethers.BigNumber.from(await bet.betId()).toNumber();
  while (i > 0) {
    const team = await bet.betIdWinningTeam(ethers.BigNumber.from(i));
    console.log(
      `For bet id ${i} the winning team is Team ${ethers.BigNumber.from(
        team,
      ).toNumber()}`,
    );
    i--;
  }
});

export default {};
