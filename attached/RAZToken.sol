pragma solidity ^0.4.11;

import './CallableToken.sol';


/**
 * @title RAZToken
 * @dev ERC20 Token that can be minted, paused and upgraded. Packaged with callable warrants.
 */
contract RAZToken is CallableToken {

  string public name = "RAZ Token";
  string public symbol = "RAZ";
  uint8 public decimals = 18;

  // second owner of the contract
  address public secondOwner;

  // onlyOwner with 2 owners
  modifier onlyOwner() {
    require(msg.sender == owner || msg.sender == secondOwner);
    _;
  }

  /**
   * @dev Initialize RAZ Token
   * @param _wallet address of the wallet
   * @param _exercisePrice exercise price of the warrant
   * @param _callPrice call price of the warrant
   * @param _warrantsPerToken number of warrants per token
   * @param _expireTime expiration time
   */
  function RAZToken(address _wallet, uint256 _exercisePrice, uint256 _callPrice, uint256 _warrantsPerToken, uint256 _expireTime)  
	CallableToken(_wallet, _exercisePrice, _callPrice, _warrantsPerToken, _expireTime) public {}

  /**
   * @dev Allows the current second owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function transferSecondOwnership(address newOwner) onlyOwner public {
    require(newOwner != address(0));
    OwnershipTransferred(secondOwner, newOwner);
    secondOwner = newOwner;
  }

  /**
   * @dev Set the second owner of the contract.
   * @param _secondOwner Address of the second owner.
   */
  function setSecondOwner(address _secondOwner) onlyOwner public {
    require(_secondOwner != address(0));
    secondOwner = _secondOwner;
  }
}