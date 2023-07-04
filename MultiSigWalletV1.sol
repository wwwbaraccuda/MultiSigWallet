// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

contract MultiSigWallet {

    address[] owners;
    uint totalRequiredConfimation;

    struct Transaction {
        address to;
        uint value;
        bytes data;
        bool executed;
    }

    mapping(uint=>mapping(address=>bool)) isConfirmed;    
    Transaction[] private transactions;
    
    event TransactionSubmitted(uint txIndex, address sender, address receiver, uint amount);
    event TransactionSigned(uint txIndex);
    event TransactionExecuted(uint txIndex);

    constructor(address[] memory _owners, uint _totalRequiredConfimation) {
        require(_owners.length > 1, "Input owner");
        require(_totalRequiredConfimation == _owners.length, "Signature Kurang" );
        owners = _owners;
        totalRequiredConfimation = _totalRequiredConfimation;
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

    function submitTransaction(address _to, bytes memory _data) public ownerOnly payable{
        require(_to!=address(0), "Invalid Receiver's Address");
        require(msg.value>0, "Input amount");
        uint txIndex = transactions.length;
        transactions.push(Transaction({to: _to, value: msg.value, data: _data, executed: false}));
        emit TransactionSubmitted(txIndex, msg.sender, _to, msg.value);
    }

    function getOwners() public view returns(address[] memory) {
        return owners;
    }

    function getTransaction(uint txIndex) public ownerOnly view returns(address _to, uint _value, bytes memory _data) {
        Transaction storage transaction = transactions[txIndex];
        return(transaction.to, transaction.value, transaction.data);
    }

    function confirmTransaction(uint txIndex) public ownerOnly {
        require(txIndex < transactions.length, "Invalid number");
        require(!isConfirmed[txIndex][msg.sender], "Already confirmed");
        isConfirmed[txIndex][msg.sender] = true;
        emit TransactionSigned(txIndex);
    }

    function isTransactionConfirmed(uint txIndex) public view returns (bool) {
        require(txIndex < transactions.length, "Invalid number");
        uint count=0;

        for (uint i = 0; i < owners.length; i++) {
            if (isConfirmed[txIndex][owners[i]]) {
                count++;
            }
        }
        return count>=totalRequiredConfimation;
    }

    function executeTransaction(uint txIndex) public payable ownerOnly {
        require(txIndex < transactions.length, "Invalid number");
        require(!transactions[txIndex].executed, "Already executed");
        (bool success,) = transactions[txIndex].to.call{value: transactions[txIndex].value}("");
        require(success, "Transaction Failed");
        transactions[txIndex].executed = true;
        emit TransactionExecuted(txIndex);
    }
}
