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
 * @title Roles
 * @dev Library for managing addresses assigned to a Role.
 */
library Roles {
    struct Role {
        mapping (address => bool) bearer;
    }

    /**
     * @dev Give an account access to this role.
     */
    function add(Role storage role, address account) internal {
        require(!has(role, account), "Roles: account already has role");
        role.bearer[account] = true;
    }

    /**
     * @dev Remove an account's access to this role.
     */
    function remove(Role storage role, address account) internal {
        require(has(role, account), "Roles: account does not have role");
        role.bearer[account] = false;
    }

    /**
     * @dev Check if an account has this role.
     * @return bool
     */
    function has(Role storage role, address account) internal view returns (bool) {
        require(account != address(0), "Roles: account is the zero address");
        return role.bearer[account];
    }
}

contract StopListable is Context {
    using Roles for Roles.Role;

    event StopListAdded(address indexed account);
    event StopListRemoved(address indexed account);

    Roles.Role private _stopList;

    modifier notInStopList() {
        require(!isInStopList(_msgSender()), "StopListable: caller is in stop list");
        _;
    }

    function isInStopList(address account) public view returns (bool) {
        return _stopList.has(account);
    }

    function addToStopList(address account) public {
        _addToStopList(account);
    }

    function removeFromStopList(address account) public {
        _removeFromStopList(account);
    }

    function _addToStopList(address account) internal {
        _stopList.add(account);
        emit StopListAdded(account);
    }

    function _removeFromStopList(address account) internal {
        _stopList.remove(account);
        emit StopListRemoved(account);
    }
}