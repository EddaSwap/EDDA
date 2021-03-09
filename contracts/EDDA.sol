pragma solidity ^0.5.16;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20Detailed.sol";

import "./Governable.sol";

contract EDDA is ERC20, ERC20Detailed, Governable {
    constructor () public ERC20Detailed("EDDA", "EDDA", 18) {
        // Mint total supply to Governance during contract creation.
        // _mint is internal funciton of Openzeppelin ERC20 contract used to create all supply.
        // After contract creation, there is no way to call _mint() function on deployed contract.
        _mint(governance(), uint256(5000 * 10 ** uint256(decimals())));
    }
}