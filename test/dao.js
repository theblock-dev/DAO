const DAO = artifacts.require('DAO.sol');
const {expectRevert, time} = require('@openzeppelin/test-helpers');

contract('DAO', (accounts)=>{
    let daoContract = undefined;
    const [investor1,investor2,investor3] = accounts;

    beforeEach(async()=>{
        daoContract = await DAO.new(10,10,50);
    });

    it('should accept contribution', async()=>{

        await Promise.all([
        daoContract.contribute({from:investor1,value:web3.utils.toWei('100','wei')}),
        daoContract.contribute({from:investor2,value:web3.utils.toWei('200','wei')}),
        daoContract.contribute({from:investor3,value:web3.utils.toWei('300','wei')})
        ]);
        
        const shares = await Promise.all([
            daoContract.shares(investor1),
            daoContract.shares(investor2),
            daoContract.shares(investor3)
        ]);

        const isInvestor = await Promise.all([
            daoContract.investors(investor1),
            daoContract.investors(investor2),
            daoContract.investors(investor3),
        ]);

        const totalShares = await daoContract.totalShares();
        const availableFunds = await daoContract.availableFunds();

        assert(shares[0].toString() === '100');
        assert(shares[1].toString() === '200');
        assert(shares[2].toString() === '300');

        assert(isInvestor[0] === true);
        assert(isInvestor[1] === true);
        assert(isInvestor[2] === true);

        assert (totalShares.toString() === '600');
    });

    it('should not accept contribution after the deadline', async()=>{
        await time.increase(5000);
        await expectRevert(
            daoContract.contribute({from:investor2,value:100}),
            'can not contribute after end period'
        );        
    });

    it('should create a proposal', async()=>{
        await daoContract.createProposal("proposal 1", 100, accounts[8], {from:investor2});
        const proposal = await daoContract.proposals(0);
        assert(proposal.name === 'proposal 1');
        assert(proposal.investmentAmount.toString() === '100');
        assert(proposal.votes.toString() === '0');        
    });

    it('should not create proposal if not investor', async()=>{
        await expectRevert(
            daoContract.createProposal("proposal 1", 100, accounts[8], {from:accounts[6]}),
            'you are not an investor'
        );
    });

    it('should not create proposal if amount too big', async()=>{
        await expectRevert(
            daoContract.createProposal("proposal 1", 1000, accounts[8], {from:investor1}),
            'amount too big'
        );
    });

    /**
     * Many more tests need to be added
     * unhappy paths should be tested properly
     * These test just show some of the things we need to test, you can add the rest of the tests as an excercise
     */
})