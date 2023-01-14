const { expect } = require("chai");
const { ether } = require("@openzeppelin/test-helpers");
const { deployments, ethers, getNamedAccounts } = require("hardhat")

describe("Equb", async function () {


    let equb;
    let accounts;
    beforeEach(async function () {
        //deploy the contract
        //using Hardhat-deploy
        accounts = await ethers.getSigners();
        const deployer = accounts[0];
        await deployments.fixture("all");
        equb = await ethers.getContract("Equb", deployer);
    });

    it("should create an equb pool", async () => {
        const name = "Test Pool";
        const profileUrl = "https://example.com";
        const email = "test@example.com";
        const description = "This is a test pool";
        const contributionAmount = ether("1");
        const contributionDate = 1;
        const website = "https://example.com";
        const twitterUrl = "https://twitter.com/example";
        const facebookUrl = "https://facebook.com/example";
        const telegramUrl = "https://t.me/example";
        const members = [accounts[1], accounts[2]];
        await equb.createEqub(name, profileUrl, email, description, contributionAmount, contributionDate, website, twitterUrl, facebookUrl, telegramUrl, members, { from: accounts[0] });

        const pool = await equb.getPool(accounts[0]);
        expect(pool.equbAddress).to.equal(accounts[0]);
        expect(pool.name).to.equal(name);
        expect(pool.profileUrl).to.equal(profileUrl);
        expect(pool.email).to.equal(email);
        expect(pool.description).to.equal(description);
        expect(pool.contributionAmount).to.be.bignumber.equal(contributionAmount);
        expect(pool.contributionDate).to.be.bignumber.equal(contributionDate);
        expect(pool.equbBalance).to.be.bignumber.equal(0);
        expect(pool.website).to.equal(website);
        expect(pool.twitterUrl).to.equal(twitterUrl);
        expect(pool.facebookUrl).to.equal(facebookUrl);
        expect(pool.telegramUrl).to.equal(telegramUrl);
        expect(pool.members).to.deep.equal(members);
    });
})