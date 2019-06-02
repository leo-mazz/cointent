pragma solidity >=0.5.0;

contract Cointent {
    address owner;
    uint value;
    uint length;

    mapping (address => uint256) subscriptions;
    mapping (address => mapping (address => string)) requests;

    constructor (uint _value, uint _length) public {
        owner = msg.sender;
        value = _value;
        length = _length;
    }

    function requestContent (address publisher, string memory id) public returns (bool) {
        address consumer = msg.sender;
        require(subscriptions[consumer] > now, "No active subscription");

        requests[consumer][publisher] = id;

        return true;
    }

    function subscribe () public payable {
        require(msg.value == value, "Incorrect amount transferred");

        subscriptions[msg.sender] = now + length;
    }

    function checkRequest (address consumer, string memory id) public returns (bool) {
        address publisher = msg.sender;
        string memory outstandingRequest = requests[consumer][publisher];

        if (bytes(outstandingRequest).length != bytes(id).length) {
            return false;
        }

        if (keccak256(abi.encodePacked((outstandingRequest))) != keccak256(abi.encodePacked((id)))) {
            return false;
        }

        delete requests[consumer][publisher];
        return true;
    }
}