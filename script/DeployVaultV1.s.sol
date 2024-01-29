// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/VaultV1.sol"; // Adjust the path to your Vault contract
import "../src/AssetToken.sol"; // Adjust the path to your AssetToken contract
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

contract DeployVaultV1 is Script {
    function run() external {
        // Deploy the AssetToken
        vm.startBroadcast();
        AssetToken assetToken = new AssetToken(msg.sender);
        console.log("AssetToken deployed at:", address(assetToken));
        

        // Deploy the Vault logic contract
        VaultV1 vaultv1 = new VaultV1();
        console.log("VaultV1 Implementation contract:", address(vaultv1));

        // Encode the initializer function for the Vault
        bytes memory initializer = abi.encodeWithSelector(
            VaultV1.initialize.selector,
            IERC20(address(assetToken)),
            msg.sender, // default admin
            msg.sender  // upgrader
        );

        // Deploy the ERC1967Proxy pointing to the Vault implementation
        
        ERC1967Proxy proxy = new ERC1967Proxy(address(vaultv1), initializer);
        console.log("VaultV1 Proxy deployed at:", address(proxy));
        vm.stopBroadcast();

        // Additional setup or interactions can be done here
    }
}
