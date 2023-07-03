// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

contract MultiSigWallet {

    address[] owners;
    uint totalrequiredsignature;

    struct Transaction {
        address to;
        uint value;
        bytes data;
        bool executed;
        mapping(address => bool) signatures;
    }

    Transaction[] private transactions;
    
    constructor(address[] memory _owners, uint _totalrequiredsignature) {
        require(_owners.length > 0, "Input owner");
        require(_totalrequiredsignature == _owners.length, "Signature Kurang" );

        owners = _owners;
        totalrequiredsignature = _totalrequiredsignature;
    }

    modifier ownerOnly() {
        bool isOwner = false;
        for (uint i = 0; i < owners.length; i++) {
            if (msg.sender == owners[i]) {
                isOwner = true;
                break;
            }
        }
        require(isOwner, "Only owners are allowed");
        _;
    }

    function submitTransaction(address _to, uint _value, bytes memory _data) public {
        uint txIndex = transactions.length;

        transactions.push();

        Transaction storage transaction = transactions[txIndex];
        transaction.to = _to;
        transaction.value = _value;
        transaction.data = _data;
        transaction.executed = false;
    }

    function getTransaction(uint txIndex) public ownerOnly view returns(address _to, uint _value, bytes memory _data) {
        Transaction storage transaction = transactions[txIndex];
        return(transaction.to, transaction.value, transaction.data);
    }

    function signTransaction(uint txIndex) public {
        require(txIndex == transactions.length, "Invalid number");
        require(!transactions[txIndex].signatures[msg.sender], "Already signed");

        transactions[txIndex].signatures[msg.sender] = true;
    }

    function getNumSignatures(Transaction storage _transaction) private view returns (uint) {
        uint count = 0;
        for (uint i = 0; i < owners.length; i++) {
            if (_transaction.signatures[owners[i]]) {
                count++;
            }
        }
        return count;
    }

    function executeTransaction(uint txIndex) public {
        require(txIndex == transactions.length, "Invalid number");
        require(!transactions[txIndex].executed, "Already executed");

        Transaction storage transaction = transactions[txIndex];
        require(getNumSignatures(transaction) == totalrequiredsignature, "Not enough sign");

        transaction.executed = true;
    }
}