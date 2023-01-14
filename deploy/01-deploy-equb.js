const { network } = require("hardhat")
const { networkConfig, developmentChains } = require("../helper-hardhat-config")
const { verify } = require("../utils/verify")
require("dotenv").config()

module.exports = async ({
    getNamedAccounts,
    deployments,
    getChainId,
    getUnnamedAccounts,
}) => {
    const { deploy, log } = deployments
    const { deployer } = await getNamedAccounts()


    // Deploy Equb
    await deploy("Equb", {
        from: deployer,
        gasLimit: 4000000,
        args: [
        ],
        log: true
    });
    log("-----------------------------------------------------------------")
};
module.exports.tags = ["all", 'Equb'];