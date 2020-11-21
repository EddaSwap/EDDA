pragma solidity ^0.5.16;

import "./MonthlyTokenVesting.sol";

contract TokenVestingTeam is MonthlyTokenVesting {
  constructor(
    address beneficiary,
    bool beneficiaryIsReleaser,
    uint256 cliffDuration,
    uint256 duration
  ) public MonthlyTokenVesting(
    beneficiary,
    beneficiaryIsReleaser,
    cliffDuration,
    duration) {
  }
}