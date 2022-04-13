# juice-contracts-v2

## Modifications

Deployment script reworked to log deployments in the deployment directory under the network_name.json. Failed deployments, produce [error.log](https://gist.github.com/tankbottoms/9c33b8858cc3a91edfc5f562a30191c1) and are able to be restarted. On Ethereum mainnet or Rinkeby, contracts are verified after deployment. And Polygon Matic and Mumbai are additional deployment network targets. 

* [Rinkeby](https://gist.github.com/tankbottoms/9b7f8ddab948ec72c1a02b217e14cd1e)
* [Mumbai](https://gist.github.com/tankbottoms/21cb46a6a79e7cd53f7f958f81a613ea)
* [Polygon Matic](https://gist.github.com/tankbottoms/d359cbc096ec5674e099b2c251662e9c)

### Deployment 

Options to deploy are localhost, rinkeby, mainnet, mumbai, and matic.

```bash
npx hardhat run ./scripts/deploy.ts --network matic 
```

### Environment 

Usual API keys for Ethereum and Polygon.

```bash
INFURA_API_KEY= # https://docs.infura.io/infura/networks/ethereum/getting-started
ALCHEMY_MUMBAI_API_KEY= # https://docs.alchemy.com/alchemy/introduction/getting-started
ALCHEMY_MATIC_API_KEY= # https://docs.alchemy.com/alchemy/introduction/getting-started
PRIVATE_KEY= # without the 0x, your typical ETH/MATIC private key
ETHERSCAN_API_KEY= # https://docs.etherscan.io/getting-started/creating-an-account
REPORT_GAS=yes
```
---
## Develop

To deploy the contracts to a local blockchain, run the following:

```bash
yarn chain --network hardhat
```

To run tests:

```bash
yarn test
```

### Coverage

To check current test coverage:

```bash
node --require esm ./node_modules/.bin/hardhat coverage --network hardhat
```

A few notes:
* Hardhat doesn't support [esm](https://nodejs.org/api/esm.html) yet, hence running manually with node.
* We are currently using a forked version of [solidity-coverage](https://www.npmjs.com/package/solidity-coverage) that includes optimizer settings. Ideally we will move to the maintained version after this is fixed on their end.

## Deploy

Juicebox uses the [Hardhat Deploy](https://github.com/wighawag/hardhat-deploy) plugin to deploy contracts to a given network. But before using it, you must create a `./mnemonic.txt` file containing the mnemonic phrase of the wallet used to deploy. You can generate a new mnemonic using [this tool](https://github.com/itinance/mnemonics). Generate a mnemonic at your own risk.

Then, to execute the `./deploy/deploy.js` script, run the following:

```bash
npx hardhat deploy --network $network
```

Contract artifacts will be outputted to `./deployments/$network/**` and should be checked in to the repo.

## Verification

To verify the contracts on [Etherscan](https://etherscan.io), make sure you have an `ETHERSCAN_API_KEY` set in your `./.env` file. Then run the following:

```bash
npx hardhat --network $network etherscan-verify
```

This will verify all of the deployed contracts in `./deployments`.
