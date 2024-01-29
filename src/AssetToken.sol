// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "../lib/openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import "../lib/openzeppelin-contracts/contracts/access/Ownable.sol";

contract AssetToken is ERC20, Ownable {
    constructor(address initialOwner)
        ERC20("AssetToken", "AST")
        Ownable(initialOwner)
    {
        _mint(msg.sender, 100000 * 10 ** decimals());
    }
}