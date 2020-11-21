pragma solidity ^0.5.0;


contract IReleaser {
    function release() external;

    function isReleaser() external pure returns (bool) {
        return true;
    }
}