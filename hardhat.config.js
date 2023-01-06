require('dotenv').config();

/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  solidity: {
    version: '0.8.5',
    defaultNetwork: 'goerli',
    networks: {
      hardhat: {},
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
  },
};
