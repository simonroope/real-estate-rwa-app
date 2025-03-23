// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import {Test} from "forge-std/Test.sol";
import {console} from "forge-std/console.sol";
import {DeployPropertySystem} from "../script/DeployPropertySystem.s.sol";
import {PropertyToken} from "../contracts/PropertyToken.sol";
import {PropertyMethodsV1} from "../contracts/PropertyMethodsV1.sol";
import {PropertyMethodsV2} from "../contracts/PropertyMethodsV2.sol";
import {TransparentUpgradeableProxy} from "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import {ProxyAdmin} from "@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol";
import {ITransparentUpgradeableProxy} from "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
contract DeployPropertySystemTest is Test {
    DeployPropertySystem deployer;
    address owner;
    address proxyAddress;
    PropertyToken propertyToken;
    PropertyMethodsV1 proxy;

    function setUp() public {
        owner = vm.addr(0x1234);
        vm.prank(owner);
        deployer = new DeployPropertySystem();

        // Deploy the system
        proxyAddress = deployer.run();

        // Get contract instances
        proxy = PropertyMethodsV1(proxyAddress);
        propertyToken = PropertyToken(proxy.propertyToken());
    }

    function testDeployPropertySystem() public view {
        // Verify proxy address is not zero
        assertTrue(
            proxyAddress != address(0),
            "Proxy address should not be zero"
        );

        // Verify initialization
        assertTrue(
            address(proxy.propertyToken()) != address(0),
            "PropertyToken should be set"
        );

        // Verify PropertyToken base URI
        assertEq(
            propertyToken.uri(0),
            "https://api.example.com/token/0",
            "PropertyToken base URI should be set correctly"
        );

        // Log deployment summary
        console.log("\nDeployment Summary:");
        console.log("-------------------");
        console.log("PropertyToken:", address(propertyToken));
        console.log("PropertyProxy:", proxyAddress);
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
        vm.prank(owner);
        proxy.authorizeMinter(address(this));

        // Create property through proxy
        vm.prank(alice);
        proxy.createProperty(propertyId, totalShares);

        // Verify property creation
        assertEq(
            propertyToken.balanceOf(alice, propertyId),
            totalShares,
            "Owner should have all shares"
        );

        // Transfer some shares to Bob
        uint256 transferAmount = 400;
        vm.prank(alice);
        propertyToken.safeTransferFrom(
            alice,
            bob,
            propertyId,
            transferAmount,
            ""
        );

        // Verify balances after transfer
        assertEq(
            propertyToken.balanceOf(alice, propertyId),
            totalShares - transferAmount,
            "Alice should have remaining shares"
        );
        assertEq(
            propertyToken.balanceOf(bob, propertyId),
            transferAmount,
            "Bob should have received shares"
        );
    }

    function testPropertyTokenDirectOperations() public {
        // Test addresses
        address alice = makeAddr("alice");
        address bob = makeAddr("bob");
        address charlie = makeAddr("charlie");

        // Test property ID
        uint256 propertyId = 2;

        // Authorize minter in PropertyMethods
        vm.prank(owner);
        proxy.authorizeMinter(address(this));

        // Create property through proxy
        vm.prank(alice);
        proxy.createProperty(propertyId, 1000);

        // Test URI
        assertEq(
            propertyToken.uri(propertyId),
            "https://api.example.com/token/2",
            "Token URI should be correct"
        );

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
        assertEq(
            propertyToken.balanceOf(bob, propertyId),
            300,
            "Bob should have received batch transfer"
        );
        assertEq(
            propertyToken.balanceOf(alice, propertyId),
            700,
            "Alice should have remaining shares after batch transfer"
        );

        // Test approval
        vm.prank(bob);
        propertyToken.setApprovalForAll(charlie, true);

        // Test approved transfer
        vm.prank(charlie);
        propertyToken.safeTransferFrom(bob, alice, propertyId, 100, "");

        // Verify approved transfer
        assertEq(
            propertyToken.balanceOf(alice, propertyId),
            800,
            "Alice should have received approved transfer"
        );
        assertEq(
            propertyToken.balanceOf(bob, propertyId),
            200,
            "Bob should have remaining shares after approved transfer"
        );
    }

    function testUpgradePropertyMethods() public {
        // Test addresses
        // proxy.upgradeToAndCall(address(new PropertyMethodsV2()), "");
        // PropertyMethodsV2 newImplementation = new PropertyMethodsV2();
        ProxyAdmin proxyAdmin = new ProxyAdmin(owner);

        address adminAddress = proxyAdmin.owner();
        vm.prank(adminAddress);
        // who is the actual admin ?
        console.log("Admin address:", adminAddress);
        console.log("this address:", address(this));

        proxyAdmin.upgradeAndCall(
            ITransparentUpgradeableProxy(payable(proxyAddress)),
            address(new PropertyMethodsV2()),
            abi.encodeWithSelector(
                PropertyMethodsV2.initialize.selector,
                "https://api.example.com/token/2"
            )
        );
    }
}
