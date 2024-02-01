// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;
import "forge-std/Script.sol";
import "forge-std/console.sol";
import "../src/VaultV1.sol";
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";


contract DeployVaultV1 is Script {
    function run() external {
        address underlyingAsset = 0xDB3cB4f2688daAB3BFf59C24cC42D4B6285828e9; // USDC

        vm.startBroadcast();
        // Deploy VaultV1
        VaultV1 vault = new VaultV1();
        console.log("VaultV1 implementation deployed at:", address(vault));

        // Prepare initializer call
        bytes memory initializer = abi.encodeWithSelector(
            VaultV1.initializeV1.selector,
            IERC20(underlyingAsset),
            msg.sender,
            msg.sender
        );

        // Deploy ERC1967Proxy pointing to VaultV1
        ERC1967Proxy proxy = new ERC1967Proxy(address(vault), initializer);
        console.log("VaultV1 proxy deployed at:", address(proxy));
        vm.stopBroadcast();
    }
}
