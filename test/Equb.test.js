const Equb = artifacts.require("Equb");

contract("Equb", accounts => {
    let equb;

    beforeEach(async () => {
        equb = await Equb.new();
    });

    it("should have no pools initially", async () => {
        const numberOfPools = await equb.numberOfPools();
        assert.equal(numberOfPools, 0, "Incorrect number of pools");
    });

    it("should create a new pool", async () => {
        const members = [accounts[1], accounts[2], accounts[3]];
        await equb.createEqub("Test Pool", "", "", "", 1, 0, "", "", "", "", members, { from: accounts[0] });
        const numberOfPools = await equb.numberOfPools();
        assert.equal(numberOfPools, 1, "Pool was not created");

        // check the details of the pool
        const pool = await equb.getPool(accounts[0]);
        assert.equal(pool.name, "Test Pool", "Incorrect pool name");
        assert.equal(pool.members.length, 3, "Incorrect number of members");
    });

    it("should allow members to contribute to a pool", async () => {
        // create a new pool with a member
        await equb.createEqub("Test Pool", "", "", "", 1, 0, "", "", "", "", [accounts[1]], { from: accounts[0] });

        // check if the member has contributed
        let hasContributed = await equb.hasContributed(accounts[0], accounts[1]);
        assert.equal(hasContributed, false, "Member has already contributed");

        // contribute to the pool
        await equb.contribution(accounts[0], accounts[1], 1, { from: accounts[1] });

        // check if the member has contributed
        hasContributed = await equb.hasContributed(accounts[0], accounts[1]);
        assert.equal(hasContributed, true, "Member has not contributed");
    });

    it("should allow members to skip contribution but remove them after three consecutive skips", async () => {
        // create a new pool with a member
        await equb.createEqub("Test Pool", "", "", "", 1, 0, "", "", "", "", [accounts[1]], { from: accounts[0] });

        // check if the member has skipped contribution
        let hasContributed = await equb.hasContributed(accounts[0], accounts[1]);
        assert.equal(hasContributed, false, "Member has already contributed or skipped");
        //skip contribution
        await equb.skipContribution(accounts[0], accounts[1], { from: accounts[1] });

        // check if the member has contributed
        hasContributed = await equb.hasContributed(accounts[0], accounts[1]);
        assert.equal(hasContributed, true, "Member has not skipped contribution");

        // check if the member has been removed after 3 consecutive skips
        let poolMembers = await equb.getPool(accounts[0]);
        assert.equal(poolMembers.members.length, 1, "Member should still be in the pool");
        await equb.skipContribution(accounts[0], accounts[1], { from: accounts[1] });
        await equb.skipContribution(accounts[0], accounts[1], { from: accounts[1] });
        poolMembers = await equb.getPool(accounts[0]);
        assert.equal(poolMembers.members.length, 0, "Member should be removed from the pool");
    });
});