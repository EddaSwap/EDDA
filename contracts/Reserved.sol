pragma solidity ^0.5.16;

import "./TokenSplitter.sol";

contract Reserved is TokenSplitter {
    constructor(
        IERC20 token_, address[] memory payees_, uint256[] memory shares_, bool[] memory releasers_
    ) public TokenSplitter(token_, payees_, shares_, releasers_) {
    }
}