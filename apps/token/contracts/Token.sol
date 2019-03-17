pragma solidity ^0.4.24;

import "@aragon/os/contracts/apps/AragonApp.sol";
import "@aragon/os/contracts/lib/math/SafeMath.sol";

contract Token is AragonApp {
  using SafeMath for uint256;  
  bytes32 public constant MINT_TOKEN_ROLE = keccak256("MINT_TOKEN_ROLE");

  string public name;
  string public symbol;
  uint8 public decimals;

  mapping (address => uint256) public balances;  
  uint256 public totalSupply;

  event TokenMinted(address indexed recipient, uint256 amount, uint256 contributionId);
  
  function initialize() public onlyInit {
    initialized();
  }

  function mintFor(address contributorAccount, uint256 amount, uint contributionId) public isInitialized auth(MINT_TOKEN_ROLE) {
    totalSupply = totalSupply.add(amount);
    balances[contributorAccount] = balances[contributorAccount].add(amount); 

    emit TokenMinted(contributorAccount, amount, contributionId);
  }
}
