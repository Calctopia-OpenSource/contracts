pragma solidity ^0.4.11;

import './SafeMath.sol';
import './Ownable.sol';
import './Pausable.sol';
import './MultiSigWallet.sol';
import './UnitToken.sol';


/**
 * @title AuctionSaleDetached
 * @dev AuctionSaleDetached is a base contract for managing a token sale based on the result of a previous auction.
 * Investors can make token purchases based on the result of an auction and AuctionSale will assign 
 * them tokens based on said previous auction. 
 * Funds collected are forwarded to a wallet as they arrive.
 *
 * Based on Crowdsale.sol (OpenZeppelin)
 */
contract AuctionSaleDetached is Ownable, Pausable {
  using SafeMath for uint256;

  // The unit token being sold
  UnitToken public token;

  // address where funds are collected
  address public wallet;

  // amount of raised money in wei
  uint256 public weiRaised;

  // amounts to be paid from bidders based on finished auction
  mapping (address => uint256) private payFromAuctionAmounts;

  // amounts of tokens to generate for bidders based on finished auction
  mapping (address => uint256) private tokensMintAuctionAmounts;

  /**
   * Event for token purchase logging
   * @param purchaser who paid for the tokens
   * @param beneficiary who got the tokens
   * @param value weis paid for purchase
   * @param amount amount of tokens purchased
   */
  event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);

  /**
   * Initialise an AuctionSaleDetached with a wallet
   * @param _wallet address of the wallet
   */
  function AuctionSaleDetached(address _wallet) public {
    require(_wallet != address(0));

    token = createTokenContract(_wallet);
    wallet = _wallet;
  }

  /**
   * @dev Creates the token to be sold.
   * @param _wallet address of the wallet
   */
  function createTokenContract(address _wallet) internal returns (UnitToken) {
	// example values
	// _exercisePrice = 10
	// _callPrice = 1
	// _warrantsPerToken = 4
	// _expireTime = 1546300800 (1/1/2019)
	return new UnitToken(_wallet, 10, 1, 4, 1546300800);
  }

  // fallback function can be used to buy tokens
  function () public payable {
    buyTokens(msg.sender);
  }

  /**
   * @dev low level token purchase function
   * @param beneficiary address of the beneficiary
   */
  function buyTokens(address beneficiary) public payable whenNotPaused {
    require(beneficiary != address(0));
    require(validPurchase(beneficiary));

    uint256 weiAmount = msg.value;

    // token amount to be created
    uint256 tokens = tokensMintAuctionAmounts[beneficiary];

    // mint tokens
    token.mint(beneficiary, tokens);
    TokenPurchase(msg.sender, beneficiary, weiAmount, tokens);

    // update state
    weiRaised = weiRaised.add(weiAmount);

    // remove minted tokens
    tokensMintAuctionAmounts[beneficiary] -= tokens;

    forwardFunds();

    // remove payed amount
    payFromAuctionAmounts[beneficiary] -= weiAmount;
  }

  /**
   * @dev Send ether to the fund collection wallet
   */
  function forwardFunds() internal {
    wallet.transfer(msg.value);
  }

  /**
   * @dev check if a purchase of tokens is valid
   * @return true if the transaction can buy tokens
   */
  function validPurchase(address beneficiary) internal constant returns (bool) {
    bool nonZeroPurchase = msg.value != 0;
    bool correctAmountWillBePaid = payFromAuctionAmounts[beneficiary] == msg.value;
    bool bidderWillBeMintedTokens = tokensMintAuctionAmounts[beneficiary] > 0;
    return nonZeroPurchase && correctAmountWillBePaid && bidderWillBeMintedTokens;
  }

  /**
   * @dev Owner of the smart contract must set the amounts that each bidder must pay based on the result of the auction
   * @param bidders Array holding the addresses of bidders
   * @param amounts Array holding the amounts that each bidder must pay
   */
  function payableFromAuction (address[] bidders, uint256[] amounts) public onlyOwner {
	require(bidders.length == amounts.length);
        for (uint256 i = 0; i < bidders.length; i++) {
            payFromAuctionAmounts[bidders[i]] = amounts[i];
        }
  }

  /**
   * @dev Owner of the smart contract must set the allowable tokens that each bidder can mint based on the result of the auction
   * @param bidders Array holding the addresses of bidders
   * @param amounts Array holding the amounts that each bidder is allowed to mint
   */
  function tokensAllowableMint (address[] bidders, uint256[] amounts) public onlyOwner {
	require(bidders.length == amounts.length);
        for (uint256 i = 0; i < bidders.length; i++) {
            tokensMintAuctionAmounts[bidders[i]] = amounts[i];
        }
  }
}
