// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;
import {StorageInterface} from './interfaces/StorageInterface.sol';
import {SSTORE2} from './libraries/SSTORE2.sol';

contract Storage is StorageInterface {
  address private pointer;

  function set(bytes memory _bytes) public override {
    pointer = SSTORE2.write(_bytes);
  }

  function get() public view override returns (bytes memory) {
    return SSTORE2.read(pointer);
  }
}
