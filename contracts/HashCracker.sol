pragma solidity 0.4.23;

import "./Scrypt.sol";

contract HashCracker is Scrypt {
  
    event NewHashEvent(address requestorAddress, uint bountyValue, bytes32 hashBytes, string hashType);
    event CrackedHashEvent(address crackerAddress, uint hashCrackIndex);
 
    struct HashCrack {
        address requestorAddress;
        uint bountyValue;

        bytes32 hashBytes;
        string hashType;
       
        address crackerAddress;
        string crackedPassword;

        bool cancelled;
        bool redeemed;
    }

    HashCrack[] public hashCracks;
    mapping (string => bool) validHashTypes;

    modifier hashCrackBySender(uint _index) {
        require(hashCracks[_index].requestorAddress == msg.sender);
        _;
    }

    modifier validHashType(string _hashType) {
        require(validHashTypes[_hashType]);
        _;
    }

    modifier validHashCrack(uint _index) {
        require(hashCracks[_index].crackerAddress == 0x00 && !hashCracks[_index].cancelled);
        _;
    }
    
    modifier validMinValue() {
        require(msg.value >= 0.001 ether);
        _;
    }

    constructor()
    public 
    {
        validHashTypes["sha256"] = true;
        validHashTypes["sha3"] = true;
        validHashTypes["scrypt"] = true;
        // validHashTypes["ripemd160"] = true;
    }

    function requestHashCrack(bytes32 _hash, string _hashType, bytes _input)
    validHashType(_hashType)
    validMinValue
    payable
    public 
    {
        if (keccak256(_hashType) == keccak256("scrypt")) {
            requestScryptHashCrack(_hash, _input);
        }
        hashCracks.push(HashCrack(msg.sender, msg.value, _hash, _hashType, 0x00, "", false, false));
        emit NewHashEvent(msg.sender, msg.value, _hash, _hashType);
    }

    function submitCrack(uint _index, string _password) 
    public 
    {
        bytes32 hashedPassword;
        HashCrack storage hashCrack = hashCracks[_index];
        if (keccak256(hashCrack.hashType) == keccak256("sha256")) {
            hashedPassword = sha256(_password);
            handleCrackAttemptInternal(_index, _password, hashedPassword);
        } else if (keccak256(hashCrack.hashType) == keccak256("sha3")) {
            hashedPassword = keccak256(_password);
            handleCrackAttemptInternal(_index, _password, hashedPassword);
        } else {
            revert();
        }
    }

    function cancelHashCrack(uint _index)
    hashCrackBySender(_index) 
    validHashCrack(_index)
    public 
    {
        HashCrack storage hashCrack = hashCracks[_index];
        hashCrack.cancelled = true;
        address(hashCrack.requestorAddress).transfer(hashCrack.bountyValue);
    }

    function handleCrackAttemptInternal(uint _index, string _password, bytes32 _hashedPassword)
    validHashCrack(_index)
    internal
    {
        HashCrack storage hashCrack = hashCracks[_index];
        if (_hashedPassword == hashCrack.hashBytes) {
            hashCrack.crackerAddress = msg.sender;
            hashCrack.crackedPassword = _password;

            emit CrackedHashEvent(msg.sender, _index);
            
            if (keccak256(hashCrack.hashType) == keccak256("sha256") || keccak256(hashCrack.hashType) == keccak256("sha3")) {
                redeemCrackAttemptUnsafe(_index);
            }
        } else {
            revert();
        }
    }

    function redeemCrackAttemptUnsafe(uint _index)
    public
    {
        HashCrack storage hashCrack = hashCracks[_index];
        if (msg.sender == hashCrack.crackerAddress && !hashCrack.redeemed) {
            hashCrack.redeemed = true;
            address(msg.sender).transfer(hashCrack.bountyValue);
        } else {
            revert();
        }
    }

    function getHashCracksLength() 
    public 
    view 
    returns(uint) 
    {
        return hashCracks.length;
    }
}
