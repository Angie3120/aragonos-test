pragma solidity ^0.4.24;

import "@aragon/os/contracts/apps/AragonApp.sol";
//import "openzeppelin-solidity/contracts/token/ERC721/ERC721.sol"
// import basic ERC20 details to be able to call balanceOf
// import 'openzeppelin-solidity/contracts/token/ERC20/ERC20Basic.sol';

interface IToken {
  function mintFor(address contributorAccount, uint256 amount, uint proposalId) external;
}

contract Contributions is AragonApp {
  bytes32 public constant ADD_CONTRIBUTION_ROLE = keccak256("ADD_CONTRIBUTION_ROLE");
  bytes32 public constant MANAGE_TOKEN_CONTRACT_ROLE = keccak256("MANAGE_TOKEN_CONTRACT_ROLE");

  struct ContributionData {
    address contributor;
    uint amount;
    bool claimed;
    bytes32 hashDigest;
    uint8 hashFunction;
    uint8 hashSize;
    string tokenMetadataURL;
    uint claimAfterBlock;
    bool exists;
  }
  string internal name_;
  string internal symbol_;

  address public tokenContract;

  mapping(uint256 => address) contributionOwner;
  mapping(address => uint256[]) ownedContributions;

  mapping(uint256 => ContributionData) public contributions;
  uint256 public contributionsCount;

  event ContributionAdded(uint256 id, address indexed contributor, uint256 amount);
  event ContributionClaimed(uint256 id, address indexed contributor, uint256 amount);

  function initialize(address _tokenContract) public onlyInit {
    tokenContract = _tokenContract;
    initialized();
  }

  function setTokenContract(address _tokenContract) public auth(MANAGE_TOKEN_CONTRACT_ROLE) {
    require(_tokenContract != address(0));
    tokenContract = _tokenContract;
  }

  function balanceOf(address owner) public view returns (uint256) {
    require(owner != address(0));
    return ownedContributions[owner].length;
  }

  function ownerOf(uint256 contributionId) public view returns (address) {
    require(exists(contributionId));
    return contributions[contributionId].contributor;
  }

  function getContribution(uint contributionId) public view returns (uint256 id, address contributor, uint256 amount, bool claimed, bytes32 hashDigest, uint8 hashFunction, uint8 hashSize, uint claimAfterBlock, bool exists) {
    id = contributionId;
    ContributionData storage c = contributions[id];
    return (
      id,
      c.contributor,
      c.amount, 
      c.claimed, 
      c.hashDigest,
      c.hashFunction,
      c.hashSize,
      c.claimAfterBlock,
      c.exists
    );
  }

  function add(uint256 amount, address contributor, uint256 blocksToWait) public auth(ADD_CONTRIBUTION_ROLE) {
    uint contributionId = contributionsCount + 1;
    ContributionData storage c = contributions[contributionId];
    c.exists = true;
    c.amount = amount;
    c.claimed = false;
    c.contributor = contributor;
    c.claimAfterBlock = block.number + blocksToWait;

    contributionsCount++;

    contributionOwner[contributionId] = contributor;
    ownedContributions[contributor].push(contributionId);
  
    emit ContributionAdded(contributionId, contributor, amount);
  }

  function claim(uint256 contributionId) public {
    ContributionData storage c = contributions[contributionId];
    require(c.exists);
    require(!c.claimed);
    require(block.number > c.claimAfterBlock);
    c.claimed = true;
    IToken(tokenContract).mintFor(c.contributor, c.amount, contributionId);
    
    emit ContributionClaimed(contributionId, c.contributor, c.amount);
  }
  
  function exists(uint256 contributionId) view public returns (bool) {
    return contributions[contributionId].exists;
  }
}
