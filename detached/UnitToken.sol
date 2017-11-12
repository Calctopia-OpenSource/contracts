pragma solidity ^0.4.11;

import './Ownable.sol';
import './RAZDetachedToken.sol';
import './CallableWarrantsToken.sol';

/**
 * @title UnitToken
 * @dev Unit token holding RAZDetachedTokens and their packaged CallableWarrantsToken (two different ERC20 tokens that could be listed on different exchanges)
 */
contract UnitToken is Ownable {
	RAZDetachedToken public razToken;
	CallableWarrantsToken public cwToken;

  /**
   * Event for token minting
   * @param to destination address
   * @param amount amount of tokens minted
   */
  event TokenMint(address indexed to, uint256 amount);

  /**
   * @dev Initialize UnitToken
   * @param _wallet address of the wallet
   * @param _exercisePrice exercise price of the warrant
   * @param _callPrice call price of the warrant
   * @param _warrantsPerToken number of warrants per token
   * @param _expireTime expiration time
   */
  function UnitToken(address _wallet, uint256 _exercisePrice, uint256 _callPrice, uint256 _warrantsPerToken, uint256 _expireTime) public {
    razToken = new RAZDetachedToken(_wallet);
    cwToken = new CallableWarrantsToken(_wallet, _exercisePrice, _callPrice, _warrantsPerToken, _expireTime, razToken);
    // set the callable warrant as the second owner of the warrant to allow minting within its contract
    razToken.setSecondOwner(address(cwToken));
  }

  /**
   * @dev Minting new tokens packaged with warrants
   * @param _to destination address to which tokens are being minted
   * @param _amount number of tokens to mint
   */
  function mint(address _to, uint256 _amount) onlyOwner public returns (bool) {
    require(razToken.mint(_to, _amount));
    TokenMint(_to, _amount);
    cwToken.createWarrants(_to, _amount);
  }
}