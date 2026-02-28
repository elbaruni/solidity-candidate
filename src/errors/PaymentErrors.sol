// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.29;

error ZeroAmount();
error InsufficientBalance(address account, uint256 requested, uint256 available);
error EthTransferFailed(address to, uint256 amount);
