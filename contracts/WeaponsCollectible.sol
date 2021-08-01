pragma solidity 0.6.6;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@chainlink/contracts/src/v0.6/VRFConsumerBase.sol";

contract WeaponsCollectible is ERC721, VRFConsumerBase {

    bytes32 internal keyHash;
    uint256 public fee;

    uint256 public tokenCounter;
    address public owner;
    uint256 public collectible_price;
    uint256 public funds_collected;
    
    string public defaultGunATokenURI;
    string public defaultGunBTokenURI;

    mapping (bytes32 => address) public requestIdToSender;
    mapping (address => bool) public usedAirDrop; // Every account is eligible for 1 free collectible
    mapping (uint256 => Weapon) public tokenIdToWeapon;
    mapping (bytes32 => uint256) public requestIdToTokenId;

    enum WeaponType { SemiAutomatic, Automatic }

    event ownershipTransferedTo(address indexed new_owner);
    event requestedAirDrop(bytes32 indexed requestId, address indexed requester);
    event requestedCollectieble(bytes32 indexed requestId, address indexed requester);
    event priceChanged(uint256 new_price);

    struct Weapon {
        WeaponType weaponType;
        uint256 damage;
    }

    constructor(
        address _VRFCoordinator,
        address _LinkToken,
        bytes32 _keyHash,

        string memory _defaultGunATokenURI,
        string memory _defaultGunBTokenURI
    ) public
    VRFConsumerBase(_VRFCoordinator, _LinkToken)
    ERC721("Weapons", "WEPONS") {
        keyHash = _keyHash;
        tokenCounter = 0;
        fee = 0.1 * 10**18;

        owner = msg.sender;
        collectible_price = 0.1 * 10**18;
        funds_collected = 0;

        defaultGunATokenURI = _defaultGunATokenURI;
        defaultGunBTokenURI = _defaultGunBTokenURI;
    }

    function transferOwnership(address new_owner) public {
        require(owner == msg.sender, "Only present owner can transfer the ownership");
        owner = new_owner;
        emit ownershipTransferedTo(new_owner);
    }

    function changeCollectiblePrice(uint256 new_price) public {
        require(owner == msg.sender, "Only present owner can change price");
        collectible_price = new_price;
        emit priceChanged(new_price);
    }

    function withdrawFund(address payable benificiary, uint256 amount) public {
        require(owner == msg.sender, "Only owner can withdraw funds");
        require(amount <= funds_collected, "Can't withdraw more than the collected amount");

        benificiary.transfer(amount);
        funds_collected -= amount;
    }

    function changeDefaultTokenURI(string memory _defaultGunATokenURI, string memory _defaultGunBTokenURI) public {
        require(owner == msg.sender, "Only the owner can change the default token URI");

        defaultGunATokenURI = _defaultGunATokenURI;
        defaultGunBTokenURI = _defaultGunBTokenURI;
    }

    function requestAirdrop() public returns(bytes32) {
        require(usedAirDrop[msg.sender] != true, "Already used the airdrop");

        bytes32 requestId = requestRandomness(keyHash, fee);
        requestIdToSender[requestId] = msg.sender;

        emit requestedAirDrop(requestId, msg.sender);

        usedAirDrop[msg.sender] = true;

        return requestId;
    }

    function createCollectible() payable public returns(bytes32) {

        if(collectible_price > 0) {
            require(msg.value == collectible_price, "Must pay the collectible price");
        }

        funds_collected += msg.value;

        bytes32 requestId = requestRandomness(keyHash, fee);
        requestIdToSender[requestId] = msg.sender;

        emit requestedCollectieble(requestId, msg.sender);

        return requestId;
    }

    function fulfillRandomness(bytes32 requestId, uint256 randomNumber) internal override {

        address weaponOwner = requestIdToSender[requestId];
        uint256 newItemId = tokenCounter;
        _safeMint(weaponOwner, newItemId);

        WeaponType weaponType = WeaponType(randomNumber%2);

        uint256 minDamage = (weaponType == WeaponType(0)) ? (10) : (30);
        uint256 damage = minDamage + (randomNumber%50);

        Weapon memory weapon = Weapon(weaponType, damage);

        // Set the default tokenURI
        if (weaponType == WeaponType(0))
            _setTokenURI(newItemId, defaultGunATokenURI);
        else if (weaponType == WeaponType(1))
            _setTokenURI(newItemId, defaultGunBTokenURI);

        tokenIdToWeapon[newItemId] = weapon;
        requestIdToTokenId[requestId] = newItemId;
        tokenCounter += 1;

    }

    function setTokenURI(uint256 tokenId, string memory newTokenURI) public {
        require(
            _isApprovedOrOwner(_msgSender(), tokenId),
            "ERC721: transfer caller is not owner nor approved"
        );
        _setTokenURI(tokenId, newTokenURI);
    }

}