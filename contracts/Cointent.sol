pragma solidity >=0.5.0 <=0.7.0;

contract Cointent {
    address owner;
    uint subscriptionValue;
    uint subscriptionLength;
    uint registrationFee;
    uint newFees;

    struct Publisher {
        uint balance;
        bool exists;
    }

    struct Subscription {
        uint expiration;
        bool distributedShares;
        uint totalHits;
    }


    address[] publishersList;
    mapping (address => Publisher) publishers;
    mapping (address => Subscription) subscriptions;
    mapping (address => mapping (address => uint8)) hits;
    mapping (address => mapping (address => string)) requests;

    constructor (uint subValue, uint subLength, uint regisFee) public {
        owner = msg.sender;
        subscriptionValue = subValue;
        subscriptionLength = subLength;
        registrationFee = regisFee;
    }

    modifier onlyPublisher () {
        require(isPublisher(msg.sender), "Was called by unregistered publisher");
        _;
    }

    modifier worthExactly (uint value) {
        require(msg.value == value, "Incorrect amount transferred");
        _;
    }

    function isPublisher (address p) internal view returns (bool) {
        publishers[p].exists;
    }

    function withdrawFees () public {
        require(msg.sender == owner, "Only owner can widthraw fees");
        uint oldNewFees = newFees;
        newFees = 0;
        msg.sender.transfer(oldNewFees * registrationFee);
    }

    function requestContent (address publisher, string memory id) public returns (bool) {
        address consumer = msg.sender;
        require(subscriptions[consumer].expiration > now, "No active subscription");
        require(isPublisher(publisher), "Was called with unregistered publisher");

        requests[consumer][publisher] = id;
        return true;
    }

    function subscribe () public payable worthExactly(subscriptionValue) {
        address consumer = msg.sender;
        require(subscriptions[consumer].expiration < now, "Subscription already active");

        payPublishers(consumer);
        subscriptions[consumer] = Subscription(now + subscriptionLength, false, 0);
    }

    function calculateShare (address consumer) public onlyPublisher returns (uint) {
        Subscription storage subscription = subscriptions[consumer];
        require(subscription.expiration < now, "Subscription needs to be expired");
        require(subscription.distributedShares, "Shares for this subscription already assigned");

        payPublishers(consumer);
    }

    function collectShare () public onlyPublisher {
        uint balance = publishers[msg.sender].balance;
        if (balance > 0) msg.sender.transfer(balance);
    }

    function registerPublisher () public payable worthExactly(registrationFee) {
        publishersList.push(msg.sender);
        publishers[msg.sender] = Publisher(0, true);
        newFees += 1;
    }

    function checkRequest (address consumer, string memory id) public onlyPublisher
        returns (bool, uint) {
        address publisher = msg.sender;
        string memory outstandingRequest = requests[consumer][publisher];


        // Check string equality
        if (bytes(outstandingRequest).length != bytes(id).length) {
            return (false, 0);
        }
        if (keccak256(abi.encodePacked((outstandingRequest))) != keccak256(abi.encodePacked((id)))) {
            return (false, 0);
        }

        delete requests[consumer][publisher];

        hits[consumer][publisher]++;
        return (true, subscriptions[consumer].expiration);
    }

    event sharesDistributed(address consumer, uint subscriptionExpiration);

    function payPublishers (address consumer) internal {
       for (uint i = 0; i < publishersList.length; i++ ) {
            address p = publishersList[i];
            // TODO: use safe math operations
            uint totalHits = subscriptions[consumer].totalHits;
            uint share = (hits[consumer][p] / totalHits) * subscriptionValue;
            publishers[p].balance += share;
        }
        subscriptions[consumer].distributedShares = true;
        emit sharesDistributed(consumer, subscriptions[consumer].expiration);
    }
}
