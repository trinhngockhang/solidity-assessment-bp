# Solidity assessment
## 1. How to deploy

### Set up ENV
`cp .env.example .env`

Change value in ENV as your params.
### Install library
`npm install`

### Create subcription in Chainlink
Since we use Chainlink v2, we need to register account and create subcription to use VRF service.

Follow Chainlink documentations and replace parameters: https://docs.chain.link/getting-started/intermediates-tutorial
### Run on Goerli
`npm run deploy-goerli`

## 2. A couple thoughts
### 2.1 What i have done
In this assigment, i have completed all the requirements about buying and refunding an NFT, also using Chainlink to get random factor.

I have a experienced with Chainlink oracle so it is not matter working with Chainlink. But i never deploy an upgradeable contract, so it take a little time to research, but finally it is working.

### 2.2 Future upgrade
* Unit test


The scope of this assignment is not required unit test, so i have not writed unit test yet. But i thing it will need a couple unit tests if it is used as a real product.

It could have a little trouble with ChainLink in unittest, but i think solotion is we could simulate ChainLink coordinator contract to use in local blockchain to test our contract.


* Handle chainlink failure

When chainlink callback to our fullfill random function, it could have some unexpected error in network. So i think it could some Backend mechanism to handle this failure.


# 3. How it work
## For user
First, user could use `requestNft` function to request minting an NFT and pay the fee, our contract would request a random number to Chainlink Oracle.

After finish, Chainlink would verify and call a callback function called `fulfillRandomWords` to return the random word, we would this to determine user could mint an NFT or not.

If user want to refund, they could use `refund` function to request refund

## For admin
Admin could change the price of NFT by function `setPriceNft`
# 4. Deployed contract

Sample contract is deployed in goerli network: https://goerli.etherscan.io/address/0x1f02919354e24E62c51b758E3bd25E3eBF20952c