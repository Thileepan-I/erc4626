// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

interface ICUSDC {
    function supply(address asset, uint256 amount) external;
    function withdraw(address asset, uint256 amount) external;
    function balanceOf(address account) external view returns (uint256);
}