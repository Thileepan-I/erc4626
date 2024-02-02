// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Script} from "forge-std/Script.sol";
import {VaultV1} from "../src/VaultV1.sol";
import {VaultV2} from "../src/VaultV2.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import {DevOpsTools} from "../lib/foundry-devops/src/DevOpsTools.sol";

contract DeployVaultV2 is Script {
    function run() external returns (address) {
        address mostRecentlyDeployedProxy = DevOpsTools
            .get_most_recent_deployment("ERC1967Proxy", block.chainid);

        vm.startBroadcast();
        VaultV2 newVault = new VaultV2();
        vm.stopBroadcast();
        address proxy = upgradeVault(mostRecentlyDeployedProxy, address(newVault));
        return proxy;
    }

    function upgradeVault(
        address proxyAddress,
        address newVault
    ) public returns (address) {
        vm.startBroadcast();
        VaultV1 proxy = VaultV1(payable(proxyAddress));

        bytes memory data = abi.encodeWithSelector(
        VaultV2.initializeV2.selector, 
        msg.sender, 
        0xF09F0369aB0a875254fB565E52226c88f10Bc839
        );
        
        proxy.upgradeToAndCall(address(newVault), data);
        vm.stopBroadcast();
        return address(proxy);
    }
}
