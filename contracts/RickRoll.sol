// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;
import {RickRollInterface} from './interfaces/RickRollInterface.sol';
import {Base64} from './libraries/Base64.sol';

contract RickRoll is RickRollInterface {
  string public name;
  uint256[] public arrayBuffer;
  uint256 public bufferLength;
  uint256 public noOfBytes;

  constructor(uint256 _maxBufferLength, uint256 _noOfBytes) {
    arrayBuffer = new uint256[](_maxBufferLength);
    noOfBytes = _noOfBytes;
  }

  function append(uint256[] memory buffer) public override {
    for (uint256 i = 0; i < buffer.length; i++) {
      arrayBuffer[bufferLength + i] = buffer[i];
    }
    bufferLength += buffer.length;
  }

  function getRickRoll() public view override returns (string memory) {
    bytes memory _bytes = new bytes(noOfBytes);
    for (uint256 i = 0; i < arrayBuffer.length; i++) {
      uint256 num = arrayBuffer[i];
      for (uint256 j = 0; num > 0 && j < 32 && (i * 32 + j) < noOfBytes; j++) {
        uint8 remainder = uint8(num % 0x100);
        _bytes[i * 32 + j] = bytes1(uint8(remainder));
        num = num / 0x100;
      }
    }
    return string(abi.encodePacked('data:audio/mp3;base64,', Base64.encode(_bytes)));
  }

  function setName(string memory _name) public override {
    name = _name;
  }
}
