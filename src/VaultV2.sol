// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./VaultV1.sol";
import "./ICUSDC.sol";

contract VaultV2 is VaultV1 {
    bytes32 public constant SPENDER_ROLE = keccak256("SPENDER_ROLE");
    uint256 public _reserveLimit; // Amount of assets reserved for emergency
    bool public __v2Initialized = false;
    ICUSDC public cUSDC;

    event FundsSpent(address indexed spender, address destination, uint256 amount);
    event ReserveLimitUpdated(uint256 newReserveLimit); 
    event SuppliedToCompound(address indexed supplier, uint256 amount);
    event WithdrawnFromCompound(address indexed withdrawer, uint256 amount);

    error InvalidDestinationAddress();
    error InsufficientFunds(uint256 available, uint256 required);
    error WithdrawalExceedsReserveLimit(uint256 available, uint256 required);
    error RedemptionExceedsReserveLimit(uint256 available, uint256 required);
    error ReserveLimitTooHigh(uint256 limit, uint256 totalAssets);

    constructor() {
        _disableInitializers();
    }

    function initializeV2(address spender, address _cUSDCAddress) public onlyRole(UPGRADER_ROLE) {
        require(!__v2Initialized, "VaultV2: already initialized");

        _grantRole(SPENDER_ROLE, spender);
        cUSDC = ICUSDC(_cUSDCAddress); // Set the cUSDC contract address
        __v2Initialized = true;
    }

    function updateReserveLimit(uint256 newReserveLimit) external onlyRole(DEFAULT_ADMIN_ROLE) {
        if (newReserveLimit >= totalAssets()) revert ReserveLimitTooHigh({limit: newReserveLimit, totalAssets: totalAssets()});
        _reserveLimit = newReserveLimit;
        emit ReserveLimitUpdated(newReserveLimit);
    }

    function reserveLimit() public view returns (uint256) {
        return _reserveLimit;
    }

    function withdrawReserves(uint256 amount, address receiver) public onlyRole(SPENDER_ROLE) {
        if (amount > _reserveLimit) {
            revert InsufficientFunds({available: _reserveLimit, required: amount});
        }
        if (receiver == address(0)) {
            revert InvalidDestinationAddress();
        }

        // Logic to transfer the specified amount to the receiver
        IERC20(asset()).transfer(receiver, amount);

        // Update the reserve limit after withdrawal
        _reserveLimit -= amount;
        emit ReserveLimitUpdated(_reserveLimit);
    }

    function withdraw(uint256 assets, address receiver, address owner) public override returns (uint256) {
        if (totalAssets() - assets < _reserveLimit) revert WithdrawalExceedsReserveLimit({available: totalAssets() - assets, required: _reserveLimit});
        return super.withdraw(assets, receiver, owner);
    }

    function redeem(uint256 shares, address receiver, address owner) public override returns (uint256) {
        uint256 assets = convertToAssets(shares);
        if (totalAssets() - assets < _reserveLimit) revert RedemptionExceedsReserveLimit({available: totalAssets() - assets, required: _reserveLimit});
        return super.redeem(shares, receiver, owner);
    }

    // Function to supply assets to Compound
    function supplyToCompound(uint256 amount) public onlyRole(SPENDER_ROLE) {
        IERC20(asset()).approve(address(cUSDC), amount);
        cUSDC.supply(asset(), amount);
        emit SuppliedToCompound(address(this), amount);
    }

    // Function to withdraw assets from Compound
    function withdrawFromCompound(uint256 amount) public onlyRole(SPENDER_ROLE) {
        cUSDC.withdraw(asset(), amount);
        emit WithdrawnFromCompound(address(this), amount);
    }

    function getMyCUSDCBalance() public view returns (uint256) {
        return cUSDC.balanceOf(address(this));
    }
}
