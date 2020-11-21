// Based on "@openzeppelin<2.5.1>/contracts/drafts/TokenVesting.sol";

pragma solidity ^0.5.16;

import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/ownership/Ownable.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";

import "./IReleaser.sol";

contract MonthlyTokenVesting is IReleaser, Ownable {
  using SafeMath for uint256;
  using SafeERC20 for IERC20;

  event TokensReleased(address token, uint256 amount);

  address public _beneficiary;
  bool public _beneficiaryIsReleaser;

  // Durations and timestamps are expressed in UNIX time, the same units as block.timestamp.
  uint256 private _cliff;
  uint256 private _start;
  uint256 private _duration;

  mapping(address => uint256) private _released;

  uint256 private SECONDS_GAP = 60 * 60 * 24 * 31;

  /**
   * @dev Creates a vesting contract that vests its balance of any ERC20 token to the
   * beneficiary, gradually in a linear fashion until start + duration. By then all
   * of the balance will have vested.
   * @param beneficiary address of the beneficiary to whom vested tokens are transferred
   * @param cliffDuration duration in seconds of the cliff in which tokens will begin to vest
   * @param duration duration in seconds of the period in which the tokens will vest
   */
  constructor(
    address beneficiary,
    bool beneficiaryIsReleaser,
    uint256 cliffDuration,
    uint256 duration
  ) public {
    require(
      beneficiary != address(0),
      "TokenVesting: beneficiary is the zero address"
    );
    require(duration > 0, "TokenVesting: duration is 0");
    // if announced as releaser - should implement interface 
    require(
      !beneficiaryIsReleaser || IReleaser(beneficiary).isReleaser(),
      "TokenVesting: beneficiary releaser status wrong"
    );

    _beneficiary = beneficiary;
    _beneficiaryIsReleaser = beneficiaryIsReleaser;
    _duration = duration;
    _cliff = cliffDuration;
  }

  function release() public onlyOwner {
    _start = block.timestamp;
    _cliff = _start.add(_cliff);
  }

  /**
   * @return the beneficiary of the tokens.
   */
  function beneficiary() public view returns (address) {
    return _beneficiary;
  }

  /**
   * @return the cliff time of the token vesting.
   */
  function cliff() public view returns (uint256) {
    return _cliff;
  }

  /**
   * @return the start time of the token vesting.
   */
  function start() public view returns (uint256) {
    return _start;
  }

  /**
   * @return the duration of the token vesting.
   */
  function duration() public view returns (uint256) {
    return _duration;
  }

  /**
   * @return the amount of the token released.
   */
  function released(address token) public view returns (uint256) {
    return _released[token];
  }

  /**
   * @notice Transfers vested tokens to beneficiary.
   * @param token ERC20 token which is being vested
   */
  function claim(IERC20 token) public {
    require(_start > 0, "TokenVesting: start is not set");

    uint256 unreleased = _releasableAmount(token);

    require(unreleased > 0, "TokenVesting: no tokens are due");

    _released[address(token)] = _released[address(token)].add(unreleased);

    token.safeTransfer(_beneficiary, unreleased);
    if (_beneficiaryIsReleaser) {
      IReleaser(_beneficiary).release();
    }

    emit TokensReleased(address(token), unreleased);
  }
    
  /**
   * @dev Calculates the amount that has already vested but hasn't been released yet.
   * @param token ERC20 token which is being vested
   */
  function _releasableAmount(IERC20 token) private view returns (uint256) {
    return _vestedAmount(token).sub(_released[address(token)]);
  }

  /**
   * @dev Calculates the amount that has already vested.
   * @param token ERC20 token which is being vested
   */
  function _vestedAmount(IERC20 token) private view returns (uint256) {
    uint256 currentBalance = token.balanceOf(address(this));
    uint256 totalBalance = currentBalance.add(_released[address(token)]);

    if (block.timestamp < _cliff) {
      return 0;
    } else if (block.timestamp >= _cliff.add(_duration)) {
      return totalBalance;
    } else {
      uint256 elapsed = block.timestamp.sub(_cliff);
      elapsed = elapsed.div(SECONDS_GAP).add(1).mul(SECONDS_GAP);
      return totalBalance.mul(elapsed).div(_duration);
    }
  }
}
