pragma solidity ^0.4.11;

import './PausableToken.sol';
import './MintableToken.sol';
import './UpgradeableToken.sol';
import './SafeMath.sol';
import './Ownable.sol';
import './OwnableDeployer.sol';
import './MultiSigWallet.sol';

/**
 * @title CallableToken
 * @dev Extension of MintableToken with Callable Warrants that can be paused and upgraded.
 */
contract CallableToken is PausableToken, MintableToken, UpgradeableToken, OwnableDeployer {

  // current exercise price, call price, number of warrants per token and expireTime
  uint256 public exercisePrice;
  uint256 public callPrice;
  uint256 public warrantsPerToken;
  uint256 public expireTime;

  // address where funds are collected
  address public wallet;

  /**
   * Event for token minting
   * @param to destination address
   * @param amount amount of tokens minted
   */
  event TokenMint(address indexed to, uint256 amount);

  /**
   * Event for warrant creation
   * @param to destination address
   * @param exercisePrice exercise price of the warrants
   * @param callPrice call price of the warrants
   * @param warrantsPerToken number of warrants per token
   * @param amount amount of tokens minted
   * @param expireTime expiration time
   */
  event WarrantsCreated(address indexed to, uint256 exercisePrice, uint256 callPrice, uint256 warrantsPerToken, uint256 amount, uint256 expireTime);

  /**
   * Event for warrant exercise
   * @param from calling address
   * @param callingValue value from the calling
   * @param lotUnits number of lot units exercised
   * @param idxPackage number of package of warrant
   * @param exercisingUnits number of warrants exercised
   * @param payment total payment
   */
  event WarrantsExercised(address indexed from, uint256 callingValue, uint256 lotUnits, uint256 idxPackage, uint256 exercisingUnits, uint256 payment);

  /**
   * Event for warrant called
   * @param bidder address of bidder's owner of the warrants
   * @param lotUnits number of lot units called
   * @param idxPackage number of package of warrant
   * @param exercisingUnits number of warrants called
   * @param payment total payment
   */
  event	WarrantsCalled(address indexed bidder, uint256 idxPackage, uint256 lotUnits, uint256 exercisingUnits, uint256 payment);

  // Struct for storing warrants features
  struct WarrantPackage {
	uint256 exercisePrice;
	uint256 callPrice;
	uint256 warrantsPerToken;
	uint256 numTokens;
	uint256 expireTime;
  }

  // a bidder could own different warrant packages because he could have acquired different lots in subsequent auctions
  mapping (address => WarrantPackage[]) public warrantPackages;

  /**
   * @dev Initialize a token packaged with callable warrants (unit token)
   * @param _wallet address of the wallet
   * @param _exercisePrice exercise price of the warrant
   * @param _callPrice call price of the warrant
   * @param _warrantsPerToken number of warrants per token
   * @param _expireTime expiration time
   */
  function CallableToken(address _wallet, uint256 _exercisePrice, uint256 _callPrice, uint256 _warrantsPerToken, uint256 _expireTime)
	UpgradeableToken(_wallet) public {
	exercisePrice = _exercisePrice;
	callPrice = _callPrice;
	warrantsPerToken = _warrantsPerToken;
	expireTime = _expireTime;
	wallet = _wallet;
  }

  /**
   * @dev change default warrant parameters
   * @param _exercisePrice new exercise price of the warrant
   * @param _callPrice new call price of the warrant
   * @param _warrantsPerToken new number of warrants per token
   * @param _expireTime new expiration time
   */
  function setParameters(uint256 _exercisePrice, uint256 _callPrice, uint256 _warrantsPerToken, uint256 _expireTime) public onlyDeployer {
	exercisePrice = _exercisePrice;
	callPrice = _callPrice;
	warrantsPerToken = _warrantsPerToken;
	expireTime = _expireTime;
  }

  /**
   * @dev minting new tokens packaged with warrants
   * @param _to destination address to which tokens are being minted
   * @param _amount number of tokens to mint
   */
  function mint(address _to, uint256 _amount) onlyOwner canMint public returns (bool) {
        // mint tokens
	require(super.mint(_to, _amount));
	TokenMint(_to, _amount);
	// create warrants
	WarrantPackage memory package = WarrantPackage(exercisePrice, callPrice, warrantsPerToken, _amount, expireTime);
	warrantPackages[_to].push(package);
	WarrantsCreated(_to, exercisePrice, callPrice, warrantsPerToken, _amount, expireTime);
  }

  /**
   * @dev an owner can exercise his warrants if he pays the correct amount (default warrant package 0)
   * @param _lotUnits number of warrants to mint
   */
  function exercise(uint256 _lotUnits) public payable returns (bool ok) {
	return exercise(_lotUnits, 0);
  }

  /**
   * @dev an owner can exercise his warrants if he pays the correct amount
   * @param _lotUnits number of warrants to mint
   * @param idxPackage number of the package of warrants
   */
  function exercise(uint256 _lotUnits, uint256 idxPackage) public payable returns (bool ok) {
	require(msg.sender != address(0));
	require(msg.value > 0);
	require(_lotUnits > 0);
	require(warrantPackages[msg.sender].length > 0);
	require(warrantPackages[msg.sender][idxPackage].numTokens >= _lotUnits);
	require(block.timestamp < warrantPackages[msg.sender][idxPackage].expireTime);

	//calculate the number of exercising units and payment
	uint256 exercisingUnits = _lotUnits.mul(warrantPackages[msg.sender][idxPackage].warrantsPerToken);
	uint256 payment = exercisingUnits.mul(warrantPackages[msg.sender][idxPackage].exercisePrice);

	// sender must pay the correct value
	require(payment != msg.value);

	// mint new tokens
	require(super.mint(msg.sender, exercisingUnits));
	warrantPackages[msg.sender][idxPackage].numTokens -= _lotUnits;

	// receive payment
	wallet.transfer(payment);

	WarrantsExercised(msg.sender, msg.value, _lotUnits, idxPackage, exercisingUnits, payment);
	
	return true;
  }

  /**
   * @dev an owner can inspect his warrants 
   * @param idxPackage number of the package of warrants
   * @return numeric values identifying the parameters of the warrant
   */
  function getWarrantPackage(uint256 idxPackage) constant public returns (uint256 exercisePr, uint256 callPr, uint256 warrantsPerTkn, uint256 numTkns, uint256 expirationTime) {
	exercisePr = warrantPackages[msg.sender][idxPackage].exercisePrice;
	callPr = warrantPackages[msg.sender][idxPackage].callPrice;
	warrantsPerTkn = warrantPackages[msg.sender][idxPackage].warrantsPerToken;
	numTkns = warrantPackages[msg.sender][idxPackage].numTokens;
	expirationTime = warrantPackages[msg.sender][idxPackage].expireTime;
  }

  /**
   * @dev deployer can withdraw any remaining warrant after their expiration
   * @param bidder address of the bidder that is going to have his warrants withdrawed
   */
  function withdraw(address bidder) public onlyDeployer returns (bool ok)
  {
	require(bidder != address(0));
	require(warrantPackages[bidder].length > 0);

	uint256 countPackages = warrantPackages[bidder].length;
	for (uint256 i = 0; i < countPackages; i++) {
		if (warrantPackages[bidder][i].expireTime > block.timestamp) {
			warrantPackages[bidder][i].numTokens = 0;
		}
	}
	return true;
  }

  /**
   * @dev Deployer can call warrants before expiration: note that you may want to reduce the number of required confirmations on the wallet before calling this method (MultiSigWallet:changeRequirement). Default warrant package is 0.
   * @param bidder address of the bidder that is going to be cleaned
   * @param _lotUnits number of warrants that are going to be called
   */
  function callWarrant(address bidder, uint256 _lotUnits) public onlyDeployer returns (bool ok)
  {
	return callWarrant(bidder, 0, _lotUnits);
  }

  /**
   * @dev Deployer can call warrants before expiration: note that you may want to reduce the number of required confirmations on the wallet before calling this method (MultiSigWallet:changeRequirement). Default warrant package is 0.
   * @param bidder address of the bidder that is going to be cleaned
   * @param idxPackage number of warrant package
   * @param _lotUnits number of warrants that are going to be called
   */
  function callWarrant(address bidder, uint256 idxPackage, uint256 _lotUnits) public onlyDeployer returns (bool ok)
  {
	require(bidder != address(0));
	require(_lotUnits > 0);
	require(warrantPackages[bidder].length > 0);
	require(warrantPackages[bidder][idxPackage].numTokens >= _lotUnits);
	require(block.timestamp < warrantPackages[bidder][idxPackage].expireTime);

	//calculate the number of exercising units and payment
	uint256 exercisingUnits = _lotUnits.mul(warrantPackages[bidder][idxPackage].warrantsPerToken);
	uint256 payment = exercisingUnits.mul(warrantPackages[bidder][idxPackage].callPrice);

	// mint new tokens and store them on the wallet
	require(super.mint(wallet, exercisingUnits));
	warrantPackages[bidder][idxPackage].numTokens -= _lotUnits;

	// pay the bidder for the exercised warrants from the wallet
	MultiSigWallet(wallet).submitTransaction(bidder, payment, 'Warrant called');

	WarrantsCalled(bidder, idxPackage, _lotUnits, exercisingUnits, payment);

	return true;
  }
}