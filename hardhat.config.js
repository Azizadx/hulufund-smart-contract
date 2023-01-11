require('dotenv').config();
require("@nomiclabs/hardhat-waffle")
require("hardhat-deploy")
require("@nomiclabs/hardhat-truffle5");

/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  solidity: {
    version: '0.8.5',
    defaultNetwork: 'hardhat',
    networks: {
      localhost: {
        url: "http://127.0.0.1:8545",
        chainId: 31337
      },
      goerli: {
        url: 'https://goerli.infura.io/v3/21f722044dea497bb97d3a918d4baf45',
        accounts: [`0x${process.env.PRIVATE_KEY}`]
      }
    },
    settings: {
      optimizer: {
        enabled: true,
        runs: 200,
      },
    },
    namedAccounts: {
      deployer: {
        default: 0,
        31337: 1,
      },
      user: {
        default: 1,
      }
    }
  },
}
