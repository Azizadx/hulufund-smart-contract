const Equb = artifacts.require("Equb");

contract("Equb", accounts => {
    let equb;

    beforeEach(async () => {
        equb = await Equb.new();
    });

    it("should have no pools initially", async () => {
        const numberOfPools = await equb.numberOfPools();
        assert.equal(numberOfPools.toNumber(), 0, "Incorrect number of pools");
    });

    it("should create a new pool", async () => {
        // create a new pool
        const members = [accounts[1], accounts[2], accounts[3]];
        await equb.createEqub("Test Pool", "", "", "", 1, 0, "", "", "", "", members, { from: accounts[0] });

        // check the number of pools
        const numberOfPools = await equb.numberOfPools();
        expect(numberOfPools.toNumber()).to.equal(1);

        // check the details of the pool
        const pool = await equb.getPool(accounts[0]);
        expect(pool.name).to.equal("Test Pool");
        expect(pool.members.length).to.equal(3);
    });

    //Other test cases

});
