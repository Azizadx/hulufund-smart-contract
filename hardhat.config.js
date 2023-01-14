// require("@nomiclabs/hardhat-waffle")
require("hardhat-gas-reporter")
require("@nomiclabs/hardhat-etherscan")
require("dotenv").config()
require("solidity-coverage")
require("hardhat-deploy")

/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  networks: {
    localhost: {
      url: "http://127.0.0.1:8545",
      chainId: 31337,
    },
    goerli: {
      url: 'https://goerli.infura.io/v3/21f722044dea497bb97d3a918d4baf45',
      accounts: [`0x${process.env.PRIVATE_KEY}`]
    }
  },
  namedAccounts: {
    deployer: {
      default: 0,
      1: 0,
    },
  },
  solidity: {
    version: "0.8.5",
    settings: {
      optimizer: {
        enabled: true,
        runs: 200,
      },
    },
  },
  gasReporter: {
    enabled: process.env.GAS_REPORTER !== "false",
    currency: "USD",
    gasPrice: 21,
    showTimeSpent: true,
    showMethodSig: true,
  },
  // etherscan: {
  //   // The url for the Etherscan API you want to use.
  //   url: "https://api-goerli.etherscan.io/api",
  //   // Your API key for Etherscan
  //   // Obtain one at https://etherscan.io/
  //   apiKey: process.env.ETHERSCAN_API_KEY,
  // },
};