// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.4;

contract MultisigWallet {
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

    constructor(address[] memory _signatories, uint256 _numOfRequiredSignatories) {
        signatories = _signatories;
        numOfRequiredSignatories = _numOfRequiredSignatories;

        for (uint256 i = 0; i < signatories.length; i++) {
            isSignatory[signatories[i]] = true;
        }
    }
}
