// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

contract DAO {

/** 
  DAO features: -
    1) Collects Investors money (ether)
    2) keep track of investors contribution with shares
    3) allow investors to transfer shares
    4) allow investment proposals to be created and voted
    5) execute successful investment proposals (& send money)
*/
  
  uint public contributionEndTime;
  uint public totalShares;
  uint public availableFunds;
  uint public nextProposalId;
  uint public voteTime;
  uint public quorum;
  address public admin;

  struct Proposal {
    uint id;
    string name;    
    uint investmentAmount;
    address payable recepient;
    uint votes;
    uint votingEndTime;
    bool executed;
  }

  mapping(uint => Proposal) public proposals;
  mapping(address => bool) public investors;
  mapping(address => uint) public shares;
  mapping(address => mapping(uint => bool)) public votes;

  //constructor
  constructor(uint _contributionPeriod, uint _voteTime, uint _quorum ) {
    require( _quorum >0 && _quorum <100, 'quorum should be less than 100');    
    contributionEndTime = block.timestamp + _contributionPeriod;
    voteTime = _voteTime;
    quorum = _quorum;
    admin = msg.sender;
  }

  modifier onlyInvestors() {
    require(investors[msg.sender] == true, 'you are not an investor');
    _;
  }

  modifier onlyAdmin() {
    require(msg.sender == admin, 'only admin can execute');
    _;
  }

  function contribute() payable external {
    require(block.timestamp < contributionEndTime, 'can not contribute after end period');
    investors[msg.sender] = true;
    shares[msg.sender] +=msg.value; //assuming 1 share is worth 1 wei
    totalShares += msg.value;
    availableFunds +=msg.value;
  }

  function redeemShares(uint _amount) external onlyInvestors() {    
    require(shares[msg.sender] >= _amount, 'not enough shares to redeem');
    require(availableFunds >= _amount,'not enough available funds');
    shares[msg.sender] -= _amount;
    totalShares -=_amount;
    availableFunds -= _amount;
    payable(msg.sender).transfer(_amount);
  }

  function transferShares(uint _amount, address _to) external onlyInvestors() {    
    require(shares[msg.sender] >= _amount, 'not enough shares to redeem');
    shares[msg.sender] -= _amount;
    investors[_to] = true;
    shares[_to] += _amount;
  }

  function createProposal(string memory _name, uint _amount, address payable _recipient) external onlyInvestors() {
    require(availableFunds >= _amount, 'amount too big');
    proposals[nextProposalId] = Proposal({
      id: nextProposalId,
      name: _name,
      investmentAmount: _amount,
      recepient: _recipient,
      votes: 0,
      votingEndTime: block.timestamp + voteTime,
      executed: false
    });

    availableFunds -= _amount;
    nextProposalId++;
  }

  function vote(uint _proposalId) external onlyInvestors() {
    Proposal storage proposal = proposals[_proposalId];
    require(votes[msg.sender][_proposalId] == false, 'you can vote only once');
    require(block.timestamp < proposal.votingEndTime,'can vote only till the deadline');
    votes[msg.sender][_proposalId] = true;
    proposal.votes +=shares[msg.sender];
  }

  function executeProposal(uint _proposalId) external onlyAdmin() {
    Proposal storage proposal = proposals[_proposalId];
    require(block.timestamp >= proposal.votingEndTime, 'can not execute before end time');
    require(proposal.executed ==false, 'can not execute a proposal twice');
    require((proposal.votes/totalShares)*100 >= quorum,'not enough quorum reached yet');
    proposal.executed = true;
    _transferEther(proposal.investmentAmount, proposal.recepient);
  }

  function withdrawEther(uint amount, address payable to) external onlyAdmin() {
    _transferEther(amount, to);
  }

  function _transferEther(uint _amount, address payable _recepient) private {
    require(_amount <= availableFunds, 'not enough funds');
    availableFunds -=_amount;
    _recepient.transfer(_amount);
  }

  receive() payable external {
    availableFunds +=msg.value;
  }


}
