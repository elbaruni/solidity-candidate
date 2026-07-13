// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.29 <0.9.0;

import { ReentrancyGuard } from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

import { IPaymentLedger } from "./interfaces/IPaymentLedger.sol";
import { InsufficientBalance, ZeroAmount } from "./errors/PaymentErrors.sol";
import { EthTransfers } from "./libraries/EthTransfers.sol";

/// @title PaymentProcessor
/// @notice Allows users to deposit, track, and withdraw ETH.
contract PaymentProcessor is IPaymentLedger, ReentrancyGuard {
    /*//////////////////////////////////////////////////////////////
                                STORAGE
    //////////////////////////////////////////////////////////////*/

    mapping(address account => uint256 balance) private _balances;

    /*//////////////////////////////////////////////////////////////
                            RECEIVE FUNCTION
    //////////////////////////////////////////////////////////////*/

    /// @inheritdoc IPaymentLedger
    receive() external payable override {
        _deposit(msg.sender, msg.value);
    }

    /*//////////////////////////////////////////////////////////////
                         EXTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @inheritdoc IPaymentLedger
    function deposit() external payable override {
        _deposit(msg.sender, msg.value);
    }

    /// @inheritdoc IPaymentLedger
    function withdraw(uint256 amount) external override nonReentrant {
        if (amount == 0) {
            revert ZeroAmount();
        }

        uint256 currentBalance = _balances[msg.sender];

        if (amount > currentBalance) {
            revert InsufficientBalance(
                msg.sender,
                amount,
                currentBalance
            );
        }

        _balances[msg.sender] = currentBalance - amount;

        EthTransfers.sendValue(payable(msg.sender), amount);

        emit Withdraw(msg.sender, amount);
    }

    /*//////////////////////////////////////////////////////////////
                            VIEW FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @inheritdoc IPaymentLedger
    function balanceOf(address account)
        external
        view
        override
        returns (uint256)
    {
        return _balances[account];
    }

    /*//////////////////////////////////////////////////////////////
                         INTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /// @dev Records an ETH deposit and emits the corresponding event.
    function _deposit(address account, uint256 amount) internal {
        if (amount == 0) {
            revert ZeroAmount();
        }

        _balances[account] += amount;

        emit Deposit(account, amount);
    }
}
