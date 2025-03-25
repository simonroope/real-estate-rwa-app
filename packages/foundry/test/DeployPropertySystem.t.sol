// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import {Test} from "forge-std/Test.sol";
import {console} from "forge-std/console.sol";
import {DeployPropertySystem} from "../script/DeployPropertySystem.s.sol";
import {PropertyToken} from "../src/PropertyToken.sol";
import {PropertyMethodsV1} from "../src/PropertyMethodsV1.sol";
import {PropertyProxy} from "../src/PropertyProxy.sol";
import {ProxyAdmin} from "@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol";

contract DeployPropertySystemTest is Test {
    DeployPropertySystem deployer;
    address owner;
    address proxyAddress;
    address proxyAdminAddress;
    address propertyMethodsV1Address;
    PropertyMethodsV1 propertyMethodsV1;
    PropertyToken propertyToken;
    PropertyProxy propertyProxy;
    ProxyAdmin proxyAdmin;

    function setUp() public {
        // Use the same private key as in the deployment script
        uint256 deployerPrivateKey = 0x1234;
        owner = vm.addr(deployerPrivateKey);
        deployer = new DeployPropertySystem();

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
        //console.log("Owner Address:", owner);

        propertyMethodsV1 = PropertyMethodsV1(proxyAddress);
        address tokenAddress = address(propertyMethodsV1.propertyToken());
        console.log("Token Address from Implementation:", tokenAddress);

        propertyToken = PropertyToken(tokenAddress);
        console.log("PropertyToken instance created at:", address(propertyToken));
    }

    function testDeployPropertySystem() public view {
        // Verify proxy address is not zero
        assertTrue(proxyAddress != address(0), "Proxy address should not be zero");

        // Verify ProxyAdmin was created
        assertTrue(proxyAdminAddress != address(0), "ProxyAdmin address should not be zero");

        // Verify initialization
        assertTrue(address(propertyMethodsV1.propertyToken()) != address(0), "PropertyToken should be set");

        // Verify PropertyToken base URI
        assertEq(
            propertyToken.uri(0), "https://api.example.com/token/0", "PropertyToken base URI should be set correctly"
        );

        // Log deployment summary
        console.log("\nDeployment Summary:");
        console.log("-------------------");
        console.log("PropertyToken:", address(propertyToken));
        console.log("PropertyProxy:", proxyAddress);
        console.log("ProxyAdmin:", proxyAdminAddress);
        console.log("Deployer:", owner);
    }

    function testPropertyTokenOperations() public {
        // Test addresses
        address alice = makeAddr("alice");
        address bob = makeAddr("bob");

        // Create a property with 1000 shares
        uint256 propertyId = 1;
        uint256 totalShares = 1000;

        // Authorize minter in PropertyMethods
        // vm.prank(proxyAdminAddress);
        // propertyMethodsV1.authorizeMinter(alice);

        // Create property through proxy
        vm.prank(alice);
        propertyMethodsV1.createProperty(propertyId, totalShares);

        // Verify property creation
        assertEq(propertyToken.balanceOf(alice, propertyId), totalShares, "Owner should have all shares");

        // Transfer some shares to Bob
        uint256 transferAmount = 400;
        vm.prank(alice);
        propertyToken.safeTransferFrom(alice, bob, propertyId, transferAmount, "");

        // Verify balances after transfer
        assertEq(
            propertyToken.balanceOf(alice, propertyId),
            totalShares - transferAmount,
            "Alice should have remaining shares"
        );
        assertEq(propertyToken.balanceOf(bob, propertyId), transferAmount, "Bob should have received shares");
    }

    function testPropertyTokenDirectOperations() public {
        // Test addresses
        address alice = makeAddr("alice");
        address bob = makeAddr("bob");
        address charlie = makeAddr("charlie");

        // Test property ID
        uint256 propertyId = 2;

        // Create property through proxy
        vm.prank(alice);
        propertyMethodsV1.createProperty(propertyId, 1000);

        // Test URI
        assertEq(propertyToken.uri(propertyId), "https://api.example.com/token/2", "Token URI should be correct");

        // Test batch transfer
        uint256[] memory ids = new uint256[](2);
        uint256[] memory amounts = new uint256[](2);
        ids[0] = propertyId;
        ids[1] = propertyId;
        amounts[0] = 100;
        amounts[1] = 200;

        vm.prank(alice);
        propertyToken.safeBatchTransferFrom(alice, bob, ids, amounts, "");

        // Verify batch transfer results
        assertEq(propertyToken.balanceOf(bob, propertyId), 300, "Bob should have received batch transfer");
        assertEq(
            propertyToken.balanceOf(alice, propertyId), 700, "Alice should have remaining shares after batch transfer"
        );

        // Test approval
        vm.prank(bob);
        propertyToken.setApprovalForAll(charlie, true);

        // Test approved transfer
        vm.prank(charlie);
        propertyToken.safeTransferFrom(bob, alice, propertyId, 100, "");

        // Verify approved transfer
        assertEq(propertyToken.balanceOf(alice, propertyId), 800, "Alice should have received approved transfer");
        assertEq(
            propertyToken.balanceOf(bob, propertyId), 200, "Bob should have remaining shares after approved transfer"
        );
    }
}
