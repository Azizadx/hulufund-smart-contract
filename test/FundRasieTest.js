const { assert } = require("chai");
const { ethers } = require("hardhat");

const contractAddress = "0x5aEe82ec80365353dC72b57b6aad083BE0accEe8";

describe("createCampaign()", async function () {
    let raiseFundContract;
    let deployer;
    const campaignData = {
        logoUrl: "logoUrl",
        bannerUrl: "bannerUrl",
        name: "Campaign 1",
        description: "Description",
        industry: "Industry",
        videoUrl: "videoUrl",
        goal: ethers.utils.parseEther("1"), // goal in ether
        minInvestment: ethers.utils.parseEther("0.01"), // min investment in ether
        valuationCap: ethers.utils.parseEther("1"), // valuation cap in ether
        discountRate: ethers.utils.parseEther("5"), // discount rate in percentage
        deadline: "1606902400", // deadline as unix timestamp
    };

    beforeEach(async function () {
        // Get the contract instance using the contract address
        const contract = await ethers.getContractAt(
            "RaiseFundContract",
            contractAddress
        );
        raiseFundContract = contract;
    });

    it("creates a new campaign", async function () {
        // Create a new campaign
        const campaignId = await raiseFundContract.createCampaign(
            campaignData.logoUrl,
            campaignData.bannerUrl,
            campaignData.name,
            campaignData.description,
            campaignData.industry,
            campaignData.videoUrl,
            campaignData.goal,
            campaignData.minInvestment,
            campaignData.valuationCap,
            campaignData.discountRate,
            campaignData.deadline,
            { from: deployer }
        );
        // console.log(campaignId)
        assert.equal(campaignId.v.toString(), "0");
    });
});
