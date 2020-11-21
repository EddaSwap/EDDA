pragma solidity ^0.5.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/ownership/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";

import "./IReleaser.sol";

contract TokenSplitter is IReleaser, Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    event PayeeAdded(address account, uint256 shares);
    event PaymentReleased(address to, uint256 amount);

    IERC20 public token;

    address[] public payees;
    mapping(address => uint256) public shares;
    mapping(address => bool) public releasers;

    uint256 private _totalShares;

    constructor (IERC20 token_, address[] memory payees_, uint256[] memory shares_, bool[] memory releasers_) public {
        require(address(token_) != address(0), "TokenSplitter: token is the zero address");
        require(payees_.length == shares_.length, "TokenSplitter: payees and shares length mismatch");
        require(payees_.length == releasers_.length, "TokenSplitter: payees and releasers length mismatch");
        require(payees_.length > 0, "TokenSplitter: no payees");

        token = token_;
        for (uint256 i = 0; i < payees_.length; i++) {
            _addPayee(payees_[i], shares_[i], releasers_[i]);
        }
    }

    function payeesCount() public view returns (uint256) {
        return payees.length;
    }

    function totalShares() public view returns (uint256) {
        return _totalShares;
    }

    function release() external onlyOwner {
        uint256 balance = token.balanceOf(address(this));
        if (balance > 0) {
            for (uint256 i = 0; i < payees.length; i++) {
                address account = payees[i];
                uint256 payment = balance.mul(shares[account]).div(_totalShares);
                if (payment > 0) {
                    token.safeTransfer(account, payment);
                    if (releasers[account]) {
                        IReleaser(address(account)).release();
                    }
                    emit PaymentReleased(account, payment);
                }
            }
        }
    }

    function _addPayee(address account_, uint256 shares_, bool releaser_) private {
        require(account_ != address(0), "TokenSplitter: account is the zero address");
        require(shares_ > 0, "TokenSplitter: shares are 0");
        require(shares[account_] == 0, "TokenSplitter: account already has shares");
        // if announced as releaser - should implement interface 
        require(
            !releaser_ || IReleaser(account_).isReleaser(), 
            "TokenSplitter: account releaser status wrong"
        );

        payees.push(account_);
        shares[account_] = shares_;
        releasers[account_] = releaser_;
        _totalShares = _totalShares.add(shares_);
        emit PayeeAdded(account_, shares_);
    }
}