pragma solidity ^0.5.0;

import "./TokenSplitter.sol";

contract TokenSplitterTeam is TokenSplitter {
    constructor (
        IERC20 token_, 
        address[] memory payees_, 
        uint256[] memory shares_,
        bool[] memory releasers_
    ) public TokenSplitter(
        token_, payees_, shares_, releasers_
    ) {}
}