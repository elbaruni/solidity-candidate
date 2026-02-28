// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.29;

import { EthTransferFailed } from "../errors/PaymentErrors.sol";

/// @dev Small helper for native ETH transfers with a single failure path.
library EthTransfers {
    function sendValue(address payable recipient, uint256 amount) internal {
        (bool success,) = recipient.call{ value: amount }("");
        if (!success) revert EthTransferFailed(recipient, amount);
    }
}
