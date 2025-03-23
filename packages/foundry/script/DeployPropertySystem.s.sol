// SPDX-License-Identifier: MIT
pragma solidity ^0.8.22;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";
import {PropertyToken} from "../contracts/PropertyToken.sol";
import {PropertyMethodsV1} from "../contracts/PropertyMethodsV1.sol";
import {ProxyAdmin} from "@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol";
import {TransparentUpgradeableProxy} from "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import {PropertyProxy} from "../contracts/PropertyProxy.sol";

contract DeployPropertySystem is Script {
    PropertyToken public propertyToken;

    function run() public returns (address proxyAddress) {
        // Get deployment private key from environment or use test key
        uint256 deployerPrivateKey = vm.envOr("PRIVATE_KEY", uint256(0x1234));

        // Start broadcasting transactions
        vm.startBroadcast(deployerPrivateKey);

        // Deploy PropertyToken
        propertyToken = new PropertyToken("https://api.example.com/token/");
        console.log("PropertyToken deployed at:", address(propertyToken));

        // Deploy implementation contract
        PropertyMethodsV1 implementation = new PropertyMethodsV1();
        console.log(
            "PropertyMethodsV1 implementation deployed at:",
            address(implementation)
        );

        // Prepare initialization data for proxy
        bytes memory data = abi.encodeWithSelector(
            PropertyMethodsV1.initialize.selector,
            "https://api.example.com/token/",
            address(propertyToken)
        );

        // Deploy TransparentUpgradeableProxy
        TransparentUpgradeableProxy propertyProxy = new PropertyProxy(
            address(implementation),
            msg.sender,
            data
        );
        console.log("PropertyProxy deployed at:", address(propertyProxy));

        // Stop broadcasting transactions
        vm.stopBroadcast();

        return address(propertyProxy);
    }
}
