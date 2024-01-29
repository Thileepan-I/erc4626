// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/Vault.sol";   // Adjust the path to your Vault contract
import "../src/AssetToken.sol";   // Adjust the path to your AssetToken contract
import "../lib/openzeppelin-contracts/contracts/proxy/ERC1967/ERC1967Proxy.sol";

contract DeployScript is Script {
    function run() external {
        // Deploy the AssetToken
        vm.startBroadcast();
        AssetToken assetToken = new AssetToken(msg.sender); // Adjust initial supply as needed
        console.log("AssetToken address:", address(assetToken));
        vm.stopBroadcast();

        // Deploy the implementation of the Vault
        Vault vault = new Vault();
        console.log("Vault Implementation address:", address(vault));

        // Encode the initializer function for the Vault
        bytes memory initializer = abi.encodeWithSelector(
            Vault.initialize.selector,
            IERC20(address(assetToken)),
            msg.sender,  // Initial owner
            100  // Minimum reserve, adjust as needed
        );

        // Deploy the proxy, pointing to the Vault implementation
        vm.startBroadcast();
        ERC1967Proxy proxy = new ERC1967Proxy(address(vault), initializer);
        console.log("Vault Proxy address:", address(proxy));
        vm.stopBroadcast();

        // Cast the proxy address to the Vault interface to interact with it as Vault
        Vault vaultProxy = Vault(address(proxy));
        console.log("Vault Proxy address for interaction:", address(vaultProxy));

        
        // Additional setup or interactions with the contract can be done here
    }
}
