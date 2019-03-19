pragma solidity ^0.4.24;

import "@aragon/os/contracts/apps/AragonApp.sol";
// import basic ERC20 details to be able to call balanceOf
// import 'openzeppelin-solidity/contracts/token/ERC20/ERC20Basic.sol';

contract Contributors is AragonApp {
  bytes32 public constant MANAGE_CONTRIBUTORS_ROLE = keccak256("MANAGE_CONTRIBUTORS_ROLE");

  struct Contributor {
    address account;
    bytes32 ipfsHash;
    uint8 hashFunction;
    uint8 hashSize;
    bool isCore;
    bool exists;
  }

  mapping (address => uint) public contributorIds;
  mapping (uint => Contributor) public contributors;
  uint256 public contributorsCount;

  event ContributorProfileUpdated(uint id, bytes32 oldIpfsHash, bytes32 newIpfsHash);
  event ContributorAccountUpdated(uint id, address oldAccount, address newAccount);
  event ContributorAdded(uint id, address account);

  function initialize() public onlyInit {
    uint _id = contributorsCount + 1;
    Contributor storage c = contributors[_id];
    c.exists = true;
    c.isCore = true;
    c.account = msg.sender;
    contributorIds[msg.sender] = _id;
    contributorsCount += 1;

    initialized();
  }

  function addContributor(address account, bytes32 ipfsHash, uint8 hashFunction, uint8 hashSize, bool isCore) public isInitialized auth(MANAGE_CONTRIBUTORS_ROLE) {
    require(!addressExists(account));
    uint _id = contributorsCount + 1;
    assert(!contributors[_id].exists); // this can not be acually
    Contributor storage c = contributors[_id];
    c.exists = true;
    c.isCore = isCore;
    c.ipfsHash = ipfsHash;
    c.hashFunction = hashFunction;
    c.hashSize = hashSize;
    c.account = account;
    contributorIds[account] = _id;

    contributorsCount += 1;
    emit ContributorAdded(_id, account);
  }

  function idIsCore(uint id) view public returns (bool) {
    return contributors[id].isCore;
  }

  function idExists(uint id) view public returns (bool) {
    return contributors[id].exists;
  }

  function addressIsCore(address account) view public returns (bool) {
    return getContributorByAddress(account).isCore;
  }

  function addressExists(address account) view public returns (bool) {
    return getContributorByAddress(account).exists;
  }

  function getContributorIdByAddress(address account) view public returns (uint) {
    return contributorIds[account];
  }

  function getContributorAddressById(uint id) view public returns (address) {
    return contributors[id].account;
  }

  function getContributorByAddress(address account) internal view returns (Contributor) {
    uint id = contributorIds[account];
    return contributors[id];
  }

  function getContributorById(uint _id) public view returns (uint id, address account, bytes32 ipfsHash, uint8 hashFunction, uint8 hashSize, bool isCore, bool exists ) {
    id = _id;
    Contributor storage c = contributors[_id];
    account = c.account;
    ipfsHash = c.ipfsHash;
    hashFunction = c.hashFunction;
    hashSize = c.hashSize;
    isCore = c.isCore;
    exists = c.exists;
  }

  function canPerform(address _who, address _where, bytes32 _what, uint256[] _how) internal view returns (bool) {
    return true;
  }
}
