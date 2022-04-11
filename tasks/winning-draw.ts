import { task } from 'hardhat/config';

task('result', 'Get the winning digits').setAction(async (taskArgs, hre) => {
  const { ethers } = hre;
  const contractAddr = `${process.env.UPKEEP_CONTRACT_ADDR}`;

  const contract = (
    await ethers.getContractFactory('KeeperCompatibleDraw')
  ).attach(contractAddr);

  const i: number = ethers.BigNumber.from(await contract.s_drawId()).toNumber();
  let first = await contract.s_drawIdWinningDraw(ethers.BigNumber.from(i), 0);
  let second = await contract.s_drawIdWinningDraw(ethers.BigNumber.from(i), 1);
  let third = await contract.s_drawIdWinningDraw(ethers.BigNumber.from(i), 2);

  console.log(first);
  console.log(second);
  console.log(third);
});

export default {};
