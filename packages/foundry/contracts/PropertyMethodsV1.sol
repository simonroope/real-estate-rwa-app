// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import { Initializable } from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import { OwnableUpgradeable } from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import { PropertyToken } from "./PropertyToken.sol";

/**
 * @title PropertyMethods
 * @notice Implementation contract for property management functionality
 * @dev This contract contains the business logic for property management
 */
contract PropertyMethodsV1 is Initializable, OwnableUpgradeable {
    // Storage variables
    string internal _baseURI;
    mapping(uint256 => PropertyData) public propertyData;
    mapping(address => uint256[]) public userProperties;
    mapping(address => mapping(uint256 => uint256)) public userInvestments;
    mapping(address => bool) public authorizedMinters;

    // Structs
    struct PropertyData {
        uint256 totalShares;
        uint256 availableShares;
        address propertyOwner;
        mapping(address => uint256) shareholderShares;
    }

    // Events
    event PropertyCreated(uint256 indexed propertyId, address indexed owner, uint256 totalShares);
    event PropertySharesPurchased(uint256 indexed propertyId, address indexed buyer, uint256 amount);
    event PropertySharesSold(uint256 indexed propertyId, address indexed seller, uint256 amount);
    event MinterAuthorized(address indexed minter);
    event MinterRevoked(address indexed minter);

    // Errors
    error InsufficientShares();
    error UnauthorizedMinter();
    error PropertyNotFound();
    error InvalidAmount();
    error TransferFailed();

    // PropertyToken instance
    PropertyToken public propertyToken;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    /**
     * @notice Initialize the contract
     * @param baseURI_ Base URI for token metadata
     * @param propertyToken_ Address of the PropertyToken contract
     */
    function initialize(string memory baseURI_, address propertyToken_) public initializer {
        __Ownable_init(msg.sender);
        _baseURI = baseURI_;
        propertyToken = PropertyToken(propertyToken_);
    }

    /**
     * @notice Create a new property
     * @param propertyId Unique identifier for the property
     * @param totalShares Total number of shares for the property
     */
    function createProperty(uint256 propertyId, uint256 totalShares) external {
        if (propertyData[propertyId].totalShares > 0) revert PropertyNotFound();

        PropertyData storage newProperty = propertyData[propertyId];
        newProperty.totalShares = totalShares;
        newProperty.availableShares = totalShares;
        newProperty.propertyOwner = msg.sender;

        // Mint tokens to the property owner
        propertyToken.mint(msg.sender, propertyId, totalShares, "");

        userProperties[msg.sender].push(propertyId);
        emit PropertyCreated(propertyId, msg.sender, totalShares);
    }

    /**
     * @notice Purchase shares in a property
     * @param propertyId ID of the property
     * @param amount Number of shares to purchase
     */
    function purchaseShares(uint256 propertyId, uint256 amount) external {
        PropertyData storage property = propertyData[propertyId];
        if (property.totalShares == 0) revert PropertyNotFound();
        if (property.availableShares < amount) revert InsufficientShares();

        property.availableShares -= amount;
        property.shareholderShares[msg.sender] += amount;
        userInvestments[msg.sender][propertyId] += amount;

        emit PropertySharesPurchased(propertyId, msg.sender, amount);
    }

    /**
     * @notice Sell shares in a property
     * @param propertyId ID of the property
     * @param amount Number of shares to sell
     */
    function sellShares(uint256 propertyId, uint256 amount) external {
        PropertyData storage property = propertyData[propertyId];
        if (property.totalShares == 0) revert PropertyNotFound();
        if (property.shareholderShares[msg.sender] < amount) revert InsufficientShares();

        property.availableShares += amount;
        property.shareholderShares[msg.sender] -= amount;
        userInvestments[msg.sender][propertyId] -= amount;

        emit PropertySharesSold(propertyId, msg.sender, amount);
    }

    /**
     * @notice Authorize a minter
     * @param minter Address to authorize
     */
    function authorizeMinter(address minter) external onlyOwner {
        authorizedMinters[minter] = true;
        emit MinterAuthorized(minter);
    }

    /**
     * @notice Revoke minter authorization
     * @param minter Address to revoke
     */
    function revokeMinter(address minter) external onlyOwner {
        authorizedMinters[minter] = false;
        emit MinterRevoked(minter);
    }

    /**
     * @notice Get the number of shares owned by an address in a property
     * @param propertyId ID of the property
     * @param account Address to query
     */
    function getShareholderShares(uint256 propertyId, address account) external view returns (uint256) {
        return propertyData[propertyId].shareholderShares[account];
    }

    /**
     * @notice Get the total number of shares for a property
     * @param propertyId ID of the property
     */
    function getTotalShares(uint256 propertyId) external view returns (uint256) {
        return propertyData[propertyId].totalShares;
    }

    /**
     * @notice Get the number of available shares for a property
     * @param propertyId ID of the property
     */
    function getAvailableShares(uint256 propertyId) external view returns (uint256) {
        return propertyData[propertyId].availableShares;
    }

    /**
     * @notice Get the owner of a property
     * @param propertyId ID of the property
     */
    function getPropertyOwner(uint256 propertyId) external view returns (address) {
        return propertyData[propertyId].propertyOwner;
    }

    /**
     * @notice Get the properties owned by an address
     * @param account Address to query
     */
    function getUserProperties(address account) external view returns (uint256[] memory) {
        return userProperties[account];
    }

    /**
     * @notice Get the investment amount for a user in a property
     * @param account Address to query
     * @param propertyId ID of the property
     */
    function getUserInvestment(address account, uint256 propertyId) external view returns (uint256) {
        return userInvestments[account][propertyId];
    }
}
