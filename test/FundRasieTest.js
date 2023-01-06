// Import the contract artifact and Hardhat libraries
const { contract, utils } = require("@openzeppelin/hardhat-truffle5");

// Import BN, a library for working with large numbers in Solidity
const BN = require("bn.js");

// Import the contract artifact
const RaiseFundContract = contract.fromArtifact("RaiseFundContract");

// Test the createCampaign() function
describe("createCampaign()", () => {
    // Test that the function creates a new campaign and assigns it the correct ID
    it("creates a new campaign", async () => {
        // Create a new instance of the contract
        const raiseFundContract = await RaiseFundContract.new();

        // Create a new campaign
        const campaignId = await raiseFundContract.createCampaign(
            "logoUrl",
            "bannerUrl",
            "Campaign 1",
            "Description",
            "Industry",
            "videoUrl",
            utils.parseEther("1"), // goal
            utils.parseEther("0.01"), // min investment
            utils.parseEther("1"), // valuation cap
            new BN(5), // discount rate
            "1606902400" // deadline
        );

        // Check that the campaign was assigned the correct ID
        assert.equal(campaignId.toString(), "0");
    });

    // Test that the function correctly sets the owner, name, goal, and deadline for the campaign
    it("sets the correct details for the campaign", async () => {
        // Create a new instance of the contract
        const raiseFundContract = await RaiseFundContract.new();

        // Create a new campaign
        await raiseFundContract.createCampaign(
            "logoUrl",
            "bannerUrl",
            "Campaign 1",
            "Description",
            "Industry",
            "videoUrl",
            utils.parseEther("1"), // goal
            utils.parseEther("0.01"), // min investment
            utils.parseEther("1"), // valuation cap
            new BN(5), // discount rate
            "1606902400" // deadline
        );

        // Get the campaign details
        const campaign = await raiseFundContract.campaigns(0);

        // Check that the campaign has the correct owner
        assert.equal(campaign.owner, utils.address);

        // Check that the campaign has the correct name
        assert.equal(campaign.name, "Campaign 1");

        // Check that the campaign has the correct goal
        assert.equal(campaign.goal.toString(), utils.parseEther("1").toString());

        // Check that the campaign has the correct deadline
        assert.equal(campaign.deadline.toString(), "1606902400");
    });
})