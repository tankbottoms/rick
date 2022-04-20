// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import './libraries/InflateLib.sol';

contract TestGZip {
    function puff(bytes calldata source, uint256 destlen) external pure returns (InflateLib.ErrorCode, bytes memory) {
        return InflateLib.puff(source, destlen);
    }
}
