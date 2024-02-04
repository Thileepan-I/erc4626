// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/VaultV1.sol";
import "../src/VaultV2.sol";
import "../src/Asset.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

contract TestVaultUpgrade is Test {
    ERC1967Proxy public proxy;
    VaultV1 public vaultV1Implementation;
    VaultV2 public vaultV2Implementation;
    Asset public asset;
    address nonPrivilegedAccount = address(0xa000000000000000000000000000000000000000);
    bytes32 public constant SPENDER_ROLE = keccak256("SPENDER_ROLE");



    function setUp() public {
        // Deploy Asset contract
        asset = new Asset();
        console.log("Asset deployed at:", address(asset));

        // Deploy VaultV1 implementation
        vaultV1Implementation = new VaultV1();
        console.log("VaultV1 implementation deployed at:", address(vaultV1Implementation));

        // Prepare initializer call for VaultV1
        bytes memory initializer = abi.encodeWithSelector(
            VaultV1.initializeV1.selector,
            IERC20(address(asset)),
            address(this), // owner
            address(this)  // manager
        );

        // Deploy ERC1967Proxy for VaultV1
        proxy = new ERC1967Proxy(address(vaultV1Implementation), initializer);
        console.log("VaultV1 proxy deployed at:", address(proxy));

        // Upgrade to VaultV2
        upgradeToVaultV2();

        // Check balance of Asset
        require(asset.balanceOf(address(this)) >= 100000000, "fetch USDC from faucet");
}
    function upgradeToVaultV2() internal {
        // Deploy VaultV2 implementation
        vaultV2Implementation = new VaultV2();
        console.log("VaultV2 implementation deployed at:", address(vaultV2Implementation));

        // Prepare data for initializing VaultV2
        bytes memory data = abi.encodeWithSelector(
            VaultV2.initializeV2.selector, 
            address(this), // new owner or any other initial setup parameters for V2
            0xF09F0369aB0a875254fB565E52226c88f10Bc839 // example parameter, adjust accordingly
        );

        // Cast the proxy to VaultV1 to call the upgrade function
        VaultV1 proxyVaultV1 = VaultV1(address(proxy));

        // Upgrade the proxy to VaultV2 implementation and call initialization
        proxyVaultV1.upgradeToAndCall(address(vaultV2Implementation), data);
        console.log("Vault upgraded to V2 at:", address(proxy));
    }

    function testDepositAndRedeem() public {
        VaultV2 vault = VaultV2(address(proxy));
        uint256 depositAmount = 100000000;

        // Pre-approve the asset transfer to the Vault
        asset.approve(address(proxy), depositAmount);

        // Deposit assets into the Vault which mints shares
        vault.deposit(depositAmount, address(this));

        // Check if the assets were deposited successfully by verifying the total assets
        uint256 totalAssets = vault.totalAssets();
        require(totalAssets == depositAmount, "Total assets in vault do not match deposit amount");

        // Verify the share allocation matches the deposited amount
        uint256 sharesBalance = vault.balanceOf(address(this));
        require(sharesBalance == depositAmount, "Shares balance does not match deposit amount");

        // Redeem assets which burns shares
        vault.redeem(depositAmount, address(this), address(this));
    }

    function testAccessRoles() public {
    VaultV2 vault = VaultV2(address(proxy));
    uint256 depositAmount = 10000;
    uint256 newReserveLimit = 1100;
    uint256 withdrawAmount = 500;

    asset.approve(address(proxy), depositAmount);
    vault.deposit(depositAmount, address(this));
    // Default admin - success
    vm.startPrank(address(this));
    vault.updateReserveLimit(newReserveLimit);
    vm.stopPrank();

    // Not Default Admin - fail
    vm.startPrank(nonPrivilegedAccount);
    vm.expectRevert();
    vault.updateReserveLimit(newReserveLimit);
    vm.stopPrank();

    // Upgrader role - success
    vm.startPrank(address(this));
    vault.hasRole(0x189ab7a9244df0848122154315af71fe140f3db0fe014031783b0946b8c9d2e3,address(this));
    vm.stopPrank();

    // Spender role - success
    vm.startPrank(address(this)); 
    vault.withdrawReserves(withdrawAmount, address(this));
    vm.stopPrank();

    // Not Spender role - fail
    vm.startPrank(nonPrivilegedAccount);
    vm.expectRevert();
    vault.withdrawReserves(withdrawAmount, address(this));
    vm.stopPrank();
}
    function testReserveAndEmergencyWithdraw() public {
       VaultV2 vault = VaultV2(address(proxy));
        uint256 depositAmount = 10000;
        uint256 reserveLimit = 1000;
        uint256 newReserveLimit = 800;
        uint256 withdrawAmount = 500;

    // Pre-approve and deposit to simulate active vault usage
    asset.approve(address(proxy), depositAmount);
    vault.deposit(depositAmount, address(this));

    // Set the reserve limit as Default Admin
    vault.updateReserveLimit(reserveLimit); // Should succeed with DEFAULT_ADMIN_ROLE

    // Test -1 Revert when withdrawl amount exceeds reserves
    vm.startPrank(address(this));
    vm.expectRevert();
    vault.withdraw(9200, address(this),address(this)); // This should trigger the InsufficientFunds error.
    vm.stopPrank();

    vault.updateReserveLimit(newReserveLimit);

    // Test -2 Able to withdraw after updating reserves
    vm.startPrank(address(this)); // Ensure we are back to the privileged account, may be redundant but for clarity
    vault.withdraw(9200, address(this), address(this)); // Should succeed with SPENDER_ROLE
    vm.stopPrank();
    
    // Test -3 Spender role able to withdraw reserves
    vm.startPrank(address(this)); // Ensure we are back to the privileged account, may be redundant but for clarity
    vault.withdrawReserves(withdrawAmount, address(this)); // Should succeed with SPENDER_ROLE
    vm.stopPrank();
    
    // Test 4: Ensure non-privileged accounts cannot withdraw reserves
    vm.startPrank(nonPrivilegedAccount);
    vm.expectRevert(); // Specify the expected revert reason if known
    vault.withdrawReserves(withdrawAmount, address(this));
    vm.stopPrank();

}

}