# TestCoin
Test repository for a Solidity-based blockchain token.

# Requirements
* [Metamask](https://metamask.io)

# How to deploy
* [Download Metamask](https://metamask.io) from their official page.
* Start a new wallet.
* Go to [Binance's Connecting Metamask to Binance Smart Chain article](https://academy.binance.com/es/articles/connecting-metamask-to-binance-smart-chain).
* For testing purposes, we recommend using Testnet.
```
Testnet
Network Name: Smart Chain - Testnet
New RPC URL: https://data-seed-prebsc-1-s1.binance.org:8545/
ChainID: 97
Symbol: BNB
Block Explorer URL: https://testnet.bscscan.com/
```
* Go to Metamask settings and add a new network using the values from the previous article.
* When using Binance's testnet, go to [Binance's account funding](https://testnet.binance.org/faucet-smart) to obtain free BNB. Copy your account hash to fund it.
* Navigate to [Ethereum's compiler](https://remix.ethereum.org)
* Create a new workspace.
* In the newly made workspace, add a new .sol file with whatever name you opt for.
* Copy our contract and modify it as desired.
* Compile the project.
* Go to "Deploy and Run Transactions".
* Choose Injected Web3 as Environment and input your account hash.
* Select your contract file and deploy!
* Confirm your deployment on Metamask.

That's it! You can begin trading now!

# Confirm transactions
* Navigate to [BscScan's testnet](https://testnet.bscscan.com).
* Look up the contract address and verify the information is accurate.



# Built using
- Solidity
- Metamask
- Ethereum
