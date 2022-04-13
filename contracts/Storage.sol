// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;
import {StorageInterface} from './interfaces/StorageInterface.sol';

contract Storage is StorageInterface {
  string public name;
  uint8[] private _arrayBuffer;

  function append(uint8[] memory buffer) public override {
    uint8[] memory newArray = new uint8[](_arrayBuffer.length + buffer.length);
    for (uint256 i = 0; i < _arrayBuffer.length; i++) {
      newArray[i] = _arrayBuffer[i];
    }
    for (uint256 i = 0; i < buffer.length; i++) {
      newArray[_arrayBuffer.length + i] = buffer[i];
    }
    _arrayBuffer = newArray;
  }

  function getBytes() public view override returns (bytes memory) {
    bytes memory _bytes = new bytes(_arrayBuffer.length);
    for (uint256 i = 0; i < _arrayBuffer.length; i++) {
      _bytes[i] = bytes1(uint8(_arrayBuffer[i]));
    }
    return _bytes;
  }

  function setName(string memory _name) public override {
    name = _name;
  }
}
