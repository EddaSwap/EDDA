// SPDX-License-Identifier: MIT

/**
 * Yggdrasil.finance
 * https://yggdrasil.finance
 *
 * Additional details for contract and wallet information:
 * https://yggdrasil.finance/tracking/
 */

pragma solidity ^0.5.16;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/ownership/Ownable.sol";

import "./EDDA.sol";
import "./TokenSplitter.sol";

contract EDDATokenSale is Ownable {
    //Enable SafeMath
    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    using SafeERC20 for EDDA;

    uint8 public constant percentSale = 65; 
    bool public initialized;

    uint256 public constant SCALAR = 1e18; // multiplier
    uint256 public constant minBuyWei = 1e17; // in Wei

    address public tokenAcceptor;
    address payable public ETHAcceptor;
    uint256 public priceInWei;
    uint256 public maxBuyTokens = 20; // in EDDA per address
    uint256 public initialSupplyInWei;
    
    address[] buyers; // buyers
    mapping(address => uint256) public purchases; // balances
    uint256 public purchased; // spent
    uint256 public distributionBatch = 1;
    uint256 public transferredToTokenAcceptor;

    bool public saleEnabled = false;

    EDDA public tokenContract;
    TokenSplitter public reserved;

    // Events
    event Sell(address _buyer, uint256 _amount);
    event Paid(address _from, uint256 _amount);
    event Withdraw(address _to, uint256 _amount);

    // On deployment
    constructor(
        EDDA _tokenContract, 
        uint256 _priceInWei,
        address _tokenAcceptor, 
        address payable _ETHAcceptor,
        address _reserved
    ) public {
        tokenContract = _tokenContract;
        tokenAcceptor = _tokenAcceptor;
        priceInWei = _priceInWei;
        ETHAcceptor = _ETHAcceptor;
        reserved = TokenSplitter(_reserved);
    }

    // Initialise
    function init() external onlyOwner {
        require(!initialized, "Could be initialized only once");
        require(reserved.owner() == address(this), "Sale should be the owner of Reserved funds");

        uint256 _initialSupplyInWei = tokenContract.balanceOf(address(this));
        require(
            _initialSupplyInWei > 0, 
            "Initial supply should be > 0"
        );

        initialSupplyInWei = _initialSupplyInWei;
        
        uint256 _tokensToReserveInWei = _getInitialSupplyPercentInWei(100 - percentSale); 
        initialized = true;
        tokenContract.safeTransfer(address(reserved), _tokensToReserveInWei);
    }
  
    /// @notice Any funds sent to this function will be unrecoverable
    /// @dev This function receives funds, there is currently no way to send funds back
    function () external payable {
        emit Paid(msg.sender, msg.value);
    }

    // Buy tokens with ETH
    function buyTokens() external payable {
        uint256 _ethSent = msg.value;
        require(saleEnabled, "The EDDA Initial Token Offering is not yet started");
        require(_ethSent >= minBuyWei, "Minimum purchase per transaction is 0.1 ETH");

        uint256 _tokens = _ethSent.mul(SCALAR).div(priceInWei);

        // Check that the purchase amount does not exceed remaining tokens
        require(_tokens <= _remainingTokens(), "Not enough tokens remain");

        if (purchases[msg.sender] == 0) {
            buyers.push(msg.sender);
        }
        purchases[msg.sender] = purchases[msg.sender].add(_tokens);
        require(purchases[msg.sender] <= maxBuyTokens.mul(SCALAR), "Exceeded maximum purchase limit per address");

        purchased = purchased.add(_tokens);

        emit Sell(msg.sender, _tokens);
    }

    // Enable the token sale
    function enableSale(bool _saleStatus) external onlyOwner {
        require(initialized, "Sale should be initialized");
        saleEnabled = _saleStatus;
    }

    // Update the current Token price in ETH
    function setPriceETH(uint256 _priceInWei) external onlyOwner {
        require(_priceInWei > 0, "Token price should be > 0");
        priceInWei = _priceInWei;
    }

    // Update the maximum buy in tokens
    function updateMaxBuyTokens(uint256 _maxBuyTokens) external onlyOwner {
        maxBuyTokens = _maxBuyTokens;
    }

    // Update the distribution batch size
    function updateDistributionBatch(uint256 _distributionBatch) external onlyOwner {
        distributionBatch = _distributionBatch;
    }

    // Distribute purchased tokens
    function distribute(uint256 _offset) external onlyOwner returns (uint256) {
        uint256 _distributed = 0;
        for (uint256 i = _offset; i < buyers.length; i++) {
            address _buyer = buyers[i];
            uint256 _purchase = purchases[_buyer];
            if (_purchase > 0) {
                purchases[_buyer] = 0;
                tokenContract.safeTransfer(_buyer, _purchase);
                if (++_distributed >= distributionBatch) {
                    break;
                }
            }            
        }
        return _distributed;
    }

    // Withdraw current ETH balance
    function withdraw() public onlyOwner {
        emit Withdraw(ETHAcceptor, address(this).balance);
        ETHAcceptor.transfer(address(this).balance);
    }

    // Get percent value of initial supply in wei
    function _getInitialSupplyPercentInWei(uint8 _percent) private view returns (uint256) {
        return initialSupplyInWei.mul(_percent).div(100); 
    }

    // Get tokens remaining on token sale balance
    function _remainingTokens() private view returns (uint256) {
        return _getInitialSupplyPercentInWei(percentSale)
            .sub(purchased)
            .sub(transferredToTokenAcceptor);
    }

    // End the token sale and transfer remaining ETH and tokens to the acceptors
    function endSale() external onlyOwner {
        uint256 remainingTokens = _remainingTokens();
        if (remainingTokens > 0) {
            transferredToTokenAcceptor = transferredToTokenAcceptor.add(remainingTokens);
            tokenContract.safeTransfer(tokenAcceptor, remainingTokens);
        }
        withdraw();
        reserved.release();

        saleEnabled = false;
    }
}