// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.29;

/// @dev Canonical shape for the assessment contract. Implement this on `PaymentProcessor`.
interface IPaymentLedger {
    event Deposit(address indexed user, uint256 amount);
    event Withdraw(address indexed user, uint256 amount);

    receive() external payable;

    function deposit() external payable;

    function withdraw(uint256 amount) external;

    function balanceOf(address account) external view returns (uint256 balance);
}
