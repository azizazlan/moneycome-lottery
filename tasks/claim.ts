import { task } from 'hardhat/config';

task('claim', 'Claim the reward').setAction(async (taskArgs, hre) => {
  const { ethers } = hre;
  const contractAddr = `${process.env.UPKEEP_CONTRACT_ADDR}`;
  const contract = (
    await ethers.getContractFactory('KeeperCompatibleDraw')
  ).attach(contractAddr);

  const accounts = await ethers.getSigners();
  const tx = await contract.connect(accounts[0]).claim();
  const receipt = await tx.wait();
  console.log(receipt);
  if (!receipt) return;
  if (!receipt.events) return;
  if (!receipt.events[0].args) return;
  console.log(receipt.events[0].args);
});

export default {};
