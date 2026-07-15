// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.29 <0.9.0;

import { Test } from "forge-std/src/Test.sol";

import { PaymentProcessor } from "../src/PaymentProcessor.sol";
import { IPaymentLedger } from "../src/interfaces/IPaymentLedger.sol";
import { EthTransferFailed, InsufficientBalance, ZeroAmount } from "../src/errors/PaymentErrors.sol";
import { ReentrantCaller } from "../src/mocks/ReentrantCaller.sol";

contract PaymentProcessorTest is Test {
    PaymentProcessor internal processor;

    address internal constant ALICE = address(0xA11CE);
    address internal constant BOB = address(0xB0B);

    event Deposit(address indexed user, uint256 amount);
    event Withdraw(address indexed user, uint256 amount);

    function setUp() public {
        processor = new PaymentProcessor();

        vm.deal(ALICE, 10 ether);
        vm.deal(BOB, 10 ether);
    }

    /*//////////////////////////////////////////////////////////////
                              DEPOSITS
    //////////////////////////////////////////////////////////////*/

    function test_DepositUpdatesBalanceAndEmitsEvent() external {
        vm.expectEmit(true, false, false, true, address(processor));
        emit Deposit(ALICE, 1 ether);

        vm.prank(ALICE);
        processor.deposit{ value: 1 ether }();

        assertEq(processor.balanceOf(ALICE), 1 ether);
        assertEq(address(processor).balance, 1 ether);
    }

    function test_MultipleDepositsAccumulate() external {
        vm.startPrank(ALICE);
        processor.deposit{ value: 1 ether }();
        processor.deposit{ value: 2 ether }();
        processor.deposit{ value: 3 ether }();
        vm.stopPrank();

        assertEq(processor.balanceOf(ALICE), 6 ether);
        assertEq(address(processor).balance, 6 ether);
    }

    function test_ReceiveUpdatesBalanceAndEmitsEvent() external {
        vm.expectEmit(true, false, false, true, address(processor));
        emit Deposit(BOB, 2 ether);

        vm.prank(BOB);
        (bool success,) = address(processor).call{ value: 2 ether }("");

        assertTrue(success);
        assertEq(processor.balanceOf(BOB), 2 ether);
        assertEq(address(processor).balance, 2 ether);
    }

    /*//////////////////////////////////////////////////////////////
                             WITHDRAWALS
    //////////////////////////////////////////////////////////////*/

    function test_WithdrawUpdatesBalancesTransfersEthAndEmitsEvent() external {
        vm.prank(ALICE);
        processor.deposit{ value: 3 ether }();

        uint256 aliceBalanceBefore = ALICE.balance;

        vm.expectEmit(true, false, false, true, address(processor));
        emit Withdraw(ALICE, 1 ether);

        vm.prank(ALICE);
        processor.withdraw(1 ether);

        assertEq(processor.balanceOf(ALICE), 2 ether);
        assertEq(address(processor).balance, 2 ether);
        assertEq(ALICE.balance, aliceBalanceBefore + 1 ether);
    }

    function test_WithdrawDoesNotAffectAnotherUser() external {
        vm.prank(ALICE);
        processor.deposit{ value: 5 ether }();

        vm.prank(BOB);
        processor.deposit{ value: 4 ether }();

        vm.prank(ALICE);
        processor.withdraw(2 ether);

        assertEq(processor.balanceOf(ALICE), 3 ether);
        assertEq(processor.balanceOf(BOB), 4 ether);
        assertEq(address(processor).balance, 7 ether);
    }

    function test_WithdrawCanEmptyBalance() external {
        vm.prank(ALICE);
        processor.deposit{ value: 1 ether }();

        uint256 aliceBalanceBefore = ALICE.balance;

        vm.prank(ALICE);
        processor.withdraw(1 ether);

        assertEq(processor.balanceOf(ALICE), 0);
        assertEq(address(processor).balance, 0);
        assertEq(ALICE.balance, aliceBalanceBefore + 1 ether);
    }

    /*//////////////////////////////////////////////////////////////
                              REVERTS
    //////////////////////////////////////////////////////////////*/

    function test_WithdrawRevertsWhenAmountExceedsOwnBalance() external {
        vm.prank(ALICE);
        processor.deposit{ value: 1 ether }();

        vm.expectRevert(abi.encodeWithSelector(InsufficientBalance.selector, BOB, 2 ether, 0));

        vm.prank(BOB);
        processor.withdraw(2 ether);
    }

    function test_WithdrawRevertsWithCurrentAvailableBalance() external {
        vm.prank(ALICE);
        processor.deposit{ value: 1 ether }();

        vm.expectRevert(abi.encodeWithSelector(InsufficientBalance.selector, ALICE, 2 ether, 1 ether));

        vm.prank(ALICE);
        processor.withdraw(2 ether);
    }

    function test_RevertedWithdrawalPreservesState() external {
        vm.prank(ALICE);
        processor.deposit{ value: 1 ether }();

        vm.expectRevert(abi.encodeWithSelector(InsufficientBalance.selector, ALICE, 2 ether, 1 ether));

        vm.prank(ALICE);
        processor.withdraw(2 ether);

        assertEq(processor.balanceOf(ALICE), 1 ether);
        assertEq(address(processor).balance, 1 ether);
    }

    function test_FailedEthTransferRestoresAccounting() external {
        RejectingRecipient recipient = new RejectingRecipient(processor);

        recipient.deposit{ value: 1 ether }();

        vm.expectRevert(abi.encodeWithSelector(EthTransferFailed.selector, address(recipient), 1 ether));

        recipient.withdraw(1 ether);

        assertEq(processor.balanceOf(address(recipient)), 1 ether);
        assertEq(address(processor).balance, 1 ether);
    }

    function test_DepositRevertsOnZeroAmount() external {
        vm.expectRevert(ZeroAmount.selector);
        processor.deposit();
    }

    function test_ReceiveRevertsOnZeroAmount() external {
        (bool success, bytes memory revertData) = address(processor).call("");

        assertFalse(success);
        assertEq(revertData, abi.encodeWithSelector(ZeroAmount.selector));
    }

    function test_WithdrawRevertsOnZeroAmount() external {
        vm.expectRevert(ZeroAmount.selector);
        processor.withdraw(0);
    }

    /*//////////////////////////////////////////////////////////////
                            REENTRANCY
    //////////////////////////////////////////////////////////////*/

    function test_ReentrantWithdrawIsBlocked() external {
        ReentrantCaller attacker = new ReentrantCaller();

        attacker.bind(processor, 1 ether);

        vm.expectRevert(abi.encodeWithSelector(EthTransferFailed.selector, address(attacker), 1 ether));

        attacker.depositAndWithdraw{ value: 2 ether }(2 ether, 1 ether);

        assertEq(processor.balanceOf(address(attacker)), 0);
        assertEq(address(processor).balance, 0);
    }
}

contract RejectingRecipient {
    error EthRejected();

    IPaymentLedger private immutable ledger;

    constructor(IPaymentLedger ledger_) {
        ledger = ledger_;
    }

    receive() external payable {
        revert EthRejected();
    }

    function deposit() external payable {
        ledger.deposit{ value: msg.value }();
    }

    function withdraw(uint256 amount) external {
        ledger.withdraw(amount);
    }
}
