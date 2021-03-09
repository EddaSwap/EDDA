pragma solidity ^0.5.16;

import "@openzeppelin/contracts/GSN/Context.sol";
import "@openzeppelin/contracts/access/Roles.sol";

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