import { task } from 'hardhat/config';

task('bet', 'Bet')
  .addParam('team', '1 or 2')
  .addParam('bet', 'in ether, for example 0.00015')
  .addParam('account', 'index account, example 0 is the first account')
  .setAction(async (taskArgs, hre) => {
    enum BET_STATE {
      OPEN,
      CLOSED,
      RANDOM,
      CLAIM,
    }

    const { ethers } = hre;
    const contract = `${process.env.VITE_BET_CONTRACT_ADDR}`;

    const accounts = await ethers.getSigners();

    const bet = (await ethers.getContractFactory('Bet')).attach(contract);

    const minBetAmountWei = await bet.MINIMUM_BET();

    const minBetAmount = ethers.utils.formatUnits(
      ethers.BigNumber.from(minBetAmountWei),
      18,
    );

    const userBet = taskArgs.bet;
    if (userBet < minBetAmount) {
      console.log(`Insufficient bet. Min bet is ${minBetAmount} ETH`);
      return;
    }
    const userBetWei = ethers.utils.parseUnits(userBet, 'ether');

    const accountIndex = taskArgs.account;
    if (accountIndex > accounts.length - 1) {
      console.log(
        `Account index ${accountIndex} does not exist. You have account index up to ${
          accounts.length - 1
        }`,
      );
      return;
    }

    const account = accounts[accountIndex];
    const balance = await account.getBalance();
    if (balance < minBetAmountWei) {
      console.log('Insufficient balance in the wallet');
      return;
    }

    const balanceEth = ethers.utils.formatEther(balance);
    if (balanceEth < userBet) {
      console.log(`You cannot bet more than the balance in your wallet`);
      return;
    }

    const team = taskArgs.team;
    if (team < 1 || team > 2) {
      console.log(`You can bet Team 1 or Team 2`);
      return;
    }
    const state = await bet.betState();

    if (state !== BET_STATE.OPEN) {
      console.log('Bet session close!');
      return;
    }

    const tx = await bet.connect(account).bet(team, { value: userBetWei });
    const receipt = await tx.wait();
    console.log(receipt);
  });

export default {};
