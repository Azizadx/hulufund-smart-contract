//import
//main function
//calling of main function
// function deployFunc() {
//     console.log("Hi")
//     hre.getNamedAccounts()
//     hre.deployments
// }
// module.exports.default = deployFunc

const { network } = require("hardhat")
const {networkConfig, developmentChains} = require("../hepler-hardhat-config")
const { verify } = require("../utils/verify")

module.exports = async ({getNamedAccounts, deployments}) => {
    const { deploy, log } = deployments
    const { deployer } = await getNamedAccounts()
    const {chainId} = network.config.chainId
    //mock contract is minimal version of real world contract that exist on mainnetwork
    //to use local testing


    //well what happens when
    // when going for localhost or hardhat network we want to use a mock
    const equb = await deploy("Equb",{
        from: deployer,
        log: true
    })
    log("-----------------------------------------------------------------")
}

module.exports.tags = ["all","equb"]