import dotenv from 'dotenv';
import { task, HardhatUserConfig } from 'hardhat/config';
import '@nomiclabs/hardhat-etherscan';
import '@nomiclabs/hardhat-waffle';
import '@nomiclabs/hardhat-ethers';
import 'hardhat-gas-reporter';
import 'hardhat-deploy';
import { utils } from 'ethers';

dotenv.config();

const chainIds = {
  mainnet: 1,
  ropsten: 3,
  rinkeby: 4,
  goerli: 5,
  kovan: 42,
  polygon: 137,
  ganache: 1337,
  hardhat: 31337,
  mumbai: 80001,
};

const defaultNetwork = 'hardhat';

const VERBOSE = false;

const INFURA_API_KEY = process.env.INFURA_API_KEY;
const ALCHEMY_MUMBAI_API_KEY = process.env.ALCHEMY_MUMBAI_API_KEY;
const ALCHEMY_MATIC_API_KEY = process.env.ALCHEMY_MATIC_API_KEY;
const PRIVATE_KEY = process.env.PRIVATE_KEY;

task('accounts', 'Prints the list of available ETH accounts:', async (args, hre) => {
  const accounts = await hre.ethers.getSigners();
  for (const account of accounts) {
    const address = await account.address;
    console.log(
      address,
      (
        BigInt((await hre.ethers.provider.getBalance(address)).toString()) / BigInt(1e18)
      ).toString() + 'ETH',
    );
  }
});

task('networks', 'Prints the configured ETH network settings:', async (args, hre) => {
  if (VERBOSE) {
    console.log(`Available Networks:`);
    console.log(hre['config']['networks']);
  } else {
    Object.keys(chainIds).forEach((k) => {
      console.log(`Network ${k}`);
      console.log(hre['config']['networks'][`${k}`]);
    });
  }
});

const hardhatConfig: HardhatUserConfig = {
  defaultNetwork,
  networks: {
    hardhat: {
      allowUnlimitedContractSize: true,
      chainId: 31337,
      blockGasLimit: 30_000_000,
      accounts: {
        mnemonic: 'aunt rule simple minor aware math lecture moon vintage clap earth machine crack mirror upgrade',
        count: 5,
        accountsBalance: utils.parseEther('100000').toString()
      }
    },
    rinkeby: {
      url: 'https://rinkeby.infura.io/v3/' + INFURA_API_KEY,
      gasPrice: 50000000000,
      accounts: [PRIVATE_KEY || ''],
    },
    kovan: {
      url: 'https://kovan.infura.io/v3/' + INFURA_API_KEY,
      gasPrice: 50000000000,
      accounts: [PRIVATE_KEY || ''],
    },
    mainnet: {
      url: 'https://mainnet.infura.io/v3/' + INFURA_API_KEY,
      gasPrice: 50000000000,
      accounts: [PRIVATE_KEY || ''],
    },
    mumbai: {
      allowUnlimitedContractSize: true,
      url: 'https://polygon-mumbai.g.alchemy.com/v2/' + ALCHEMY_MUMBAI_API_KEY,
      accounts: [PRIVATE_KEY || ''],
    },
    matic: {
      allowUnlimitedContractSize: true,
      url: 'https://polygon-mainnet.g.alchemy.com/v2/' + ALCHEMY_MATIC_API_KEY,
      accounts: [PRIVATE_KEY || ''],
    },
  },
  namedAccounts: {
    deployer: {
      default: 0,
    },
    feeCollector: {
      default: 0,
    },
  },
  solidity: {
    compilers: [
      {
        version: '0.8.13',
        settings: {
          metadata: {
            /* Not including the metadata hash
            https://github.com/paulrberg/solidity-template/issues/31 */
            bytecodeHash: 'none',
          },
          /* You should disable the optimizer when debugging
          https://hardhat.org/hardhat-network/#solidity-optimizer-support */
          optimizer: {
            enabled: true,
            runs: 800,
          },
        },
      },
      { version: '0.6.0' },
    ],
  },
  mocha: {
    bail: true,
    timeout: 6000,
  },
  gasReporter: {
    currency: 'USD',
    enabled: !!process.env.REPORT_GAS,
    showTimeSpent: true,
  },
  etherscan: {
    apiKey: `${process.env.ETHERSCAN_API_KEY}`,
  },
  paths: {
    sources: './contracts',
    artifacts: './artifacts',
    cache: './cache',
    tests: './test',
  },
};

export default hardhatConfig;
