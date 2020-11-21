pragma solidity ^0.5.16;


/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
contract Context {
    // Empty internal constructor, to prevent people from mistakenly deploying
    // an instance of this contract, which should be used via inheritance.
    constructor () internal { }
    // solhint-disable-previous-line no-empty-blocks

    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

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