pragma solidity ^0.4.11;

import './PausableToken.sol';
import './MintableToken.sol';
import './UpgradeableToken.sol';
import './Ownable.sol';
import './OwnableDeployer.sol';
import './Pausable.sol';
import './MultiSigWallet.sol';

/**
 * @title RAZDetachedToken
 * @dev Extension of MintableToken that can be paused and upgraded (but without callable warrants)
 */
contract RAZDetachedToken is PausableToken, MintableToken, UpgradeableToken {

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
   */
  function RAZDetachedToken(address _wallet)
	UpgradeableToken(_wallet) public {}

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