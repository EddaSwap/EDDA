pragma solidity ^0.5.16;

import "@openzeppelin/contracts/GSN/Context.sol";

/**
 * @dev Contract module which provides a Governance access control mechanism, where
 * there is an account (a Governor) that can be granted exclusive access to
 * specific functions.
 *
 * Unlike with Ownable, governance can not be renounced.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyGovernance`, which can be applied to your functions to restrict their use to
 * the Governance.
 */
contract Governable is Context {

    address private _governance;

    event GovernanceTransferred(address indexed previousGovernance, address indexed newGovernance);

    /**
     * @dev Initializes the contract setting the deployer as the initial Governance.
     */
    constructor () internal {
        address msgSender = _msgSender();
        _governance = msgSender;
        emit GovernanceTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function governance() public view returns (address) {
        return _governance;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyGovernance() {
        require(isGovernance(), "Governable: caller is not the governance");
        _;
    }

    /**
     * @dev Returns true if the caller is the current owner.
     */
    function isGovernance() public view returns (bool) {
        return _msgSender() == _governance;
    }


    /**
     * @dev Transfers governance of the contract to a new account (`newGovernance`).
     * Can only be called by the current governance.
     */
    function setGovernance(address newGovernance) public onlyGovernance {
        _transferGovernance(newGovernance);
    }

    /**
     * @dev Transfers governance of the contract to a new account (`newGovernance`).
     */
    function _transferGovernance(address newGovernance) internal {
        require(newGovernance != address(0), "Governable: new governance is the zero address");
        emit GovernanceTransferred(_governance, newGovernance);
        _governance = newGovernance;
    }
}
