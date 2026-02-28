// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.29;

import { IPaymentLedger } from "../interfaces/IPaymentLedger.sol";

/// @dev Minimal malicious-style contract for exercising reentrancy defenses in tests.
contract ReentrantCaller {
    IPaymentLedger public ledger;
    uint256 public attackAmount;
    uint256 public calls;

    function bind(IPaymentLedger ledger_, uint256 attackAmount_) external {
        ledger = ledger_;
        attackAmount = attackAmount_;
    }

    receive() external payable {
        if (calls++ == 0 && address(ledger) != address(0) && attackAmount != 0) {
            ledger.withdraw(attackAmount);
        }
    }

    function depositAndWithdraw(uint256 depositAmount, uint256 withdrawAmount) external payable {
        ledger.deposit{ value: depositAmount }();
        ledger.withdraw(withdrawAmount);
    }
}
