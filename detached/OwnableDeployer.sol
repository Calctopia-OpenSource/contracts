pragma solidity ^0.4.11;


/**
 * @title OwnableDeployer
 * @dev The OwnableDeployer contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 * This contract initially stores the tx.origin as the owner instead of the msg.sender.
 */
contract OwnableDeployer {
  address public owner;


  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  function OwnableDeployer() public {
    owner = tx.origin;
  }


  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyDeployer() {
    require(msg.sender == owner);
    _;
  }


  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnershipDeployer(address newOwner) onlyDeployer public {
    require(newOwner != address(0));
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}
