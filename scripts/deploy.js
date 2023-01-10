// SPDX-License-Identifier: MIT
const { deployments } = require("hardhat-deploy");

async function main() {
    // Deploy the RaiseFundContract contract
    const contract = await deployments.fixture({
        contracts: [
            {
                name: "RaiseFundContract",
                alias: "RaiseFundContract",
                contract: "RaiseFundContract",
                address: "0x48719e483fb93aa150a4dc153082813829cf1479",
            },
        ],
    });
}

main()
    .then(() => process.exit(0))
    .catch(error => {
        console.error(error);
        process.exit(1);
    });