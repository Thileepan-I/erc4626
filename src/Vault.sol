// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "../lib/openzeppelin-contracts-upgradeable/contracts/access/OwnableUpgradeable.sol";
import "../lib/openzeppelin-contracts-upgradeable/contracts/proxy/utils/Initializable.sol";
import "../lib/openzeppelin-contracts-upgradeable/contracts/proxy/utils/UUPSUpgradeable.sol";
import "../lib/openzeppelin-contracts-upgradeable/contracts/token/ERC20/ERC20Upgradeable.sol";
import "../lib/openzeppelin-contracts-upgradeable/contracts/token/ERC20/extensions/ERC4626Upgradeable.sol";

contract Vault is Initializable, ERC20Upgradeable, ERC4626Upgradeable, UUPSUpgradeable, OwnableUpgradeable {
    uint256 private minimumReserve;
    uint256 private constant INTEREST_RATE_5 = 500; // 5%
    uint256 private constant INTEREST_RATE_10 = 1000; // 10%
    uint256 private constant INTEREST_RATE_15 = 1500; // 15%

    struct StakerInfo {
        uint256 balance;
        uint256 lastBlockNumber;
    }

    mapping(address => StakerInfo) private stakers;

    constructor() {
        _disableInitializers();
    }

    function initialize(IERC20 asset_, address initialOwner, uint256 _minimumReserve) public initializer {
        __ERC20_init("Share Token", "SKT");
        __ERC4626_init(asset_);
        __Ownable_init(initialOwner);
        __UUPSUpgradeable_init();

        transferOwnership(initialOwner);
        minimumReserve = _minimumReserve;
    }

    function decimals() public view virtual override(ERC20Upgradeable, ERC4626Upgradeable) returns (uint8) {
        return ERC4626Upgradeable.decimals();
    }

    function _authorizeUpgrade(address newImplementation) internal onlyOwner override {}

    function stake(uint256 amount) public {
        require(balanceOf(msg.sender) >= amount, "Insufficient balance");
        _burn(msg.sender, amount);

        StakerInfo storage staker = stakers[msg.sender];
        staker.balance += amount;
        staker.lastBlockNumber = block.number;
    }

    function unstake(uint256 amount) public {
        StakerInfo storage staker = stakers[msg.sender];
        require(staker.balance >= amount, "Insufficient staked balance");
        
        uint256 interest = calculateInterest(staker.balance, block.number - staker.lastBlockNumber);
        staker.balance -= amount;
        staker.lastBlockNumber = block.number;

        _mint(msg.sender, amount + interest);
    }

    function calculateInterest(uint256 amount, uint256 blocks) public pure returns (uint256) {
        uint256 blocksPerYear = 2102400; // Approximation (15 seconds per block)
        uint256 interestRate = getInterestRate(amount);
        return amount * interestRate * blocks / blocksPerYear / 10000;
    }

    function getInterestRate(uint256 amount) public pure returns (uint256) {
        if (amount < 100 ether) {
            return INTEREST_RATE_5;
        } else if (amount < 500 ether) {
            return INTEREST_RATE_10;
        } else {
            return INTEREST_RATE_15;
        }
    }

    function previewDeposit(uint256 assets) public view override returns (uint256) {
    uint256 totalAssets = totalAssets();
    
    if (totalAssets < minimumReserve) {
        uint256 neededToFillReserve = minimumReserve - totalAssets;
        if (assets <= neededToFillReserve) {
            // If the deposit amount is less than or equal to what's needed to fill the reserve,
            // accept the entire deposit amount.
            return super.previewDeposit(assets);
        } else {
            // If the deposit is more than needed, only accept up to the reserve requirement.
            return super.previewDeposit(neededToFillReserve);
        }
    } else {
        // If the reserve requirement is already met, proceed normally.
        return super.previewDeposit(assets);
    }
}


    function previewWithdraw(uint256 assets) public view override returns (uint256) {
    uint256 totalAssets = totalAssets();

    if (totalAssets - assets < minimumReserve) {

        // Allow withdrawal using reserve, if sufficient
        uint256 availableForWithdrawal = totalAssets > minimumReserve ? totalAssets - minimumReserve : 0;
        return super.previewWithdraw(availableForWithdrawal);
    } else {
        // Normal withdrawal
        return super.previewWithdraw(assets);
    }
}

}
