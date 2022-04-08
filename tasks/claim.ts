import { task } from 'hardhat/config';

task('claim', 'Claim the reward').setAction(async (taskArgs, hre) => {
  enum BET_STATE {
    OPEN,
    CLOSED,
    RANDOM,
    CLAIM,
  }

  const { ethers } = hre;
  const contract = `${process.env.VITE_BET_CONTRACT_ADDR}`;

  const bet = (await ethers.getContractFactory('Bet')).attach(contract);

  const accounts = await ethers.getSigners();
  const tx = await bet.connect(accounts[0]).claim();

  const receipt = await tx.wait();
  console.log(receipt);
});

export default {};
