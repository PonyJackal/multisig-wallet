// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.4;

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";

contract MultiSigWallet is Ownable {
    address private recoveryAddress;
    address[] public signatories;
    uint256 public numOfRequiredSignatories;
    mapping(address => bool) public isSignatory;

    struct Transaction {
        address destination;
        uint value;
        bytes data;
        bool executed;
        uint numOfConfirmations;
    }

    // mapping tx => owner => bool
    mapping(uint256 => mapping(address => bool)) public isConfirmed;

    // transactions
    Transaction[] public transactions;

    // events
    event SignatoryAdded(address indexed signatory);
    event SignatoryRemoved(address indexed signatory);
    event NumberOfRequiredSignatoriesUpdated(uint256 numOfRequiredSignatories);
    event TransactionSubmitted(
        address indexed signatory,
        uint256 indexed nonce,
        address indexed destination,
        uint256 value,
        bytes data
    );
    event TransactionConfirmed(address indexed signatory, uint256 indexed nonce);
    event TransactionRevoked(address indexed signatory, uint256 indexed nonce);
    event TransactionExecuted(address indexed signatory, uint256 indexed nonce);

    constructor(address[] memory _signatories, uint256 _numOfRequiredSignatories) {
        signatories = _signatories;
        numOfRequiredSignatories = _numOfRequiredSignatories;

        for (uint256 i = 0; i < signatories.length; i++) {
            isSignatory[signatories[i]] = true;
        }
    }

    /** Modifiers */
    modifier onlySignatory() {
        require(isSignatory[msg.sender], "Not a signatory");
        _;
    }

    /** Owner Functions */

    /**
     * @dev Add a new signatory
     * @param _signatory The address of new signatory
     */
    function addSignatory(address _signatory) external onlyOwner {
        require(!isSignatory[_signatory], "Signatory already exists");

        isSignatory[_signatory] = true;

        signatories.push(_signatory);

        emit SignatoryAdded(_signatory);
    }

    /**
     * @dev Remove an existing signatory
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
     * @dev Update number of required signatories
     * @param _numOfRequiredSignatories The number of required signatories to execute tx
     */
    function updateNumOfRequiredSignatories(uint256 _numOfRequiredSignatories) external onlyOwner {
        numOfRequiredSignatories = _numOfRequiredSignatories;

        emit NumberOfRequiredSignatoriesUpdated(_numOfRequiredSignatories);
    }

    /**
     * @dev Set recovery address
     * @param _recoveryAddress The recovery address
     */
    function setRecoveryAddress(address _recoveryAddress) external onlyOwner {
        require(_recoveryAddress != address(0), "Invalid address");

        recoveryAddress = _recoveryAddress;
    }

    /** Mutative Functions */

    /**
     * @dev Submit a transaction
     * @param _destination The transaction destination address
     * @param _value The transaction value
     * @param _data The transaction data
     */
    function submitTransaction(address _destination, uint256 _value, bytes memory _data) external onlySignatory {
        uint256 nonce = transactions.length;

        transactions.push(
            Transaction({
                destination: _destination,
                value: _value,
                data: _data,
                executed: false,
                numOfConfirmations: 0
            })
        );

        emit TransactionSubmitted(msg.sender, nonce, _destination, _value, _data);
    }

    /**
     * @dev confirm a transaction
     * @param _nonce The transaction destination address
     */
    function confirmTransaction(uint256 _nonce) external onlySignatory {
        require(_nonce < transactions.length, "Transaction doesn't exist");
        require(!isConfirmed[_nonce][msg.sender], "Already confirmed");

        Transaction storage transaction = transactions[_nonce];
        require(!transaction.executed, "Already executed");

        isConfirmed[_nonce][msg.sender] = true;
        transaction.numOfConfirmations++;

        emit TransactionConfirmed(msg.sender, _nonce);
    }

    /**
     * @dev Revoke a transaction confirmation
     * @param _nonce The transaction nonce
     */
    function revokeTransaction(uint256 _nonce) external onlySignatory {
        require(_nonce < transactions.length, "Transaction doesn't exist");
        require(isConfirmed[_nonce][msg.sender], "Not confirmed");

        Transaction storage transaction = transactions[_nonce];
        require(!transaction.executed, "Already executed");

        isConfirmed[_nonce][msg.sender] = false;
        transaction.numOfConfirmations--;

        emit TransactionRevoked(msg.sender, _nonce);
    }

    /**
     * @dev execute a transaction
     * @param _nonce The transaction nonce
     */
    function executeTransaction(uint256 _nonce) external onlySignatory {
        require(_nonce < transactions.length, "Transaction doesn't exist");

        Transaction storage transaction = transactions[_nonce];
        require(!transaction.executed, "Already executed");
        require(transaction.numOfConfirmations >= numOfRequiredSignatories, "Cannot execute transaction");

        transaction.executed = true;

        (bool success, ) = transaction.destination.call{ value: transaction.value }(transaction.data);
        require(success, "Transaction failed");

        emit TransactionExecuted(msg.sender, _nonce);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function recoverOwnership(address newOwner) external {
        require(msg.sender == recoveryAddress, "Not a recovery address");
        require(newOwner != address(0), "Ownable: new owner is the zero address");

        _transferOwnership(newOwner);
    }
}
