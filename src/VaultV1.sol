// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC4626Upgradeable.sol";

contract VaultV1 is Initializable, ERC20Upgradeable, ERC4626Upgradeable, UUPSUpgradeable, AccessControlUpgradeable {
    bytes32 public constant UPGRADER_ROLE = keccak256("UPGRADER_ROLE");
    bool private __v1Initialized = false;

    constructor() {
        _disableInitializers();
    }

    function initializeV1(IERC20 asset_, address defaultAdmin, address upgrader)
        initializer public
    {
        require(!__v1Initialized, "VaultV1: already initialized");
        __ERC20_init("VaultToken", "VTK");
        __ERC4626_init(asset_);
        __AccessControl_init();
        __UUPSUpgradeable_init();
        
        _grantRole(DEFAULT_ADMIN_ROLE, defaultAdmin);
        _grantRole(UPGRADER_ROLE, upgrader);
        
        __v1Initialized = true;
    }

    function decimals() public view override(ERC20Upgradeable, ERC4626Upgradeable) returns (uint8) {
    return super.decimals(); 
    }

    function _authorizeUpgrade(address newImplementation) internal onlyRole(UPGRADER_ROLE) override {}

    function approveAsset(address spender, uint256 amount) public {
    IERC20(asset()).approve(spender, amount);
    }

    function allowanceAsset(address owner, address spender) public view returns (uint256) {
    return IERC20(asset()).allowance(owner, spender);
    }

    function balanceOfAsset(address account) public view returns (uint256) {
    return IERC20(asset()).balanceOf(account);
    }

}


