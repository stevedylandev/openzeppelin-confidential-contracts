import dotenv from "dotenv";
import "@nomicfoundation/hardhat-chai-matchers";
import "@nomicfoundation/hardhat-ethers";
import "hardhat-gas-reporter";
import "hardhat-ignore-warnings";
import "solidity-coverage";

import { HardhatUserConfig } from "hardhat/config";

import "./hardhat/provider";
import "./hardhat/testEnvironment";
import "./hardhat/coverage";

dotenv.config();

const config: HardhatUserConfig = {
  solidity: {
    version: "0.8.29",
    settings: {
      optimizer: {
        enabled: true,
        runs: 200,
      },
      evmVersion: "cancun",
    },
  },
  networks: {
    hardhat: {
      accounts: {
        count: 10,
        mnemonic: process.env.MNEMONIC,
        path: "m/44'/60'/0'/0",
      },
    },
  },
  namedAccounts: {
    deployer: 0,
  },
  gasReporter: {
    currency: "USD",
    enabled: !!process.env.REPORT_GAS,
    excludeContracts: [],
    src: "./contracts",
  },
  etherscan: {
    apiKey: process.env.ETHERSCAN_API_KEY,
  },
  typechain: {
    outDir: "types",
    target: "ethers-v6",
  },
};

export default config;
