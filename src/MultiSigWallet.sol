// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.4;

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";

contract MultisigWallet is Ownable {
    address[] public signatories;
    uint256 public numOfRequiredSignatories;
    mapping(address => bool) public isSignatory;

    struct Transaction {
        address to;
        uint value;
        bytes data;
        bool executed;
        uint numOfConfirmations;
    }

    // mapping tx => owner => bool
    mapping(uint256 => mapping(address => bool)) public isConfirmed;

    // transactions
    mapping(uint256 => Transaction) public transactions;

    // events
    event SignatoryAdded(address indexed signatory);
    event SignatoryRemoved(address indexed signatory);
    event NumberOfRequiredSignatoriesUpdated(uint256 numOfRequiredSignatories);

    constructor(address[] memory _signatories, uint256 _numOfRequiredSignatories) {
        signatories = _signatories;
        numOfRequiredSignatories = _numOfRequiredSignatories;

        for (uint256 i = 0; i < signatories.length; i++) {
            isSignatory[signatories[i]] = true;
        }
    }

    /** Owner functions */

    /**
     * @dev add a new signatory
     * @param _signatory The address of new signatory
     */
    function addSignatory(address _signatory) external onlyOwner {
        require(!isSignatory[_signatory], "Signatory already exists");

        isSignatory[_signatory] = true;

        signatories.push(_signatory);

        emit SignatoryAdded(_signatory);
    }

    /**
     * @dev remove an existing signatory
     * @param _signatory The address of signatory to remove
     */
    function removeSignatory(address _signatory) external onlyOwner {
        require(isSignatory[_signatory], "Signatory doesn't exist");

        isSignatory[_signatory] = false;
        uint256 numOfSignatories = signatories.length;

        for (uint256 i = 0; i < numOfSignatories; i++) {
            if (signatories[i] == _signatory) {
                signatories[i] = signatories[numOfSignatories - 1];
                signatories.pop();
                break;
            }
        }

        emit SignatoryRemoved(_signatory);
    }

    /**
     * @dev update number of required signatories
     * @param _numOfRequiredSignatories The number of required signatories to execute tx
     */
    function updateNumOfRequiredSignatories(uint256 _numOfRequiredSignatories) external onlyOwner {
        numOfRequiredSignatories = _numOfRequiredSignatories;

        emit NumberOfRequiredSignatoriesUpdated(_numOfRequiredSignatories);
    }
}
