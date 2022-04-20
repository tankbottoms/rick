// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import './libraries/InflateLib.sol';

interface ITestGZip {
    function puff(bytes calldata source, uint256 destlen) external pure returns (InflateLib.ErrorCode, bytes memory);
}

contract TestGZip is ITestGZip {
    function puff(bytes calldata source, uint256 destlen) public pure override returns (InflateLib.ErrorCode, bytes memory) {
        return InflateLib.puff(source, destlen);
    }
}
