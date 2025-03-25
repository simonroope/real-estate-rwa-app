// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import {Test} from "forge-std/Test.sol";
import {console} from "forge-std/console.sol";
import {DeployPropertySystem} from "../script/DeployPropertySystem.s.sol";
import {UpgradePropertySystem} from "../script/UpgradePropertySystem.s.sol";
import {PropertyMethodsV1} from "../src/PropertyMethodsV1.sol";
import {PropertyMethodsV2} from "../src/PropertyMethodsV2.sol";
import {PropertyToken} from "../src/PropertyToken.sol";
import {ProxyAdmin} from "@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol";
import {PropertyProxy} from "../src/PropertyProxy.sol";

contract UpgradePropertySystemTest is Test {
    DeployPropertySystem deployer;
    UpgradePropertySystem upgrader;
    uint256 privateKey;
    address owner;
    address proxyAddress;
    address proxyAdminAddress;
    address propertyMethodsV1Address;
    address propertyMethodsV2Address;
    PropertyMethodsV1 propertyMethodsV1;
    PropertyMethodsV2 propertyMethodsV2;
    PropertyToken propertyToken;
    PropertyProxy propertyProxy;
    ProxyAdmin proxyAdmin;

    function setUp() public {
        privateKey = vm.envOr("PRIVATE_KEY", uint256(0x1234));
        owner = vm.addr(privateKey);
        deployer = new DeployPropertySystem();
        upgrader = new UpgradePropertySystem();

        // Deploy the system
        proxyAddress = deployer.run();

        // Get contract instances
        propertyProxy = PropertyProxy(payable(proxyAddress));
        proxyAdminAddress = propertyProxy.getAdmin();
        propertyMethodsV1Address = propertyProxy.getImplementation();

        console.log("\nSetup Debug Info:");
        console.log("-------------------");
        console.log("Proxy Address:", proxyAddress);
        console.log("ProxyAdmin Address:", proxyAdminAddress);
        console.log("Implementation Address:", propertyMethodsV1Address);
        console.log("Owner Address:", owner);

        propertyMethodsV1 = PropertyMethodsV1(proxyAddress);
        address tokenAddress = address(propertyMethodsV1.propertyToken());
        console.log("Token Address from Implementation:", tokenAddress);

        propertyToken = PropertyToken(tokenAddress);
        console.log("PropertyToken instance created at:", address(propertyToken));
    }

    function testUpgradePreservesData() public {
        // Create a property with V1
        uint256 propertyId = 1;
        uint256 totalShares = 1000;
        address alice = makeAddr("alice");

        // Create property through proxy
        vm.prank(alice);
        propertyMethodsV1.createProperty(propertyId, totalShares);

        // Verify property creation with V1
        assertEq(propertyToken.balanceOf(alice, propertyId), totalShares, "Owner should have all shares");

        // Perform upgrade as proxy
        console.log("Performing upgrade", msg.sender);
        upgrader.run();
        console.log("Upgrade completed");

        // Get V2 proxy instance
        propertyMethodsV2 = PropertyMethodsV2(proxyAddress);

        // Verify data is preserved after upgrade
        assertEq(propertyToken.balanceOf(alice, propertyId), totalShares, "Shares should be preserved after upgrade");
        assertEq(propertyMethodsV2.getPropertyOwner(propertyId), alice, "Property ownership should be preserved");
        assertEq(propertyMethodsV2.getAvailableShares(propertyId), 1000, "Available shares should be preserved");
    }

    function testUpgradePreservesMultipleProperties() public {
        // Create multiple properties with V1
        address alice = makeAddr("alice");
        address bob = makeAddr("bob");

        // Create properties
        vm.prank(alice);
        propertyMethodsV1.createProperty(1, 1000);
        vm.prank(bob);
        propertyMethodsV1.createProperty(2, 2000);

        // Perform upgrade as proxy
        console.log("Performing upgrade");
        upgrader.run();
        console.log("Upgrade completed");

        // Get V2 proxy instance
        propertyMethodsV2 = PropertyMethodsV2(proxyAddress);

        // Verify all properties are preserved
        assertEq(propertyToken.balanceOf(alice, 1), 1000, "Alice's shares should be preserved");
        assertEq(propertyToken.balanceOf(bob, 2), 2000, "Bob's shares should be preserved");
        assertEq(propertyMethodsV2.getPropertyOwner(1), alice, "Alice's ownership should be preserved");
        assertEq(propertyMethodsV2.getPropertyOwner(2), bob, "Bob's ownership should be preserved");
    }

    function testUpgradePreservesUserInvestments() public {
        // Create a property and transfer shares with V1
        uint256 propertyId = 1;
        uint256 totalShares = 1000;
        address alice = makeAddr("alice");
        address bob = makeAddr("bob");

        // Create property and transfer shares
        vm.prank(alice);
        propertyMethodsV1.createProperty(propertyId, totalShares);
        vm.prank(alice);
        propertyToken.safeTransferFrom(alice, bob, propertyId, 400, "");

        // Perform upgrade as proxy
        console.log("Performing upgrade");
        upgrader.run();
        console.log("Upgrade completed");

        // Get V2 proxy instance
        propertyMethodsV2 = PropertyMethodsV2(proxyAddress);

        // Verify all investments are preserved
        assertEq(propertyToken.balanceOf(alice, propertyId), 600, "Alice's remaining shares should be preserved");
        assertEq(propertyToken.balanceOf(bob, propertyId), 400, "Bob's received shares should be preserved");
    }
}
